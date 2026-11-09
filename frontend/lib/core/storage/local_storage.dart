// Local storage using Hive and SharedPreferences
// lib/core/storage/local_storage.dart

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorage {
  static const String _boxName = 'elmapita_cache';
  late Box _box;
  late SharedPreferences _prefs;
  bool _initialized = false;
  final Future<String> Function()? _hivePath;

  /// [hivePath] permite a las pruebas usar un directorio propio sin plugins.
  LocalStorage({Future<String> Function()? hivePath}) : _hivePath = hivePath;

  Future<void> init() async {
    if (_initialized) return;

    if (_hivePath != null) {
      Hive.init(await _hivePath());
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(path.join(appDocDir.path, 'hive'));
    }

    _box = await Hive.openBox(_boxName);
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Hive operations (for complex objects)
  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  dynamic get(String key) {
    return _box.get(key);
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  // SharedPreferences operations (for simple values)
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool getBool(String key) {
    return _prefs.getBool(key) ?? false;
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Metadatos de edificio (payload de la API) para uso sin red
  Future<void> cacheBuildingPayload(
      String buildingId, Map<String, dynamic> payload) async {
    await put('building_meta_$buildingId', jsonEncode(payload));
  }

  /// Último payload guardado o null si no existe o está dañado.
  Map<String, dynamic>? getCachedBuildingPayload(String buildingId) {
    final raw = get('building_meta_$buildingId');
    if (raw is! String) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Model 3D cache specific
  Future<void> cacheModel(String buildingId, String version, String localPath) async {
    await put('model_${buildingId}_$version', localPath);
    await setString('model_${buildingId}_version', version);
  }

  String? getCachedModelPath(String buildingId, String version) {
    return get('model_${buildingId}_$version') as String?;
  }

  String? getCachedModelVersion(String buildingId) {
    return getString('model_${buildingId}_version');
  }

  /// Versiones en caché de un edificio -> ruta local del .glb.
  /// El id de edificio es un UUID (sin '_'), por lo que el prefijo no es ambiguo.
  Map<String, String> getCachedModelsOf(String buildingId) {
    final prefix = 'model_${buildingId}_';
    final result = <String, String>{};
    for (final key in _box.keys) {
      if (key is String && key.startsWith(prefix)) {
        result[key.substring(prefix.length)] = _box.get(key) as String;
      }
    }
    return result;
  }

  /// Ids de edificio que tienen algún modelo en caché.
  Set<String> getCachedBuildingIds() {
    final ids = <String>{};
    for (final key in _box.keys) {
      if (key is String && key.startsWith('model_')) {
        final rest = key.substring('model_'.length);
        final cut = rest.indexOf('_');
        if (cut > 0) ids.add(rest.substring(0, cut));
      }
    }
    return ids;
  }

  Future<void> removeCachedModel(String buildingId, String version) async {
    await delete('model_${buildingId}_$version');
    if (getCachedModelVersion(buildingId) == version) {
      await _prefs.remove('model_${buildingId}_version');
    }
  }
}