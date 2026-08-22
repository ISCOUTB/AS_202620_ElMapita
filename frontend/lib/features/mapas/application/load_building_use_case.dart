// lib/features/mapas/application/load_building_use_case.dart

import 'package:either_dart/either.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';
import '../../infrastructure/api/mapas_api.dart';
import '../../infrastructure/storage/model_cache.dart';

class LoadBuildingUseCase {
  final MapasApi _api;
  final ModelCache _cache;

  LoadBuildingUseCase({
    required MapasApi api,
    required ModelCache cache,
  })  : _api = api,
        _cache = cache;

  Future<Either<String, LoadBuildingResult>> execute(BuildingId buildingId) async {
    // 1. Get building data from API
    final buildingResult = await _api.getBuilding(buildingId);
    if (buildingResult.isLeft) {
      return Left(buildingResult.left);
    }

    final buildingData = buildingResult.right;
    final building = Building.fromJson(buildingData['building']);
    final floors = (buildingData['floors'] as List)
        .map((e) => Floor.fromJson(e))
        .toList();
    final modelUrl = buildingData['model3DUrl'] as String;

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
      ));
    }

    return Right(LoadBuildingResult(
      building: building,
      floors: floors,
      modelPath: modelResult.right,
      modelError: null,
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

  const LoadBuildingResult({
    required this.building,
    required this.floors,
    this.modelPath,
    this.modelError,
  });

  bool get hasModel => modelPath != null;
}