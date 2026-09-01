// lib/features/mapas/domain/entities.dart

import 'package:uuid/uuid.dart';
import '../../../core/kernel/entity.dart';
import '../../../core/kernel/value_object.dart';

class BuildingId extends ValueObject {
  final String value;
  const BuildingId(this.value);
  @override List<Object?> get props => [value];
  
  factory BuildingId.generate() => BuildingId(const Uuid().v4());
  factory BuildingId.fromString(String value) => BuildingId(value);
}

class FloorId extends ValueObject {
  final String value;
  const FloorId(this.value);
  @override List<Object?> get props => [value];
  
  factory FloorId.generate() => FloorId(const Uuid().v4());
  factory FloorId.fromString(String value) => FloorId(value);
}

class ModelVersion extends ValueObject {
  final String value;
  const ModelVersion(this.value);
  @override List<Object?> get props => [value];
  
  factory ModelVersion.initial() => const ModelVersion('1.0.0');
}

class Building extends Entity<BuildingId> {
  final String nombre;
  final String codigo;
  final Map<String, dynamic> geometria; // GeoJSON Polygon
  final List<FloorId> pisos;
  final ModelVersion versionModelo3D;

  const Building({
    required super.id,
    required this.nombre,
    required this.codigo,
    required this.geometria,
    required this.pisos,
    required this.versionModelo3D,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Building.create({
    required String nombre,
    required String codigo,
    required Map<String, dynamic> geometria,
    required List<FloorId> pisos,
    required ModelVersion versionModelo3D,
  }) {
    final now = DateTime.now();
    return Building(
      id: BuildingId.generate(),
      nombre: nombre,
      codigo: codigo,
      geometria: geometria,
      pisos: pisos,
      versionModelo3D: versionModelo3D,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: BuildingId.fromString(json['id'] as String),
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      geometria: json['geometria'] as Map<String, dynamic>,
      pisos: (json['pisos'] as List).map((e) => FloorId.fromString(e as String)).toList(),
      versionModelo3D: ModelVersion(json['versionModelo3D'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'nombre': nombre,
    'codigo': codigo,
    'geometria': geometria,
    'pisos': pisos.map((e) => e.value).toList(),
    'versionModelo3D': versionModelo3D.value,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  Building copyWith({
    String? nombre,
    String? codigo,
    Map<String, dynamic>? geometria,
    List<FloorId>? pisos,
    ModelVersion? versionModelo3D,
  }) {
    return Building(
      id: id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      geometria: geometria ?? this.geometria,
      pisos: pisos ?? this.pisos,
      versionModelo3D: versionModelo3D ?? this.versionModelo3D,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class Floor extends Entity<FloorId> {
  final BuildingId edificioId;
  final int numero;
  final String nombre;
  final String modelo3DUrl;
  final ModelVersion modelo3DVersion;
  final double alturaMetros;
  final List<String> pois;

  const Floor({
    required super.id,
    required this.edificioId,
    required this.numero,
    required this.nombre,
    required this.modelo3DUrl,
    required this.modelo3DVersion,
    required this.alturaMetros,
    required this.pois,
    required super.createdAt,
    required super.updatedAt,
  });

  factory Floor.create({
    required BuildingId edificioId,
    required int numero,
    required String nombre,
    required String modelo3DUrl,
    required ModelVersion modelo3DVersion,
    required double alturaMetros,
    required List<String> pois,
  }) {
    final now = DateTime.now();
    return Floor(
      id: FloorId.generate(),
      edificioId: edificioId,
      numero: numero,
      nombre: nombre,
      modelo3DUrl: modelo3DUrl,
      modelo3DVersion: modelo3DVersion,
      alturaMetros: alturaMetros,
      pois: pois,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: FloorId.fromString(json['id'] as String),
      edificioId: BuildingId.fromString(json['edificioId'] as String),
      numero: json['numero'] as int,
      nombre: json['nombre'] as String,
      modelo3DUrl: json['modelo3DUrl'] as String,
      modelo3DVersion: ModelVersion(json['modelo3DVersion'] as String),
      alturaMetros: (json['alturaMetros'] as num).toDouble(),
      pois: (json['pois'] as List).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'edificioId': edificioId.value,
    'numero': numero,
    'nombre': nombre,
    'modelo3DUrl': modelo3DUrl,
    'modelo3DVersion': modelo3DVersion.value,
    'alturaMetros': alturaMetros,
    'pois': pois,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class Poi extends Entity<String> {
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
      id: const Uuid().v4(),
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
      id: json['id'] as String,
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
    'id': id,
    'pisoId': pisoId.value,
    'tipo': tipo.name,
    'nombre': nombre,
    'geometria': geometria,
    'metadatos': metadatos,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

enum PoiType {
  salon,
  laboratorio,
  bano,
  cafeteria,
  biblioteca,
  escalera,
  ascensor,
  otro,
}