// lib/features/ubicacion/presentation/pages/location_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/ubicacion_bloc.dart';
import '../../domain/entities.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/theme/app_theme.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  void initState() {
    super.initState();
    context.read<UbicacionBloc>().add(RequestLocationPermission());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ubicación'),
        actions: [
          BlocBuilder<UbicacionBloc, UbicacionState>(
            builder: (context, state) {
              if (state is LocationWatching) {
                return IconButton(
                  icon: const Icon(Icons.location_off),
                  onPressed: () => context.read<UbicacionBloc>().add(StopWatchingLocation()),
                  tooltip: 'Dejar de seguir',
                );
              }
              return IconButton(
                icon: const Icon(Icons.gps_fixed),
                onPressed: () => context.read<UbicacionBloc>().add(GetCurrentLocation()),
                tooltip: 'Obtener ubicación',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<UbicacionBloc, UbicacionState>(
        builder: (context, state) {
          if (state is UbicacionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UbicacionError) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<UbicacionBloc>().add(GetCurrentLocation()),
            );
          }

          if (state is LocationLoaded || state is LocationWatching) {
            final location = state is LocationLoaded ? state.location : state.location;
            return _buildLocationView(location, state is LocationWatching);
          }

          if (state is PermissionRequested) {
            if (state.granted) {
              context.read<UbicacionBloc>().add(GetCurrentLocation());
            }
            return _buildPermissionView(state.granted);
          }

          if (state is ManualLocationSet) {
            return _buildLocationView(state.location, false, isManual: true);
          }

          return _buildInitialView();
        },
      ),
    );
  }

  Widget _buildLocationView(UserLocation location, bool isWatching, {bool isManual = false}) {
    final precision = location.precisionMeters;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map preview placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vista de mapa\n(${location.coordinates.latitude.toStringAsFixed(6)}, ${location.coordinates.longitude.toStringAsFixed(6)})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Precision indicator
          PrecisionIndicator(
            precisionMeters: precision,
            showUncertainty: location.uncertaintyShown,
          ),
          const SizedBox(height: 24),
          
          // Location details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles de ubicación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Latitud', location.coordinates.latitude.toStringAsFixed(6)),
                  _buildDetailRow('Longitud', location.coordinates.longitude.toStringAsFixed(6)),
                  _buildDetailRow('Precisión', '${precision.toStringAsFixed(1)} metros'),
                  if (location.floorEstimate != null)
                    _buildDetailRow('Piso estimado', location.floorEstimate.toString()),
                  _buildDetailRow('Fuente', location.source.name.toUpperCase()),
                  _buildDetailRow(
                    'Actualizado',
                    '${location.timestamp.hour.toString().padLeft(2, '0')}:${location.timestamp.minute.toString().padLeft(2, '0')}:${location.timestamp.second.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Actions
          if (!isWatching)
            ElevatedButton.icon(
              onPressed: () => context.read<UbicacionBloc>().add(WatchLocation()),
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Seguir ubicación en tiempo real'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          
          const SizedBox(height: 12),
          
          OutlinedButton.icon(
            onPressed: _showManualLocationDialog,
            icon: const Icon(Icons.edit_location),
            label: const Text('Establecer ubicación manualmente'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView(bool granted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.location_on : Icons.location_off,
              size: 64,
              color: granted ? AppTheme.secondary : AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              granted ? 'Permiso concedido' : 'Permiso denegado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              granted
                  ? 'Ahora podemos obtener tu ubicación'
                  : 'Necesitas habilitar el permiso de ubicación en la configuración',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (!granted)
              ElevatedButton.icon(
                onPressed: () => context.read<UbicacionBloc>().add(RequestLocationPermission()),
                icon: const Icon(Icons.settings),
                label: const Text('Abrir configuración'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.read<UbicacionBloc>().add(GetCurrentLocation()),
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Obtener ubicación'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tu ubicación',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón para obtener tu ubicación actual',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<UbicacionBloc>().add(GetCurrentLocation()),
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Obtener ubicación'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualLocationDialog() {
    final buildingController = TextEditingController();
    final floorController = TextEditingController();
    final xController = TextEditingController();
    final yController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubicación manual'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: buildingController,
                decoration: const InputDecoration(labelText: 'ID del edificio'),
              ),
              TextField(
                controller: floorController,
                decoration: const InputDecoration(labelText: 'Piso'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: xController,
                decoration: const InputDecoration(labelText: 'Coordenada X'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: yController,
                decoration: const InputDecoration(labelText: 'Coordenada Y'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UbicacionBloc>().add(SetManualLocationEvent(ManualLocationInput(
                buildingId: buildingController.text,
                floor: int.tryParse(floorController.text) ?? 1,
                x: double.tryParse(xController.text) ?? 0,
                y: double.tryParse(yController.text) ?? 0,
              )));
            },
            child: const Text('Establecer'),
          ),
        ],
      ),
    );
  }
}