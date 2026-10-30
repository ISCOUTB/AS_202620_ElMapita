// lib/features/mapas/presentation/pages/campus_model_page.dart
//
// Visor 3D del campus: descarga el .glb de Supabase a la cache local, oculta
// en vivo los nodos que no pertenecen a las categorias del filtro y marca la
// posicion del telefono cuando esta dentro del campus.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/platform/location_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../campus/application/campus_filter.dart';
import '../../../campus/domain/entities.dart';
import '../../../campus/presentation/category_labels.dart';
import '../../domain/arrival_guide.dart';
import '../../domain/campus_geo_reference.dart';
import '../../domain/campus_layers.dart';
import '../../infrastructure/api/campus_layers_repository.dart';
import '../../infrastructure/storage/glb_node_names.dart';
import '../../infrastructure/storage/model_cache.dart';

class CampusModelPage extends StatefulWidget {
  const CampusModelPage({super.key});

  @override
  State<CampusModelPage> createState() => _CampusModelPageState();
}

enum _UserStatus { locating, denied, unavailable, outside, inside }

class _CampusModelPageState extends State<CampusModelPage> {
  static const double _userMarkerHeight = 3;
  static const double _outsideMarginMeters = 30;

  final CampusFilter _filter = getIt<CampusFilter>();
  final CampusGeoReference _geo = CampusGeoReference.utbTernera;
  final ValueNotifier<_UserStatus> _status =
      ValueNotifier(_UserStatus.locating);

  static const String _guideOffKey = 'arrival_guide_disabled';
  static const ArrivalGuide _arrivalRules = ArrivalGuide();
  static const Duration _nearBuzzEvery = Duration(seconds: 4);

  late Future<Widget> _viewer;
  CampusLayers? _layers;
  List<String> _nodes = const [];
  Map<String, NodeBounds> _bounds = const {};
  WebViewController? _controller;
  bool _viewerReady = false;
  String _userJs = 'hideUser()';
  StreamSubscription<Position>? _positionSub;

  // Guia de llegada: destino elegido, estado y vibracion.
  final ValueNotifier<Destination?> _destination = ValueNotifier(null);
  final ValueNotifier<String?> _guideMessage = ValueNotifier(null);
  late bool _guideEnabled;
  ModelPoint? _lastPoint;
  Timer? _nearTimer;
  bool _arrivedNotified = false;

  @override
  void initState() {
    super.initState();
    _guideEnabled = !getIt<LocalStorage>().getBool(_guideOffKey);
    _viewer = _load();
    _filter.addListener(_onFilterChanged);
    _startLocation();
  }

  @override
  void dispose() {
    _filter.removeListener(_onFilterChanged);
    _positionSub?.cancel();
    _nearTimer?.cancel();
    Vibration.cancel();
    _status.dispose();
    _destination.dispose();
    _guideMessage.dispose();
    super.dispose();
  }

  Future<Widget> _load() async {
    final download = await getIt<ModelCache>().getOrDownloadModel(
      buildingId: kCampusBuildingId,
      version: kCampusModelVersion,
      downloadUrl: kCampusModelUrl,
    );
    final path = download.fold<String>(
      (error) => throw Exception(error),
      (value) => value,
    );
    _nodes = await GlbNodeNames.read(path);
    _bounds = await GlbNodeBounds.read(path);
    _layers = await getIt<CampusLayersRepository>().load();
    return ModelViewer(
      src: 'file://$path',
      alt: 'Modelo 3D del campus UTB',
      backgroundColor: const Color(0xFF1B2A41),
      cameraControls: true,
      autoRotate: false,
      interactionPrompt: InteractionPrompt.none,
      // Vista cenital inclinada que simula una isometrica: campo de vision
      // estrecho y fijo, y el zoom solo cambia la distancia de la camara.
      cameraOrbit: '0deg 40deg 900m',
      minCameraOrbit: 'auto 5deg 70m',
      maxCameraOrbit: 'auto 75deg 1400m',
      fieldOfView: '25deg',
      minFieldOfView: '25deg',
      maxFieldOfView: '25deg',
      innerModelViewerHtml: _userDotHtml,
      relatedJs: _viewerJs(
        _hiddenSanitized(),
        [for (final node in _nodes) CampusLayers.sanitizeNodeName(node)],
      ),
      javascriptChannels: {
        JavascriptChannel('Ready', onMessageReceived: (_) => _onViewerReady()),
      },
      onWebViewCreated: (controller) => _controller = controller,
    );
  }

