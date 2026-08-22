// lib/features/mapas/presentation/pages/building_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/mapas_bloc.dart';
import '../../domain/entities.dart';
import '../widgets/building_card.dart';
import '../../../shared/widgets/common_widgets.dart';

class BuildingListPage extends StatefulWidget {
  const BuildingListPage({super.key});

  @override
  State<BuildingListPage> createState() => _BuildingListPageState();
}

class _BuildingListPageState extends State<BuildingListPage> {
  @override
  void initState() {
    super.initState();
    context.read<MapasBloc>().add(LoadAllBuildings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edificios del Campus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MapasBloc>().add(LoadAllBuildings()),
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
              onRetry: () => context.read<MapasBloc>().add(LoadAllBuildings()),
            );
          }
          
          if (state is BuildingsLoaded) {
            if (state.buildings.isEmpty) {
              return const EmptyStateView(
                icon: Icons.location_city,
                title: 'No hay edificios',
                message: 'No se encontraron edificios en el campus',
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.buildings.length,
              itemBuilder: (context, index) {
                final building = state.buildings[index];
                return BuildingCard(
                  building: building,
                  onTap: () => context.go('/map/building/${building.id.value}'),
                );
              },
            );
          }
          
          return const Center(child: Text('Cargando...'));
        },
      ),
    );
  }
}