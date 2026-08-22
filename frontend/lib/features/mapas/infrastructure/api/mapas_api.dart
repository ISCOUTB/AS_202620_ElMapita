// lib/features/mapas/infrastructure/api/mapas_api.dart

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class MapasApi {
  final Dio _dio;

  MapasApi(this._dio);

  Future<Either<String, List<Building>>> getBuildings() async {
    try {
      final response = await _dio.get('/v1/map/buildings');
      if (response.statusCode == 200) {
        final data = response.data['buildings'] as List;
        return Right(data.map((e) => Building.fromJson(e)).toList());
      }
      return Left('Error ${response.statusCode}: ${response.data}');
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<String, Map<String, dynamic>>> getBuilding(BuildingId id) async {
    try {
      final response = await _dio.get('/v1/map/buildings/${id.value}');
      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }
      return Left('Error ${response.statusCode}: ${response.data}');
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<String, Map<String, dynamic>>> getFloorModel(FloorId id) async {
    try {
      final response = await _dio.get('/v1/map/floors/${id.value}/model');
      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }
      return Left('Error ${response.statusCode}: ${response.data}');
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      return 'Error ${e.response?.statusCode}: ${e.response?.data}';
    }
    return 'Network error: ${e.message}';
  }
}