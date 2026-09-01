// lib/features/campus/domain/entities.dart

import 'package:flutter/material.dart';

/// Categorías de lugares que puede tener un campus universitario.
enum PlaceCategory {
  salones,
  laboratorios,
  banos,
  serviciosEscolares,
  canchas,
  auditorios,
  biblioteca,
  cafeteria,
  estacionamientos,
  oficinasAdministrativas,
  bienestarUniversitario,
  servicioMedico,
  centroIdiomas,
  salasComputo,
  salaProfesores,
  papeleria,
  areasVerdes,
  controlEscolar,
  vigilancia,
  cajeroAutomatico,
}

extension PlaceCategoryX on PlaceCategory {
  IconData get icon {
    switch (this) {
      case PlaceCategory.salones:
        return Icons.meeting_room_outlined;
      case PlaceCategory.laboratorios:
        return Icons.science_outlined;
      case PlaceCategory.banos:
        return Icons.wc_outlined;
      case PlaceCategory.serviciosEscolares:
        return Icons.assignment_outlined;
      case PlaceCategory.canchas:
        return Icons.sports_soccer_outlined;
      case PlaceCategory.auditorios:
        return Icons.theater_comedy_outlined;
      case PlaceCategory.biblioteca:
        return Icons.local_library_outlined;
      case PlaceCategory.cafeteria:
        return Icons.restaurant_outlined;
      case PlaceCategory.estacionamientos:
        return Icons.local_parking_outlined;
      case PlaceCategory.oficinasAdministrativas:
        return Icons.badge_outlined;
      case PlaceCategory.bienestarUniversitario:
        return Icons.groups_outlined;
      case PlaceCategory.servicioMedico:
        return Icons.medical_services_outlined;
      case PlaceCategory.centroIdiomas:
        return Icons.translate_outlined;
      case PlaceCategory.salasComputo:
        return Icons.computer_outlined;
      case PlaceCategory.salaProfesores:
        return Icons.school_outlined;
      case PlaceCategory.papeleria:
        return Icons.print_outlined;
      case PlaceCategory.areasVerdes:
        return Icons.park_outlined;
      case PlaceCategory.controlEscolar:
        return Icons.fact_check_outlined;
      case PlaceCategory.vigilancia:
        return Icons.security_outlined;
      case PlaceCategory.cajeroAutomatico:
        return Icons.atm_outlined;
    }
  }
}

class CampusPlace {
  final String name;
  final PlaceCategory category;
  final String location;

  const CampusPlace({
    required this.name,
    required this.category,
    required this.location,
  });
}
