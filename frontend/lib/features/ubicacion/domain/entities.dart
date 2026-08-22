// lib/features/ubicacion/domain/entities.dart

import 'package:equatable/equatable.dart';
import '../../../core/kernel/value_object.dart';

class Coordinates extends ValueObject {
  final double latitude;
  final double longitude;
  const Coordinates({required this.latitude, required this.longitude});
  @override List<Object?> get props => [latitude, longitude];
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

enum PrecisionLevel { high, medium, low, manual }
enum LocationSource { gps, wifi, ble, manual }

class UserLocation extends Equatable {
  final Coordinates coordinates;
  final double precisionMeters;
  final int? floorEstimate;
  final LocationSource source;
  final DateTime timestamp;
  final bool uncertaintyShown;

  const UserLocation({
    required this.coordinates,
    required this.precisionMeters,
    this.floorEstimate,
    required this.source,
    required this.timestamp,
    required this.uncertaintyShown,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      coordinates: Coordinates(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      precisionMeters: (json['precisionMeters'] as num).toDouble(),
      floorEstimate: json['floorEstimate'] as int?,
      source: LocationSource.values.byName(json['source'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      uncertaintyShown: json['uncertaintyShown'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'coordinates': coordinates.toJson(),
    'precisionMeters': precisionMeters,
    'floorEstimate': floorEstimate,
    'source': source.name,
    'timestamp': timestamp.toIso8601String(),
    'uncertaintyShown': uncertaintyShown,
  };

  @override List<Object?> get props => [
    coordinates, precisionMeters, floorEstimate, source, timestamp, uncertaintyShown
  ];
}

class ManualLocationInput extends Equatable {
  final String buildingId;
  final int floor;
  final double x;
  final double y;
  const ManualLocationInput({
    required this.buildingId,
    required this.floor,
    required this.x,
    required this.y,
  });
  @override List<Object?> get props => [buildingId, floor, x, y];
}