// lib/features/mapas/presentation/pages/map_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/mapas_bloc.dart';
import '../../domain/entities.dart';
import '../widgets/floor_selector.dart';
import '../widgets/poi_marker.dart';
import '../../../features/ubicacion/presentation/widgets/location_button.dart';
import '../../../shared/widgets/common_widgets.dart';

class MapPage extends StatefulWidget {
  final String buildingId;

  const MapPage({super.key, required this.buildingId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  BuildingId? _buildingId;
  int _currentFloorIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildingId = BuildingId(widget.buildingId);
    context.read<MapasBloc>().add(LoadBuilding(_buildingId!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<MapasBloc, MapasState>(
          builder: (context, state) {
            if (state is BuildingLoaded) {
              return Text(state.building.nombre);
            }
            return const Text('Mapa 3D');
          },
        ),
        actions: [
          BlocBuilder<MapasBloc, MapasState>(
            builder: (context, state) {
              if (state is BuildingLoaded && state.floors.length > 1) {
                return FloorSelector(
                  floors: state.floors,
                  currentIndex: _currentFloorIndex,
                  onFloorChanged: (index) {
                    setState(() => _currentFloorIndex = index);
                    // TODO: Load floor model
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<MapasBloc, MapasState>(
        builder: (context, state) {
          if (state is MapasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MapasError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<MapasBloc>().add(LoadBuilding(_buildingId!)),
            );
          }

          if (state is BuildingLoaded) {
            final floor = _currentFloorIndex < state.floors.length
                ? state.floors[_currentFloorIndex]
                : state.floors.first;

            return Stack(
              children: [
                // 3D Map View (Placeholder)
                _buildMapView(state, floor),
                
                // POI Markers Overlay
                ..._buildPoiMarkers(state, floor),
                
                // Location Button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: LocationButton(
                    onPressed: () => context.go('/location'),
                  ),
                ),
                
                // Model Load Error
                if (state.modelError != null)
                  Positioned(
                    bottom: 170,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: AppTheme.warning.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppTheme.warning),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No se pudo cargar el modelo 3D: ${state.modelError}',
                                style: TextStyle(color: AppTheme.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: Text('Cargando mapa...'));
        },
      ),
    );
  }

  Widget _buildMapView(BuildingLoaded state, Floor floor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade100,
      child: state.modelPath != null
          ? _buildModelViewer(state.modelPath!)
          : _buildPlaceholderMap(floor),
    );
  }

  Widget _buildModelViewer(String modelPath) {
    // TODO: Integrate with flame/three.dart for actual 3D rendering
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.model_training,
            size: 64,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Modelo 3D cargado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ruta: $modelPath',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderMap(Floor floor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Mapa 3D - ${floor.nombre}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Modelo 3D: ${floor.modelo3DVersion.value}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Trigger model download
              context.read<MapasBloc>().add(LoadBuilding(_buildingId!));
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar modelo'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPoiMarkers(BuildingLoaded state, Floor floor) {
    // In a real implementation, this would project 3D coordinates to 2D screen positions
    // For now, return empty list
    return [];
  }
}