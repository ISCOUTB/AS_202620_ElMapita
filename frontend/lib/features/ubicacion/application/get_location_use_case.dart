// lib/features/ubicacion/application/get_location_use_case.dart

import 'package:either_dart/either.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';

class GetLocationUseCase {
  final LocationRepository _repository;

  GetLocationUseCase({required LocationRepository repository}) : _repository = repository;

  Future<Either<String, UserLocation>> execute() async {
    return await _repository.getCurrentLocation();
  }

  Stream<UserLocation> watch() {
    return _repository.watchLocation();
  }

  Future<Either<String, bool>> requestPermission() async {
    return await _repository.requestPermission();
  }

  Future<Either<String, UserLocation>> setManualLocation(ManualLocationInput input) async {
    return await _repository.setManualLocation(input);
  }
}