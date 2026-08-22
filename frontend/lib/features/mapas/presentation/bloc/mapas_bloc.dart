// lib/features/mapas/presentation/bloc/mapas_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../application/load_building_use_case.dart';
import '../../domain/entities.dart';

// Events
abstract class MapasEvent extends Equatable {
  const MapasEvent();
  @override List<Object?> get props => [];
}

class LoadBuilding extends MapasEvent {
  final BuildingId buildingId;
  const LoadBuilding(this.buildingId);
  @override List<Object?> get props => [buildingId];
}

class LoadAllBuildings extends MapasEvent {}

class SwitchFloor extends MapasEvent {
  final FloorId floorId;
  const SwitchFloor(this.floorId);
  @override List<Object?> get props => [floorId];
}

class ClearError extends MapasEvent {}

// States
abstract class MapasState extends Equatable {
  const MapasState();
  @override List<Object?> get props => [];
}

class MapasInitial extends MapasState {}

class MapasLoading extends MapasState {}

class BuildingsLoaded extends MapasState {
  final List<Building> buildings;
  const BuildingsLoaded(this.buildings);
  @override List<Object?> get props => [buildings];
}

class BuildingLoaded extends MapasState {
  final Building building;
  final List<Floor> floors;
  final Floor currentFloor;
  final String? modelPath;
  final String? modelError;
  const BuildingLoaded({
    required this.building,
    required this.floors,
    required this.currentFloor,
    this.modelPath,
    this.modelError,
  });
  @override List<Object?> get props => [building, floors, currentFloor, modelPath, modelError];
}

class FloorSwitched extends MapasState {
  final Floor floor;
  final String? modelPath;
  final String? modelError;
  const FloorSwitched({
    required this.floor,
    this.modelPath,
    this.modelError,
  });
  @override List<Object?> get props => [floor, modelPath, modelError];
}

class MapasError extends MapasState {
  final String message;
  const MapasError(this.message);
  @override List<Object?> get props => [message];
}

// Bloc
class MapasBloc extends Bloc<MapasEvent, MapasState> {
  final LoadBuildingUseCase _loadBuildingUseCase;

  MapasBloc({required LoadBuildingUseCase loadBuildingUseCase})
      : _loadBuildingUseCase = loadBuildingUseCase,
        super(MapasInitial()) {
    on<LoadBuilding>(_onLoadBuilding);
    on<LoadAllBuildings>(_onLoadAllBuildings);
    on<SwitchFloor>(_onSwitchFloor);
    on<ClearError>(_onClearError);
  }

  Future<void> _onLoadBuilding(LoadBuilding event, Emitter<MapasState> emit) async {
    emit(MapasLoading());
    final result = await _loadBuildingUseCase.execute(event.buildingId);
    result.fold(
      (error) => emit(MapasError(error)),
      (data) => emit(BuildingLoaded(
        building: data.building,
        floors: data.floors,
        currentFloor: data.floors.firstWhere(
          (f) => f.numero == 1,
          orElse: () => data.floors.first,
        ),
        modelPath: data.modelPath,
        modelError: data.modelError,
      )),
    );
  }

  Future<void> _onLoadAllBuildings(LoadAllBuildings event, Emitter<MapasState> emit) async {
    emit(MapasLoading());
    final result = await _loadBuildingUseCase.getAllBuildings();
    result.fold(
      (error) => emit(MapasError(error)),
      (buildings) => emit(BuildingsLoaded(buildings)),
    );
  }

  Future<void> _onSwitchFloor(SwitchFloor event, Emitter<MapasState> emit) async {
    if (state is BuildingLoaded) {
      final currentState = state as BuildingLoaded;
      final floor = currentState.floors.firstWhere(
        (f) => f.id == event.floorId,
        orElse: () => currentState.currentFloor,
      );
      
      // TODO: Load floor model if not cached
      emit(FloorSwitched(floor: floor));
    }
  }

  void _onClearError(ClearError event, Emitter<MapasState> emit) {
    emit(MapasInitial());
  }
}