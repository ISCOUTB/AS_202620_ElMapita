// lib/features/ubicacion/presentation/bloc/ubicacion_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../application/get_location_use_case.dart';
import '../../domain/entities.dart';
import '../../../../core/platform/permission_service.dart';

// Events
abstract class UbicacionEvent extends Equatable {
  const UbicacionEvent();
  @override List<Object?> get props => [];
}

class GetCurrentLocation extends UbicacionEvent {}

class WatchLocation extends UbicacionEvent {}

class StopWatchingLocation extends UbicacionEvent {}

class RequestLocationPermission extends UbicacionEvent {}

class SetManualLocationEvent extends UbicacionEvent {
  final ManualLocationInput input;
  const SetManualLocationEvent(this.input);
  @override List<Object?> get props => [input];
}

class ClearLocationError extends UbicacionEvent {}

// States
abstract class UbicacionState extends Equatable {
  const UbicacionState();
  @override List<Object?> get props => [];
}

class UbicacionInitial extends UbicacionState {}

class UbicacionLoading extends UbicacionState {}

class LocationLoaded extends UbicacionState {
  final UserLocation location;
  const LocationLoaded(this.location);
  @override List<Object?> get props => [location];
}

class LocationWatching extends UbicacionState {
  final UserLocation location;
  const LocationWatching(this.location);
  @override List<Object?> get props => [location];
}

class PermissionRequested extends UbicacionState {
  final bool granted;
  const PermissionRequested(this.granted);
  @override List<Object?> get props => [granted];
}

class ManualLocationSet extends UbicacionState {
  final UserLocation location;
  const ManualLocationSet(this.location);
  @override List<Object?> get props => [location];
}

class UbicacionError extends UbicacionState {
  final String message;
  const UbicacionError(this.message);
  @override List<Object?> get props => [message];
}

// Bloc
class UbicacionBloc extends Bloc<UbicacionEvent, UbicacionState> {
  final GetLocationUseCase _getLocationUseCase;
  final PermissionService _permissionService;
  Stream<UserLocation>? _locationStream;

  UbicacionBloc({
    required GetLocationUseCase getLocationUseCase,
    required PermissionService permissionService,
  })  : _getLocationUseCase = getLocationUseCase,
        _permissionService = permissionService,
        super(UbicacionInitial()) {
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<WatchLocation>(_onWatchLocation);
    on<StopWatchingLocation>(_onStopWatchingLocation);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<SetManualLocationEvent>(_onSetManualLocation);
    on<ClearLocationError>(_onClearError);
  }

  @override
  Future<void> close() {
    _locationStream = null;
    return super.close();
  }

  Future<void> _onGetCurrentLocation(GetCurrentLocation event, Emitter<UbicacionState> emit) async {
    emit(UbicacionLoading());
    final result = await _getLocationUseCase.execute();
    result.fold(
      (error) => emit(UbicacionError(error)),
      (location) => emit(LocationLoaded(location)),
    );
  }

  Future<void> _onWatchLocation(WatchLocation event, Emitter<UbicacionState> emit) async {
    emit(UbicacionLoading());
    _locationStream = _getLocationUseCase.watch();
    await emit.onEach(_locationStream!, onData: (location) {
      emit(LocationWatching(location));
    });
  }

  Future<void> _onStopWatchingLocation(StopWatchingLocation event, Emitter<UbicacionState> emit) async {
    await _locationStream?.drain();
    _locationStream = null;
    emit(UbicacionInitial());
  }

  Future<void> _onRequestLocationPermission(RequestLocationPermission event, Emitter<UbicacionState> emit) async {
    emit(UbicacionLoading());
    final result = await _getLocationUseCase.requestPermission();
    result.fold(
      (error) => emit(UbicacionError(error)),
      (granted) => emit(PermissionRequested(granted)),
    );
  }

  Future<void> _onSetManualLocation(SetManualLocationEvent event, Emitter<UbicacionState> emit) async {
    emit(UbicacionLoading());
    final result = await _getLocationUseCase.setManualLocation(event.input);
    result.fold(
      (error) => emit(UbicacionError(error)),
      (location) => emit(ManualLocationSet(location)),
    );
  }

  void _onClearError(ClearLocationError event, Emitter<UbicacionState> emit) {
    emit(UbicacionInitial());
  }
}