  List<String> _hiddenSanitized() {
    final layers = _layers;
    if (layers == null) return const [];
    final selected = {for (final c in _filter.value) c.name};
    return [
      for (final node in layers.hiddenNodes(_nodes, selected))
        CampusLayers.sanitizeNodeName(node),
    ];
  }

  void _onViewerReady() {
    _viewerReady = true;
    _pushHidden(animate: false); // estado inicial: sin animar
    _pushHighlight();
    _controller?.runJavaScript(_userJs);
  }

  void _onFilterChanged() => _pushHidden(animate: true);

  void _pushHidden({required bool animate}) {
    if (!_viewerReady) return;
    _controller?.runJavaScript(
      'setHiddenNodes(${jsonEncode(_hiddenSanitized())}, $animate)',
    );
  }

  // --- Ubicacion -----------------------------------------------------------

  Future<void> _startLocation() async {
    final location = getIt<LocationService>();
    final permission = await location.requestLocationPermission();
    if (!mounted) return;
    if (permission.isLeft || !permission.right) {
      _status.value = _UserStatus.denied;
      return;
    }
    _positionSub = location
        .watchPosition(distanceFilterMeters: 3)
        .listen(_onPosition, onError: (_) => _status.value = _UserStatus.unavailable);
    // Primera lectura inmediata: el stream solo emite al moverse.
    final current = await location.getCurrentPosition();
    if (!mounted) return;
    current.fold(
      (_) => _status.value = _UserStatus.unavailable,
      _onPosition,
    );
  }

  void _onPosition(Position position) {
    final point = _geo.toModel(position.latitude, position.longitude);
    if (_geo.isInside(point, marginMeters: _outsideMarginMeters)) {
      _userJs = 'setUserPosition(${point.x.toStringAsFixed(2)}, '
          '$_userMarkerHeight, ${point.z.toStringAsFixed(2)})';
      _status.value = _UserStatus.inside;
      _lastPoint = point;
    } else {
      _userJs = 'hideUser()';
      _status.value = _UserStatus.outside;
      _lastPoint = null;
    }
    if (_viewerReady) _controller?.runJavaScript(_userJs);
    _updateGuide();
  }

  // --- Guia de llegada -----------------------------------------------------

  void _setDestination(Destination? destination) {
    _arrivedNotified = false;
    _destination.value = destination;
    if (destination == null) {
      // Sin destino se vuelve a ver todo el campus.
      _filter.clear();
    } else {
      // Su categoria queda activa en el filtro para que el edificio se vea.
      final category = _categoryByName(destination.category);
      if (category != null && !_filter.value.contains(category)) {
        _filter.toggle(category);
      }
    }
    _pushHighlight();
    _updateGuide();
  }

  /// Resalta el destino en el modelo (o quita el resaltado).
  void _pushHighlight() {
    if (!_viewerReady) return;
    final destination = _destination.value;
    final arg = destination == null
        ? 'null'
        : jsonEncode(CampusLayers.sanitizeNodeName(destination.node));
    _controller?.runJavaScript('setHighlight($arg)');
  }

