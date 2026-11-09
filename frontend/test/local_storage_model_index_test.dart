import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Índice de modelos sobre el LocalStorage real (Hive + SharedPreferences).
void main() {
  late Directory tmp;
  late LocalStorage storage;
  const a = 'aaaaaaaa-0000-0000-0000-000000000001';
  const b = 'bbbbbbbb-0000-0000-0000-000000000002';

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('local_storage_');
    storage = LocalStorage(hivePath: () async => tmp.path);
    await storage.init();
  });

  tearDown(() async {
    await Hive.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('getCachedModelsOf devuelve solo las versiones de ese edificio',
      () async {
    await storage.cacheModel(a, 'v1', '/m/a/v1.glb');
    await storage.cacheModel(a, 'v2', '/m/a/v2.glb');
    await storage.cacheModel(b, 'v1', '/m/b/v1.glb');

    expect(storage.getCachedModelsOf(a),
        {'v1': '/m/a/v1.glb', 'v2': '/m/a/v2.glb'});
    expect(storage.getCachedModelsOf(b), {'v1': '/m/b/v1.glb'});
  });

  test('removeCachedModel borra solo esa version y deja las demas', () async {
    await storage.cacheModel(a, 'v1', '/m/a/v1.glb');
    await storage.cacheModel(a, 'v2', '/m/a/v2.glb');
    await storage.cacheModel(b, 'v1', '/m/b/v1.glb');

    await storage.removeCachedModel(a, 'v1');

    expect(storage.getCachedModelPath(a, 'v1'), isNull);
    expect(storage.getCachedModelPath(a, 'v2'), '/m/a/v2.glb');
    expect(storage.getCachedModelPath(b, 'v1'), '/m/b/v1.glb');
  });

  test('la version vigente es por edificio y se limpia al borrarla', () async {
    await storage.cacheModel(a, 'v1', '/m/a/v1.glb');
    await storage.cacheModel(b, 'v7', '/m/b/v7.glb');

    expect(storage.getCachedModelVersion(a), 'v1');
    expect(storage.getCachedModelVersion(b), 'v7');

    await storage.removeCachedModel(a, 'v1');

    expect(storage.getCachedModelVersion(a), isNull);
    expect(storage.getCachedModelVersion(b), 'v7');
  });

  test('getCachedBuildingIds lista los edificios con modelo', () async {
    await storage.cacheModel(a, 'v1', '/m/a/v1.glb');
    await storage.cacheModel(b, 'v1', '/m/b/v1.glb');

    expect(storage.getCachedBuildingIds(), {a, b});
  });

  test('metadatos de edificio: ida y vuelta, y null si no hay o esta danado',
      () async {
    expect(storage.getCachedBuildingPayload(a), isNull);

    await storage.cacheBuildingPayload(a, {'building': {'id': a}});
    expect(storage.getCachedBuildingPayload(a), {'building': {'id': a}});

    await storage.put('building_meta_$b', '{no es json');
    expect(storage.getCachedBuildingPayload(b), isNull);
  });
}
