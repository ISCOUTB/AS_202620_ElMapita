// lib/features/ubicacion/domain/repositories.dart

import 'package:either_dart/either.dart';
import 'entities.dart';

abstract class LocationRepository {
  Future<Either<String, UserLocation>> getCurrentLocation();
  Stream<UserLocation> watchLocation();
  Future<Either<String, bool>> requestPermission();
  Future<bool> isPermissionGranted();
  Future<Either<String, UserLocation>> setManualLocation(ManualLocationInput input);
}