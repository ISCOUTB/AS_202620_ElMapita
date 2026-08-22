// lib/features/mapas/infrastructure/storage/model_cache.dart

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/storage/local_storage.dart';

class ModelCache {
  final LocalStorage _storage;
  Dio? _downloadDio;

  ModelCache(this._storage);

  Dio get _dio => _downloadDio ??= Dio(BaseOptions(
    responseType: ResponseType.bytes,
    receiveTimeout: const Duration(minutes: 5),
  ));

  Future<Either<String, String>> getOrDownloadModel({
    required String buildingId,
    required String version,
    required String downloadUrl,
  }) async {
    // Check cache first
    final cachedPath = _storage.getCachedModelPath(buildingId, version);
    if (cachedPath != null) {
      return Right(cachedPath);
    }

    // Download if not cached
    return await _downloadModel(buildingId, version, downloadUrl);
  }

  Future<Either<String, String>> _downloadModel(
    String buildingId,
    String version,
    String url,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = path.join(appDir.path, 'models', buildingId);
      final filePath = path.join(modelsDir, '$version.glb');

      // Ensure directory exists
      final dir = Directory(modelsDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Download file
      final response = await _dio.get<List<int>>(url);
      if (response.statusCode == 200 && response.data != null) {
        final file = File(filePath);
        await file.writeAsBytes(response.data!);
        
        // Update cache index
        await _storage.cacheModel(buildingId, version, filePath);
        
        return Right(filePath);
      }
      return Left('Failed to download model: ${response.statusCode}');
    } catch (e) {
      return Left('Error downloading model: $e');
    }
  }

  Future<void> clearModelCache(String buildingId) async {
    // Implementation would clear specific building cache
  }

  Future<void> clearAllCache() async {
    // Implementation would clear all model cache
  }
}