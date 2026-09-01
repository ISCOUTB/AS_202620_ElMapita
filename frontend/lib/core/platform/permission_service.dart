// Platform services - Permissions
// lib/core/platform/permission_service.dart

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart' show Permission;
import 'package:either_dart/either.dart';

class PermissionService {
  Future<Either<String, bool>> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left('Error requesting location permission: $e');
    }
  }

  Future<Either<String, bool>> requestLocationAlwaysPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left('Error requesting location always permission: $e');
    }
  }

  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> isLocationAlwaysPermissionGranted() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}