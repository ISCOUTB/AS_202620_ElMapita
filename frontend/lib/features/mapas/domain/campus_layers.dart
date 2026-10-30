// lib/features/mapas/domain/campus_layers.dart
//
// Vincula las categorias del filtro (PlaceCategory.name) con los nodos del
// .glb del campus. Logica pura: no depende de Flutter ni de la red.

class CampusLayers {
  /// Nodo del .glb -> categoria, tal como esta en la tabla `mapa_capas`.
  final Map<String, String> _nodeToCategory;

  CampusLayers(Map<String, Set<String>> nodesByCategory)
      : _nodeToCategory = {
          for (final entry in nodesByCategory.entries)
            for (final node in entry.value) node: entry.key,
        };

  /// Nodos que nunca se muestran (el plano trae una textura de referencia).
  static const Set<String> alwaysHidden = {'Plano_Referencia'};

  /// Etiquetas (`Etq_*`) -> categoria, por palabra clave del texto normalizado.
  static const List<(String, String)> _labelRules = [
    ('cancha', 'canchas'),
    ('biblioteca', 'biblioteca'),
    ('cafeteria', 'cafeteria'),
    ('pandebono', 'cafeteria'),
    ('auditorio', 'auditorios'),
    ('maloka', 'auditorios'),
    ('lab', 'laboratorios'),
    ('rectoria', 'oficinasAdministrativas'),
    ('bienestar', 'bienestarUniversitario'),
    ('bloque a', 'salones'),
    ('forest', 'areasVerdes'),
  ];

  /// Categoria de un nodo, o null si es parte de la base (vias, terreno...).
  String? categoryOf(String node) {
    final direct = _nodeToCategory[node];
    if (direct != null) return direct;
    // Todo `Det_*` es detalle de una cancha (lineas, porterias, tableros).
    if (node.startsWith('Det_')) return 'canchas';
    if (node.startsWith('Etq_')) return _labelCategory(node.substring(4));
    return null;
  }

  /// Hay al menos un nodo vinculado a [category].
  bool hasLayer(String category) =>
      _nodeToCategory.values.contains(category);

  /// Categorias con al menos un nodo en el modelo.
  Set<String> get categories => _nodeToCategory.values.toSet();

  /// Nodos de la tabla `mapa_capas` vinculados a [category].
  List<String> nodesOf(String category) => [
        for (final entry in _nodeToCategory.entries)
          if (entry.value == category) entry.key,
      ];

  /// Terreno y circulacion: se ven siempre para ubicarse en el mapa.
  static bool isBase(String node) =>
      node == 'Terreno' ||
      node == 'Carreteable' ||
      node.startsWith('Via_') ||
      node.startsWith('Anden');

  /// Nodos a ocultar. Sin categorias seleccionadas se muestra todo el campus.
  /// Con algunas seleccionadas solo quedan visibles la base y los nodos de
  /// esas categorias: lo que no tiene categoria (edificios fuera de
  /// `mapa_capas`, ventanas, puertas, etiquetas sueltas) tambien se oculta.
  Set<String> hiddenNodes(Iterable<String> allNodes, Set<String> selected) {
    final hidden = <String>{...alwaysHidden};
    if (selected.isEmpty) return hidden;
    for (final node in allNodes) {
      if (isBase(node)) continue;
      final category = categoryOf(node);
      if (category == null || !selected.contains(category)) hidden.add(node);
    }
    return hidden;
  }

  /// Three.js sanea los nombres al cargar el .glb (espacios -> '_', quita
  /// `[ ] . : /`); el JS del visor compara contra el nombre ya saneado.
  static String sanitizeNodeName(String name) => name
      .replaceAll(RegExp(r'\s'), '_')
      .replaceAll(RegExp(r'[\[\].:/]'), '');

  String? _labelCategory(String label) {
    final text = _stripAccents(label.toLowerCase());
    for (final (keyword, category) in _labelRules) {
      if (text.contains(keyword)) return category;
    }
    return null;
  }

  static String _stripAccents(String value) {
    const from = 'áéíóúñ';
    const to = 'aeioun';
    var result = value;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }
}
