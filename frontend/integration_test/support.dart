import 'dart:io';

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:frontend/core/storage/local_storage.dart';
import 'package:frontend/features/mapas/domain/entities.dart';
import 'package:frontend/features/mapas/infrastructure/api/mapas_api.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const buildingId = '3f8634e7-29c3-4cda-97f7-129b5587c899';
const floorId = '061917df-d73c-426a-8b93-56025b20c74d';
const modelVersion = 'v1';

Map<String, dynamic> buildingPayload() => {
      'building': {
        'id': buildingId,
        'nombre': 'Edificio de Ingenierias',
        'codigo': 'ING',
        'geometria': {'type': 'Polygon', 'coordinates': []},
        'pisos': [floorId],
        'versionModelo3D': modelVersion,
        'createdAt': '2026-09-27T20:55:20.139Z',
        'updatedAt': '2026-09-27T20:55:20.139Z',
      },
      'floors': [
        {
          'id': floorId,
          'edificioId': buildingId,
          'numero': 1,
          'nombre': 'Piso 1',
          'modelo3DUrl': 'v1.glb',
          'modelo3DVersion': modelVersion,
          'alturaMetros': 3.0,
          'pois': <String>[],
          'createdAt': '2026-09-27T20:55:20.139Z',
          'updatedAt': '2026-09-27T20:55:20.139Z',
        }
      ],
      'model3DUrl': 'https://example.invalid/v1.glb',
    };

/// API que responde desde memoria (carga online simulada y reproducible).
class InMemoryMapasApi extends MapasApi {
  InMemoryMapasApi() : super(Dio());

  @override
  Future<Either<String, Map<String, dynamic>>> getBuilding(
          BuildingId id) async =>
      Right(buildingPayload());
}

/// API sin red: DNS inexistente, falla igual que el modo avion.
MapasApi offlineApi() => MapasApi(Dio(BaseOptions(
      baseUrl: 'https://sin-red.invalid/api',
      connectTimeout: const Duration(seconds: 2),
    )));

/// Precarga la cache de modelo (archivo + indice Hive) como lo haria una carga previa.
Future<LocalStorage> preloadModelCache() async {
  final storage = LocalStorage();
  await storage.init();
  final dir = await getApplicationDocumentsDirectory();
  final file =
      File(p.join(dir.path, 'models', buildingId, '$modelVersion.glb'));
  await file.create(recursive: true);
  await file.writeAsBytes(List<int>.filled(1024, 0));
  await storage.cacheModel(buildingId, modelVersion, file.path);
  return storage;
}
