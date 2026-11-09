// lib/features/mapas/application/load_building_use_case.dart

import 'package:either_dart/either.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/entities.dart';
import '../infrastructure/api/mapas_api.dart';
import '../infrastructure/storage/model_cache.dart';

class LoadBuildingUseCase {
  final MapasApi _api;
  final ModelCache _cache;
  final LocalStorage _storage;

  LoadBuildingUseCase({
    required MapasApi api,
    required ModelCache cache,
    required LocalStorage storage,
  })  : _api = api,
        _cache = cache,
        _storage = storage;

  Future<Either<String, LoadBuildingResult>> execute(BuildingId buildingId) async {
    // 1. Get building data from API; si falla, usar la copia local (EC-04).
    final buildingResult = await _api.getBuilding(buildingId);
    final Map<String, dynamic> buildingData;
    final bool fromCache;
    if (buildingResult.isRight) {
      buildingData = buildingResult.right;
      fromCache = false;
      await _storage.cacheBuildingPayload(buildingId.value, buildingData);
    } else {
      final cached = _storage.getCachedBuildingPayload(buildingId.value);
      if (cached == null) return Left(buildingResult.left);
      buildingData = cached;
      fromCache = true;
    }

    final Building building;
    final List<Floor> floors;
    final String modelUrl;
    try {
      building = Building.fromJson(buildingData['building']);
      floors = (buildingData['floors'] as List)
          .map((e) => Floor.fromJson(e))
          .toList();
      modelUrl = buildingData['model3DUrl'] as String;
    } catch (_) {
      // Copia local incompatible: se informa el error original de la API.
      if (fromCache) return Left(buildingResult.left);
      rethrow;
    }

    // 2. Download/cache model
    final modelResult = await _cache.getOrDownloadModel(
      buildingId: buildingId.value,
      version: building.versionModelo3D.value,
      downloadUrl: modelUrl,
    );

    if (modelResult.isLeft) {
      // Return building data even if model fails (can show error in UI)
      return Right(LoadBuildingResult(
        building: building,
        floors: floors,
        modelPath: null,
        modelError: modelResult.left,
        fromCache: fromCache,
      ));
    }

    return Right(LoadBuildingResult(
      building: building,
      floors: floors,
      modelPath: modelResult.right,
      modelError: null,
      fromCache: fromCache,
    ));
  }

  Future<Either<String, List<Building>>> getAllBuildings() async {
    return await _api.getBuildings();
  }
}

class LoadBuildingResult {
  final Building building;
  final List<Floor> floors;
  final String? modelPath;
  final String? modelError;

  /// true si los metadatos vienen de la copia local (sin red).
  final bool fromCache;

  const LoadBuildingResult({
    required this.building,
    required this.floors,
    this.modelPath,
    this.modelError,
    this.fromCache = false,
  });

  bool get hasModel => modelPath != null;
}