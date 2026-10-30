// lib/features/mapas/infrastructure/api/campus_layers_repository.dart
//
// Lee la tabla `mapa_capas` de Supabase (lectura publica por RLS) y guarda la
// ultima respuesta en disco para poder filtrar sin red.

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/campus_layers.dart';

/// La clave `publishable` es publica por diseno (solo lee lo que permite RLS).
const String kSupabaseUrl = 'https://smgbmfbgxfjkspvtyvfb.supabase.co';
const String kSupabasePublishableKey =
    'sb_publishable_GLfxnLoXZyfzBrdc5f9gqQ_t8nOhhA1';

/// Modelo del campus en el bucket publico `mapa-campus`. Al subir una version
/// nueva del .glb hay que cambiar `kCampusModelVersion` para invalidar la cache.
const String kCampusModelUrl =
    '$kSupabaseUrl/storage/v1/object/public/mapa-campus/utb_campus.glb';
const String kCampusModelVersion = '1';
const String kCampusBuildingId = 'campus';

class CampusLayersRepository {
  static const String _cacheKey = 'mapa_capas_json';

  final LocalStorage _storage;
  final Dio _dio;

  CampusLayersRepository(this._storage, {Dio? dio}) : _dio = dio ?? Dio();

  /// Intenta la red; si falla usa la copia local; sin ninguna, capas vacias
  /// (el mapa se ve completo, solo que el filtro no oculta nada).
  CampusLayers? _memo;

  Future<CampusLayers> load() async {
    final memo = _memo;
    if (memo != null) return memo;
    final layers = await _fetch();
    if (layers.categories.isNotEmpty) _memo = layers;
    return layers;
  }

  Future<CampusLayers> _fetch() async {
    try {
      final response = await _dio.get<String>(
        '$kSupabaseUrl/rest/v1/mapa_capas',
        queryParameters: {'select': 'categoria,nodo'},
        options: Options(
          headers: {'apikey': kSupabasePublishableKey},
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final body = response.data;
      if (body != null) {
        final layers = parse(body);
        await _storage.setString(_cacheKey, body);
        return layers;
      }
    } catch (_) {
      // Sin red o error del servidor: se cae a la copia local.
    }
    final cached = _storage.getString(_cacheKey);
    return cached == null ? CampusLayers(const {}) : parse(cached);
  }

  static CampusLayers parse(String body) {
    final rows = jsonDecode(body) as List;
    final byCategory = <String, Set<String>>{};
    for (final row in rows) {
      final categoria = (row as Map)['categoria'] as String;
      byCategory.putIfAbsent(categoria, () => <String>{}).add(row['nodo'] as String);
    }
    return CampusLayers(byCategory);
  }
}
