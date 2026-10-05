// EC-04: con cache valida y sin red, vista utilizable < 5 s en 100% de 20 pruebas,
// sin crash y con banner "Offline". Ejecutar en dispositivo:
//   flutter test integration_test/offline_map_test.dart -d <device>
import 'package:flutter/material.dart';
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

  testWidgets('EC-04 offline con cache: 20 corridas < 5 s con banner Offline',
      (tester) async {
    final storage = await preloadModelCache();
    // Control online: valida que el arnes de prueba hace avanzar el bloc.
    // Si esto falla, el resultado offline no es interpretable.
    final control = MapasBloc(
      loadBuildingUseCase: LoadBuildingUseCase(
        api: InMemoryMapasApi(),
        cache: ModelCache(storage),
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: control,
        child: const MapPage(buildingId: buildingId),
      ),
    ));
    for (var t = 0; t < 30 && control.state is! BuildingLoaded; t++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    // ignore: avoid_print
    print('EC04_CONTROL online -> ${control.state.runtimeType}');
    expect(control.state, isA<BuildingLoaded>(),
        reason: 'control online fallo: arnes invalido');
    await control.close();

    const runs = 20;
    final results = <String>[];
    var ok = 0;

    for (var i = 1; i <= runs; i++) {
      final bloc = MapasBloc(
        loadBuildingUseCase: LoadBuildingUseCase(
          api: offlineApi(),
          cache: ModelCache(storage),
        ),
      );
      final sw = Stopwatch()..start();
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: MapPage(key: ValueKey('run$i'), buildingId: buildingId),
        ),
      ));
      var banner = false;
      while (sw.elapsed < const Duration(seconds: 5)) {
        // runAsync deja avanzar la E/S real (DNS, archivos); sin esto el bloc no progresa.
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        if (find.textContaining('Offline').evaluate().isNotEmpty) {
          banner = true;
          break;
        }
      }
      final usable = bloc.state is BuildingLoaded;
      final pass = banner && usable && sw.elapsed < const Duration(seconds: 5);
      if (pass) ok++;
      results.add('corrida $i: ${sw.elapsedMilliseconds} ms, '
          'estado=${bloc.state.runtimeType}, bannerOffline=$banner, '
          '${pass ? "OK" : "FALLA"}');
      await bloc.close();
    }

    // ignore: avoid_print
    print('EC04_RESULT ok=$ok/$runs\n${results.join("\n")}');
    expect(ok, runs, reason: '$ok/$runs corridas cumplen EC-04');
  });
}
