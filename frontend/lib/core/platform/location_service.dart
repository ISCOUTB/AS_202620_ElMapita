// Platform services - Location
// lib/core/platform/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:either_dart/either.dart';
import 'permission_service.dart';

class LocationService {
  final PermissionService _permissionService;

  LocationService(this._permissionService);

  Future<Either<String, bool>> requestLocationPermission() {
    return _permissionService.requestLocationPermission();
  }

  Future<bool> isLocationPermissionGranted() {
    return _permissionService.isLocationPermissionGranted();
  }

  Future<Either<String, Position>> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final hasPermission = await _permissionService.isLocationPermissionGranted();
      if (!hasPermission) {
        final result = await _permissionService.requestLocationPermission();
        if (result.isLeft || !result.right) {
          return Left('Location permission not granted');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      return Right(position);
    } catch (e) {
      return Left('Error getting location: $e');
    }
  }

  Stream<Position> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 5,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  Future<Either<String, Map<String, dynamic>>> getLocationWithPrecision() async {
    final result = await getCurrentPosition();
    
    return result.fold(
      (error) => Left(error),
      (position) {
        final precision = _calculatePrecision(position.accuracy);
        final floorEstimate = _estimateFloor(position.altitude);
        
        return Right({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'precision': precision,
          'floorEstimate': floorEstimate,
          'source': 'gps',
          'timestamp': DateTime.now().toIso8601String(),
          'uncertaintyShown': position.accuracy > 15,
        });
      },
    );
  }

  String _calculatePrecision(double accuracy) {
    if (accuracy <= 5) return 'high';
    if (accuracy <= 15) return 'medium';
    if (accuracy <= 50) return 'low';
    return 'manual';
  }

  int? _estimateFloor(double altitude) {
    // Rough estimation: each floor ~3-4 meters
    // This would need calibration per building
    if (altitude <= 0) return null;
    return (altitude / 3.5).ceil();
  }

  // Manual location fallback
  Future<Either<String, Map<String, dynamic>>> setManualLocation({
    required String buildingId,
    required int floor,
    required double x,
    required double y,
  }) async {
    // In a real implementation, this would convert building/floor/x,y to lat/long
    // using the building's reference coordinates
    return Right({
      'latitude': 0.0,
      'longitude': 0.0,
      'accuracy': 0,
      'precision': 'manual',
      'floorEstimate': floor,
      'source': 'manual',
      'timestamp': DateTime.now().toIso8601String(),
      'uncertaintyShown': true,
      'buildingId': buildingId,
      'manualX': x,
      'manualY': y,
    });
  }
}