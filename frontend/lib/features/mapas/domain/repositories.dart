// lib/features/mapas/domain/repositories.dart

import 'package:either_dart/either.dart';
import 'entities.dart';

abstract class BuildingRepository {
  Future<Either<String, Building>> getById(BuildingId id);
  Future<Either<String, List<Building>>> getAll();
  Future<Either<String, Building?>> getByCodigo(String codigo);
}

abstract class FloorRepository {
  Future<Either<String, Floor>> getById(FloorId id);
  Future<Either<String, List<Floor>>> getByBuildingId(BuildingId buildingId);
}

abstract class Model3DRepository {
  Future<Either<String, String>> getSignedUrl(BuildingId buildingId, ModelVersion version);
  Future<Either<String, String>> downloadModel(String url, String localPath);
}