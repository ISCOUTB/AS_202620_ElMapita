// lib/features/mapas/infrastructure/storage/model_cache.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/storage/local_storage.dart';

class ModelCache {
  final LocalStorage _storage;
  final Future<Directory> Function() _documentsDir;
  Dio? _downloadDio;

  ModelCache(
    this._storage, {
    Dio? dio,
    Future<Directory> Function()? documentsDir,
  })  : _downloadDio = dio,
        _documentsDir = documentsDir ?? getApplicationDocumentsDirectory;

  Dio get _dio => _downloadDio ??= Dio(BaseOptions(
    responseType: ResponseType.bytes,
    receiveTimeout: const Duration(minutes: 5),
  ));

  /// Descargas en curso por (edificio, versión): la precarga del splash y la
  /// pantalla 3D comparten una sola descarga en vez de escribir el mismo
  /// archivo dos veces.
  final Map<String, Future<Either<String, String>>> _inFlight = {};

  Future<Either<String, String>> getOrDownloadModel({
    required String buildingId,
    required String version,
    required String downloadUrl,
  }) {
    // Check cache first
    final cachedPath = _storage.getCachedModelPath(buildingId, version);
    if (cachedPath != null) {
      return Future.value(Right(cachedPath));
    }

    final key = '$buildingId/$version';
    return _inFlight.putIfAbsent(
      key,
      () => _downloadAndEvict(buildingId, version, downloadUrl)
          .whenComplete(() {
        // Sin devolver el Future que quita: whenComplete esperaria a ese mismo.
        _inFlight.remove(key);
      }),
    );
  }

  Future<Either<String, String>> _downloadAndEvict(
    String buildingId,
    String version,
    String downloadUrl,
  ) async {
    final result = await _downloadModel(buildingId, version, downloadUrl);
    // Solo se desaloja tras una descarga exitosa: si falla, se conserva la
    // versión anterior para poder seguir usando el mapa sin red.
    if (result.isRight) {
      await _evictOtherVersions(buildingId, keepVersion: version);
    }
    return result;
  }

  Future<Either<String, String>> _downloadModel(
    String buildingId,
    String version,
    String url,
  ) async {
    try {
      final appDir = await _documentsDir();
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

  /// Los modelos son inmutables por versión: una versión nueva nunca reemplaza
  /// a la anterior en su clave, así que las viejas solo ocupan espacio.
  Future<void> _evictOtherVersions(
    String buildingId, {
    required String keepVersion,
  }) async {
    final cached = _storage.getCachedModelsOf(buildingId);
    for (final entry in cached.entries) {
      if (entry.key == keepVersion) continue;
      await _deleteFileIfExists(entry.value);
      await _storage.removeCachedModel(buildingId, entry.key);
    }
  }

  Future<void> clearModelCache(String buildingId) async {
    final cached = _storage.getCachedModelsOf(buildingId);
    for (final entry in cached.entries) {
      await _deleteFileIfExists(entry.value);
      await _storage.removeCachedModel(buildingId, entry.key);
    }
  }

  Future<void> clearAllCache() async {
    for (final buildingId in _storage.getCachedBuildingIds()) {
      await clearModelCache(buildingId);
    }
  }

  Future<void> _deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
