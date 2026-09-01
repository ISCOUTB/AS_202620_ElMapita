// lib/features/mapas/presentation/widgets/poi_marker.dart

import 'package:flutter/material.dart';
import '../../domain/entities.dart';
import '../../../../shared/theme/app_theme.dart';

class PoiMarker extends StatelessWidget {
  final Poi poi;
  final Offset position;
  final VoidCallback? onTap;

  const PoiMarker({
    super.key,
    required this.poi,
    required this.position,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 20,
      top: position.dy - 40,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPoiColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getPoiIcon(),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                poi.nombre,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPoiColor() {
    switch (poi.tipo) {
      case PoiType.salon:
        return AppTheme.primary;
      case PoiType.laboratorio:
        return AppTheme.secondary;
      case PoiType.bano:
        return Colors.blue;
      case PoiType.cafeteria:
        return Colors.orange;
      case PoiType.biblioteca:
        return Colors.purple;
      case PoiType.escalera:
        return Colors.grey;
      case PoiType.ascensor:
        return Colors.teal;
      case PoiType.otro:
        return Colors.grey;
    }
  }

  IconData _getPoiIcon() {
    switch (poi.tipo) {
      case PoiType.salon:
        return Icons.meeting_room;
      case PoiType.laboratorio:
        return Icons.science;
      case PoiType.bano:
        return Icons.wc;
      case PoiType.cafeteria:
        return Icons.restaurant;
      case PoiType.biblioteca:
        return Icons.library_books;
      case PoiType.escalera:
        return Icons.stairs;
      case PoiType.ascensor:
        return Icons.elevator;
      case PoiType.otro:
        return Icons.place;
    }
  }
}