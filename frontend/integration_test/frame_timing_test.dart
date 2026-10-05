// EC-02 (PARCIAL): mide tiempos de fotograma de la pantalla del mapa en dispositivo.
// LIMITACION: el frontend aun no tiene renderizador 3D (map_page.dart es un
// placeholder), asi que esto mide el repintado sintetico del arbol de widgets
// actual (rotacion continua del mapa durante 60 s), NO un modelo 3D.
//   flutter test integration_test/frame_timing_test.dart -d <device> --profile
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/mapas/application/load_building_use_case.dart';
import 'package:frontend/features/mapas/infrastructure/storage/model_cache.dart';
import 'package:frontend/features/mapas/presentation/bloc/mapas_bloc.dart';
import 'package:frontend/features/mapas/presentation/pages/map_page.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EC-02 (parcial) frame timing 60 s', (tester) async {
    final storage = await preloadModelCache();
    final bloc = MapasBloc(
      loadBuildingUseCase: LoadBuildingUseCase(
        api: InMemoryMapasApi(),
        cache: ModelCache(storage),
      ),
    );
    final timings = <FrameTiming>[];
    void onTimings(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(onTimings);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const _Spinning(child: MapPage(buildingId: buildingId)),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    timings.clear();

    final sw = Stopwatch()..start();
    while (sw.elapsed < const Duration(seconds: 60)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    SchedulerBinding.instance.removeTimingsCallback(onTimings);

    final totals =
        timings.map((t) => t.totalSpan.inMicroseconds / 1000).toList()..sort();
    final within = totals.where((ms) => ms <= 33.3).length;
    final pct = totals.isEmpty ? 0.0 : within * 100 / totals.length;
    final p95 =
        totals.isEmpty ? double.nan : totals[(totals.length * 0.95).ceil() - 1];
    // ignore: avoid_print
    print('EC02_RESULT frames=${totals.length} '
        'pct<=33.3ms=${pct.toStringAsFixed(1)} '
        'p95=${p95.toStringAsFixed(1)}ms max=${totals.isEmpty ? 0 : totals.last}ms');
    expect(totals.length, greaterThan(100), reason: 'muy pocos fotogramas');
    expect(pct, greaterThanOrEqualTo(95));
    await bloc.close();
  });
}

class _Spinning extends StatefulWidget {
  final Widget child;
  const _Spinning({required this.child});

  @override
  State<_Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<_Spinning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _c, child: widget.child);
}
