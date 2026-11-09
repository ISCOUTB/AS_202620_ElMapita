import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/features/mapas/application/load_building_use_case.dart';
import 'package:frontend/features/mapas/domain/entities.dart';
import 'package:frontend/features/mapas/infrastructure/api/mapas_api.dart';
import 'package:frontend/features/mapas/infrastructure/storage/model_cache.dart';

const _buildingId = '3f8634e7-29c3-4cda-97f7-129b5587c899';
const _floorId = '061917df-d73c-426a-8b93-56025b20c74d';

Map<String, dynamic> _payload() => {
      'building': {
        'id': _buildingId,
        'nombre': 'Edificio de Ingenierias',
        'codigo': 'ING',
        'geometria': {'type': 'Polygon', 'coordinates': []},
        'pisos': [_floorId],
        'versionModelo3D': 'v1',
        'createdAt': '2026-09-27T20:55:20.139Z',
        'updatedAt': '2026-09-27T20:55:20.139Z',
      },
      'floors': [
        {
          'id': _floorId,
          'edificioId': _buildingId,
          'numero': 1,
          'nombre': 'Piso 1',
          'modelo3DUrl': 'v1.glb',
          'modelo3DVersion': 'v1',
          'alturaMetros': 3.0,
          'pois': <String>[],
          'createdAt': '2026-09-27T20:55:20.139Z',
          'updatedAt': '2026-09-27T20:55:20.139Z',
        }
      ],
      'model3DUrl': 'https://example.invalid/v1.glb',
    };

/// Almacenamiento en memoria con la misma semántica que LocalStorage.
class _FakeStorage extends Fake implements LocalStorage {
  final Map<String, String> models = {};
  final Map<String, String> payloads = {};

  @override
  Future<void> cacheModel(String b, String v, String p) async =>
      models['${b}_$v'] = p;

  @override
  String? getCachedModelPath(String b, String v) => models['${b}_$v'];

  @override
  Map<String, String> getCachedModelsOf(String b) => const {};

  @override
  Future<void> removeCachedModel(String b, String v) async {}

  @override
  Future<void> cacheBuildingPayload(
          String id, Map<String, dynamic> payload) async =>
      payloads[id] = jsonEncode(payload);

  @override
  Map<String, dynamic>? getCachedBuildingPayload(String id) {
    final raw = payloads[id];
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class _FakeApi extends MapasApi {
  _FakeApi() : super(Dio());

  Either<String, Map<String, dynamic>> response = Right(_payload());

  @override
  Future<Either<String, Map<String, dynamic>>> getBuilding(BuildingId id) async =>
      response;
}

void main() {
  late _FakeStorage storage;
  late _FakeApi api;
  late LoadBuildingUseCase useCase;
  late Directory tmp;
  const id = BuildingId(_buildingId);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('load_building_');
    storage = _FakeStorage();
    final modelFile = File('${tmp.path}/v1.glb');
    await modelFile.writeAsBytes([1, 2, 3]);
    await storage.cacheModel(_buildingId, 'v1', modelFile.path);
    api = _FakeApi();
    useCase = LoadBuildingUseCase(
      api: api,
      cache: ModelCache(storage, documentsDir: () async => tmp),
      storage: storage,
    );
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('con red: devuelve datos frescos, fromCache=false y guarda el payload',
      () async {
    final result = await useCase.execute(id);

    expect(result.isRight, isTrue);
    expect(result.right.fromCache, isFalse);
    expect(result.right.building.nombre, 'Edificio de Ingenierias');
    expect(result.right.floors, hasLength(1));
    expect(result.right.hasModel, isTrue);
    expect(storage.getCachedBuildingPayload(_buildingId), isNotNull);
  });

  test('sin red y con metadatos en cache: sirve la copia local (fromCache=true)',
      () async {
    await useCase.execute(id); // carga previa con red
    api.response = const Left('Error de conexion');

    final result = await useCase.execute(id);

    expect(result.isRight, isTrue);
    expect(result.right.fromCache, isTrue);
    expect(result.right.building.nombre, 'Edificio de Ingenierias');
    expect(result.right.floors.single.nombre, 'Piso 1');
    expect(result.right.hasModel, isTrue);
  });

  test('sin red y sin cache: conserva el comportamiento previo (Left)',
      () async {
    api.response = const Left('Error de conexion');

    final result = await useCase.execute(id);

    expect(result.isLeft, isTrue);
    expect(result.left, 'Error de conexion');
  });

  test('sin red y cache corrupta: devuelve el error original sin lanzar',
      () async {
    storage.payloads[_buildingId] = '{no es json';
    api.response = const Left('Error de conexion');

    final result = await useCase.execute(id);

    expect(result.isLeft, isTrue);
    expect(result.left, 'Error de conexion');
  });
}
