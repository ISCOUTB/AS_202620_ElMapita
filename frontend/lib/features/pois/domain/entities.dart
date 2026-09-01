// lib/features/pois/domain/entities.dart

import 'package:uuid/uuid.dart';
import '../../../core/kernel/entity.dart';
import '../../../core/kernel/value_object.dart';

class PoiId extends ValueObject {
  final String value;
  const PoiId(this.value);
  @override List<Object?> get props => [value];
  
  factory PoiId.generate() => PoiId(const Uuid().v4());
  factory PoiId.fromString(String value) => PoiId(value);
}

class FloorId extends ValueObject {
  final String value;
  const FloorId(this.value);
  @override List<Object?> get props => [value];
  
  factory FloorId.generate() => FloorId(const Uuid().v4());
  factory FloorId.fromString(String value) => FloorId(value);
}

enum PoiType { salon, laboratorio, bano, cafeteria, biblioteca, escalera, ascensor, otro }

class Poi extends Entity<PoiId> {
  final FloorId pisoId;
  final PoiType tipo;
  final String nombre;
  final Map<String, dynamic> geometria; // GeoJSON Point
  final Map<String, dynamic> metadatos;

  const Poi({
    required super.id,
    required this.pisoId,
    required this.tipo,
    required this.nombre,
    required this.geometria,
    required this.metadatos,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Poi.create({
    required FloorId pisoId,
    required PoiType tipo,
    required String nombre,
    required Map<String, dynamic> geometria,
    required Map<String, dynamic> metadatos,
  }) {
    final now = DateTime.now();
    return Poi(
      id: PoiId.generate(),
      pisoId: pisoId,
      tipo: tipo,
      nombre: nombre,
      geometria: geometria,
      metadatos: metadatos,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: PoiId.fromString(json['id'] as String),
      pisoId: FloorId.fromString(json['pisoId'] as String),
      tipo: PoiType.values.byName(json['tipo'] as String),
      nombre: json['nombre'] as String,
      geometria: json['geometria'] as Map<String, dynamic>,
      metadatos: json['metadatos'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'pisoId': pisoId.value,
    'tipo': tipo.name,
    'nombre': nombre,
    'geometria': geometria,
    'metadatos': metadatos,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}