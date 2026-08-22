// lib/features/ubicacion/infrastructure/platform/location_service_impl.dart

import 'package:either_dart/either.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../../../core/platform/location_service.dart';
import '../../../core/platform/permission_service.dart';

class LocationServiceImpl implements LocationRepository {
  final LocationService _platformService;

  LocationServiceImpl(this._platformService);

  @override
  Future<Either<String, UserLocation>> getCurrentLocation() async {
    final result = await _platformService.getLocationWithPrecision();
    return result.fold(
      (error) => Left(error),
      (data) => Right(UserLocation(
        coordinates: Coordinates(
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
        ),
        precisionMeters: data['accuracy'] as double,
        floorEstimate: data['floorEstimate'] as int?,
        source: LocationSource.values.byName(data['source'] as String),
        timestamp: DateTime.parse(data['timestamp'] as String),
        uncertaintyShown: data['uncertaintyShown'] as bool,
      )),
    );
  }

  @override
  Stream<UserLocation> watchLocation() {
    return _platformService.watchPosition().map((position) {
      return UserLocation(
        coordinates: Coordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        precisionMeters: position.accuracy,
        floorEstimate: _estimateFloor(position.altitude),
        source: LocationSource.gps,
        timestamp: DateTime.now(),
        uncertaintyShown: position.accuracy > 15,
      );
    });
  }

  @override
  Future<Either<String, bool>> requestPermission() async {
    final result = await _platformService.requestLocationPermission();
    return result.fold(
      (error) => Left(error),
      (granted) => Right(granted),
    );
  }

  @override
  Future<bool> isPermissionGranted() async {
    return await _platformService.isLocationPermissionGranted();
  }

  @override
  Future<Either<String, UserLocation>> setManualLocation(ManualLocationInput input) async {
    final result = await _platformService.setManualLocation(
      buildingId: input.buildingId,
      floor: input.floor,
      x: input.x,
      y: input.y,
    );
    return result.fold(
      (error) => Left(error),
      (data) => Right(UserLocation(
        coordinates: Coordinates(
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
        ),
        precisionMeters: data['accuracy'] as double,
        floorEstimate: data['floorEstimate'] as int?,
        source: LocationSource.manual,
        timestamp: DateTime.parse(data['timestamp'] as String),
        uncertaintyShown: data['uncertaintyShown'] as bool,
      )),
    );
  }

  int? _estimateFloor(double altitude) {
    if (altitude <= 0) return null;
    return (altitude / 3.5).ceil();
  }
}