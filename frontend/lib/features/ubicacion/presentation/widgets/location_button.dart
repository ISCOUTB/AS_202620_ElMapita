// lib/features/ubicacion/presentation/widgets/location_button.dart

import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class LocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      heroTag: 'location_button',
      mini: true,
      child: const Icon(Icons.my_location),
    );
  }
}