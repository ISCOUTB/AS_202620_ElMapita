// lib/features/mapas/presentation/widgets/floor_selector.dart

import 'package:flutter/material.dart';
import '../../domain/entities.dart';
import '../../../../shared/theme/app_theme.dart';

class FloorSelector extends StatelessWidget {
  final List<Floor> floors;
  final int currentIndex;
  final ValueChanged<int> onFloorChanged;

  const FloorSelector({
    super.key,
    required this.floors,
    required this.currentIndex,
    required this.onFloorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      initialValue: currentIndex,
      onSelected: onFloorChanged,
      itemBuilder: (context) => floors.asMap().entries.map((entry) {
        final index = entry.key;
        final floor = entry.value;
        return PopupMenuItem<int>(
          value: index,
          child: Row(
            children: [
              if (index == currentIndex)
                Icon(Icons.check, size: 18, color: AppTheme.primary),
              if (index == currentIndex) const SizedBox(width: 8),
              Text(floor.nombre),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers, size: 18, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              floors[currentIndex].nombre,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}