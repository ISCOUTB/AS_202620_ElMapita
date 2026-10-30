// lib/features/mapas/domain/arrival_guide.dart
//
// Destino elegido y fases de la guia de llegada. Logica pura, con tests.

import 'dart:math' as math;
import 'campus_geo_reference.dart';

/// Caja de un nodo sobre el plano del terreno, en metros del modelo.
class NodeBounds {
  final double minX;
  final double maxX;
  final double minZ;
  final double maxZ;

  const NodeBounds({
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
  });

  /// Distancia del punto al borde de la caja; 0 si esta dentro.
  double distanceTo(ModelPoint p) {
    final dx = math.max(math.max(minX - p.x, p.x - maxX), 0.0);
    final dz = math.max(math.max(minZ - p.z, p.z - maxZ), 0.0);
    return math.sqrt(dx * dx + dz * dz);
  }
}

class Destination {
  final String node;
  final String category;
  final NodeBounds bounds;

  const Destination({
    required this.node,
    required this.category,
    required this.bounds,
  });

  /// `Cancha_Futbol_6126m2` -> `Cancha Futbol`; `Bloque_A1` -> `Bloque A1`.
  String get label => node
      .replaceAll(RegExp(r'_?\d+m2$'), '')
      .replaceAll('_', ' ')
      .trim();
}

enum ArrivalPhase { far, near, arrived }

class ArrivalGuide {
  /// Desde esta distancia al edificio el telefono empieza a vibrar.
  final double nearMeters;

  /// Distancia al borde del edificio que cuenta como "llegaste". Es mayor que
  /// el error del GPS (5-10 m) para no quedarse esperando una llegada que no
  /// llega.
  final double arrivedMeters;

  const ArrivalGuide({this.nearMeters = 60, this.arrivedMeters = 15});

  ArrivalPhase phaseFor(double distanceMeters) {
    if (distanceMeters <= arrivedMeters) return ArrivalPhase.arrived;
    if (distanceMeters <= nearMeters) return ArrivalPhase.near;
    return ArrivalPhase.far;
  }
}
