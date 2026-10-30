// lib/features/mapas/domain/campus_geo_reference.dart
//
// Convierte latitud/longitud del GPS a coordenadas del modelo 3D del campus.
// Logica pura (sin Flutter ni plugins), cubierta por tests.

import 'dart:math' as math;

/// Punto sobre el plano del terreno, en metros del modelo (eje X y eje Z de glTF).
class ModelPoint {
  final double x;
  final double z;

  const ModelPoint(this.x, this.z);
}

/// Transformacion de similitud (rotacion + escala + desplazamiento) entre el
/// plano local este/norte alrededor de ([originLat], [originLon]) y el modelo.
class CampusGeoReference {
  final double originLat;
  final double originLon;
  final double ar;
  final double ai;
  final double tx;
  final double tz;
  final double minX;
  final double maxX;
  final double minZ;
  final double maxZ;

  const CampusGeoReference({
    required this.originLat,
    required this.originLon,
    required this.ar,
    required this.ai,
    required this.tx,
    required this.tz,
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
  });

  /// Calibracion provisional del campus Ternera: ajuste por minimos cuadrados
  /// entre los centros de Bloque A1, A2, A5 y las canchas de futbol y softbol
  /// del modelo contra sus poligonos en OpenStreetMap (error medio ~9 m).
  /// Datos de mapa (c) colaboradores de OpenStreetMap, licencia ODbL.
  /// Se mejora con puntos tomados en sitio.
  static const CampusGeoReference utbTernera = CampusGeoReference(
    originLat: 10.3687,
    originLon: -75.4645,
    ar: 0.7037688010352227,
    ai: 0.6475444290808399,
    tx: 87.46136076530392,
    tz: -304.17586844832044,
    // Caja del nodo `Terreno` en el .glb.
    minX: -22.1,
    maxX: 299.3,
    minZ: -313.7,
    maxZ: 4.4,
  );

  static const double _metersPerDegLat = 110574;
  static const double _metersPerDegLonAtEquator = 111320;

  ModelPoint toModel(double lat, double lon) {
    final east = (lon - originLon) *
        _metersPerDegLonAtEquator *
        math.cos(originLat * math.pi / 180);
    final north = (lat - originLat) * _metersPerDegLat;
    // El plano del modelo esta reflejado respecto a este/norte (glTF: Z = -Y).
    final u = -east;
    final v = north;
    return ModelPoint(ar * u - ai * v + tx, ai * u + ar * v + tz);
  }

  /// Dentro del terreno mas [marginMeters] (el GPS tiene 5-10 m de error).
  bool isInside(ModelPoint p, {double marginMeters = 30}) =>
      p.x >= minX - marginMeters &&
      p.x <= maxX + marginMeters &&
      p.z >= minZ - marginMeters &&
      p.z <= maxZ + marginMeters;
}