  void _toggleGuide() {
    setState(() => _guideEnabled = !_guideEnabled);
    getIt<LocalStorage>().setBool(_guideOffKey, !_guideEnabled);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_guideEnabled
          ? 'Guía de llegada activada'
          : 'Guía de llegada desactivada'),
      duration: const Duration(seconds: 2),
    ));
    _updateGuide();
  }

  /// Decide mensaje y vibracion segun la distancia al borde del destino.
  /// Solo actua con la guia activa, un destino elegido y el usuario dentro del
  /// campus.
  void _updateGuide() {
    final destination = _destination.value;
    final point = _lastPoint;
    if (!_guideEnabled || destination == null || point == null) {
      _nearTimer?.cancel();
      _nearTimer = null;
      Vibration.cancel();
      _guideMessage.value = null;
      return;
    }
    final distance = destination.bounds.distanceTo(point);
    final metres = distance.round();
    var phase = _arrivalRules.phaseFor(distance);
    // Una vez llegado se queda en "llegaste" aunque el GPS oscile.
    if (_arrivedNotified && phase != ArrivalPhase.far) {
      phase = ArrivalPhase.arrived;
    }
    switch (phase) {
      case ArrivalPhase.far:
        _nearTimer?.cancel();
        _nearTimer = null;
        _arrivedNotified = false;
        _guideMessage.value = 'Rumbo a ${destination.label} · $metres m';
      case ArrivalPhase.near:
        if (_nearTimer == null) {
          _vibrate(arrived: false);
          _nearTimer = Timer.periodic(_nearBuzzEvery, (_) => _vibrate(arrived: false));
        }
        _guideMessage.value = 'Cerca de ${destination.label} · $metres m';
      case ArrivalPhase.arrived:
        _nearTimer?.cancel();
        _nearTimer = null;
        if (!_arrivedNotified) {
          _arrivedNotified = true;
          _vibrate(arrived: true);
        }
        _guideMessage.value = '¡Llegaste a ${destination.label}!';
    }
  }

  Future<void> _vibrate({required bool arrived}) async {
    try {
      if (await Vibration.hasVibrator() != true) return;
      await Vibration.vibrate(
        pattern: arrived ? [0, 500, 200, 500, 200, 500] : [0, 250, 150, 250],
      );
    } catch (_) {
      // Sin vibrador o sin permiso: la guia sigue funcionando con el mensaje.
    }
  }

  /// Edificios elegibles: los de las categorias del filtro activo (todas si no
  /// hay filtro). Las areas verdes no son destinos.
  List<Destination> _destinationOptions() {
    final layers = _layers;
    if (layers == null) return const [];
    final selected = {for (final c in _filter.value) c.name};
    final options = <Destination>[];
    for (final category in layers.categories) {
      if (category == 'areasVerdes') continue;
      if (selected.isNotEmpty && !selected.contains(category)) continue;
      for (final node in layers.nodesOf(category)) {
        final bounds = _bounds[node];
        if (bounds != null) {
          options.add(Destination(node: node, category: category, bounds: bounds));
        }
      }
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  Future<void> _pickDestination() async {
    final options = _destinationOptions();
    final filtered = _filter.value.isNotEmpty;
    final choice = await showModalBottomSheet<Destination>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                filtered
                    ? '¿A dónde quieres ir? (categorías filtradas)'
                    : '¿A dónde quieres ir?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: options.isEmpty
                  ? const Center(child: Text('No hay edificios en el filtro actual'))
                  : ListView(
                      controller: scroll,
                      children: [
                        for (final option in options)
                          ListTile(
                            leading: Icon(_categoryByName(option.category)?.icon),
                            title: Text(option.label),
                            subtitle: Text(_categoryText(context, option.category)),
                            onTap: () => Navigator.of(context).pop(option),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
    if (choice != null) _setDestination(choice);
  }

  static PlaceCategory? _categoryByName(String name) {
    for (final category in PlaceCategory.values) {
      if (category.name == name) return category;
    }
    return null;
  }

  static String _categoryText(BuildContext context, String name) {
    final category = _categoryByName(name);
    return category == null ? name : categoryLabel(context, category);
  }

  // --- HTML y JS del visor -------------------------------------------------

  static const String _userDotHtml = '''
<button id="user-dot" slot="hotspot-user" data-position="0 0 0" data-normal="0 1 0"
  style="display:none;width:18px;height:18px;padding:0;border-radius:50%;
  background:#1E88E5;border:3px solid #fff;box-shadow:0 0 0 6px rgba(30,136,229,.35);"></button>
''';

  /// Oculta nodos y mueve el marcador. Three.js guarda los nodos en la escena
  /// interna de `model-viewer` (simbolo `scene`); el paneo se limita a un
  /// radio alrededor del centro inicial para no perder el campus de vista.
  String _viewerJs(List<String> initialHidden, List<String> allNodes) => '''
(function () {
  var mv = document.querySelector('model-viewer');
  var hidden = new Set(${jsonEncode(initialHidden)});
  var center = null;
  var PAN_LIMIT = 190;

  var highlighted = null;

  function getScene() {
    var sym = Object.getOwnPropertySymbols(mv).find(function (s) {
      return s.description === 'scene';
    });
    return sym && mv[sym];
  }

  // Aparecer/desaparecer: el nodo crece desde el suelo (escala Y). La base de
  // los edificios esta en y=0, asi que escalar en Y los hace subir o hundirse.
  var nodeSet = new Set(${jsonEncode(allNodes)});
  var DURATION = 320;
  var STAGGER_STEP = 20;
  var STAGGER_MAX = 140;
  var MIN_SCALE = 0.001;
  var animating = new Map();
  var rafId = null;

  function setProgress(o, k) {
    if (o.userData.baseY === undefined) o.userData.baseY = o.scale.y;
    o.userData.k = k;
    o.scale.y = o.userData.baseY * Math.max(k, MIN_SCALE);
  }

  function step(now) {
    animating.forEach(function (a, o) {
      var t = (now - a.start) / DURATION;
      if (t < 0) return;
      if (t > 1) t = 1;
      var eased = 1 - Math.pow(1 - t, 3);
      setProgress(o, a.from + (a.to - a.from) * eased);
      if (t === 1) {
        if (a.to === 0) o.visible = false;
        animating.delete(o);
      }
    });
    var scene = getScene();
    if (scene) scene.queueRender();
    rafId = animating.size ? requestAnimationFrame(step) : null;
  }

  function apply(animate) {
    var scene = getScene();
    if (!scene) return;
    var changed = 0;
    scene.traverse(function (o) {
      if (!o.name || !nodeSet.has(o.name)) return;
      var show = !hidden.has(o.name);
      var to = show ? 1 : 0;
      var current = o.userData.k !== undefined ? o.userData.k : (o.visible ? 1 : 0);
      if (!animate) {
        animating.delete(o);
        o.visible = show;
        setProgress(o, to);
        return;
      }
      var running = animating.get(o);
      if (running ? running.to === to : current === to) return;
      if (show) o.visible = true;
      animating.set(o, {
        from: current,
        to: to,
        start: performance.now() + Math.min(changed * STAGGER_STEP, STAGGER_MAX),
      });
      changed++;
    });
    if (animating.size && rafId === null) rafId = requestAnimationFrame(step);
    scene.queueRender();
  }

  // Los materiales se comparten entre nodos: se clona el del destino antes de
  // teñirlo y se guarda el original para restaurarlo.
  function tint(material) {
    var copy = material.clone();
    // Los colores del modelo son pastel: solo sumar emision los deja casi
    // blancos, asi que tambien se reemplaza el color base.
    copy.map = null;
    if (copy.color) copy.color.setHex(0xFFA000);
    if (copy.emissive) {
      copy.emissive.setHex(0xFF8F00);
      copy.emissiveIntensity = 0.5;
    }
    copy.needsUpdate = true;
    return copy;
  }

  function paint() {
    var scene = getScene();
    if (!scene) { console.log('[mapita] paint: sin escena'); return; }
    scene.traverse(function (o) {
      if (o.isMesh && o.userData.originalMaterial) {
        o.material = o.userData.originalMaterial;
        delete o.userData.originalMaterial;
      }
    });
    var painted = 0;
    if (highlighted) {
      scene.traverse(function (o) {
        if (o.name !== highlighted) return;
        o.traverse(function (mesh) {
          if (!mesh.isMesh || mesh.userData.originalMaterial) return;
          mesh.userData.originalMaterial = mesh.material;
          mesh.material = Array.isArray(mesh.material)
            ? mesh.material.map(tint)
            : tint(mesh.material);
          painted++;
        });
      });
    }
    console.log('[mapita] highlight=' + highlighted + ' meshes=' + painted);
    scene.queueRender();
  }

  window.setHighlight = function (name) {
    highlighted = name;
    paint();
  };

  window.setHiddenNodes = function (names, animate) {
    hidden = new Set(names);
    apply(animate);
  };
  window.setUserPosition = function (x, y, z) {
    var dot = document.getElementById('user-dot');
    dot.style.display = 'block';
    mv.updateHotspot({ name: 'hotspot-user', position: x + ' ' + y + ' ' + z });
  };
  window.hideUser = function () {
    document.getElementById('user-dot').style.display = 'none';
  };

  mv.addEventListener('load', function () {
    apply(false);
    center = mv.getCameraTarget();
    Ready.postMessage('1');
  });
  mv.addEventListener('camera-change', function (e) {
    if (!center || !e.detail || e.detail.source !== 'user-interaction') return;
    var t = mv.getCameraTarget();
    var x = Math.max(center.x - PAN_LIMIT, Math.min(center.x + PAN_LIMIT, t.x));
    var z = Math.max(center.z - PAN_LIMIT, Math.min(center.z + PAN_LIMIT, t.z));
    if (x !== t.x || z !== t.z) {
      mv.cameraTarget = x + 'm ' + t.y + 'm ' + z + 'm';
    }
  });
})();
''';

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelo 3D del campus'),
        actions: [
          IconButton(
            tooltip: _guideEnabled
                ? 'Guía de llegada: activada (tocar para desactivar)'
                : 'Guía de llegada: desactivada (tocar para activar)',
            icon: Icon(_guideEnabled ? Icons.vibration : Icons.mobile_off),
            onPressed: _toggleGuide,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDestination,
        icon: const Icon(Icons.flag_outlined),
        label: const Text('Ir a…'),
      ),
      body: FutureBuilder<Widget>(
        future: _viewer,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              onRetry: () => setState(() => _viewer = _load()),
            );
          }
          return Stack(
            children: [
              snapshot.requireData,
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: _FilterChips(filter: _filter, layers: _layers),
              ),
              Positioned(
                left: 16,
                right: 88, // deja libre el boton "Ir a…"
                bottom: 16,
                child: _StatusBanner(
                  status: _status,
                  guideMessage: _guideMessage,
                  destination: _destination,
                  guideEnabled: _guideEnabled,
                  onClearDestination: () => _setDestination(null),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chips de categorias con capa en el modelo; seleccionar/deseleccionar
/// actualiza el visor en vivo.
class _FilterChips extends StatelessWidget {
  final CampusFilter filter;
  final CampusLayers? layers;

  const _FilterChips({required this.filter, required this.layers});

  @override
  Widget build(BuildContext context) {
    final available = [
      for (final category in PlaceCategory.values)
        if (layers?.hasLayer(category.name) ?? false) category,
    ];
    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<Set<PlaceCategory>>(
        valueListenable: filter,
        builder: (context, selected, _) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final category in available)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(category.icon, size: 18),
                  label: Text(categoryLabel(context, category)),
                  selected: selected.contains(category),
                  onSelected: (_) => filter.toggle(category),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final ValueNotifier<_UserStatus> status;
  final ValueNotifier<String?> guideMessage;
  final ValueNotifier<Destination?> destination;
  final bool guideEnabled;
  final VoidCallback onClearDestination;

  const _StatusBanner({
    required this.status,
    required this.guideMessage,
    required this.destination,
    required this.guideEnabled,
    required this.onClearDestination,
  });

  static const Map<_UserStatus, String> _messages = {
    _UserStatus.outside: 'Posición lejana de la zona',
    _UserStatus.denied:
        'Activa el permiso de ubicación para verte en el mapa',
    _UserStatus.unavailable: 'No se pudo obtener tu ubicación',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([status, guideMessage, destination]),
      builder: (context, _) {
        final target = destination.value;
        final guide = guideMessage.value;
        final location = _messages[status.value];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (target != null)
              InputChip(
                avatar: Icon(
                  guideEnabled ? Icons.flag : Icons.flag_outlined,
                  size: 18,
                ),
                label: Text('Destino: ${target.label}'),
                onDeleted: onClearDestination,
              ),
            if (guide != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(guide, textAlign: TextAlign.center),
                ),
              ),
            if (location != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(location, textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No se pudo cargar el modelo 3D.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
