// lib/features/campus/presentation/category_labels.dart

import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities.dart';

String categoryLabel(BuildContext context, PlaceCategory category) {
  final l10n = AppLocalizations.of(context)!;
  switch (category) {
    case PlaceCategory.salones:
      return l10n.categorySalones;
    case PlaceCategory.laboratorios:
      return l10n.categoryLaboratorios;
    case PlaceCategory.banos:
      return l10n.categoryBanos;
    case PlaceCategory.serviciosEscolares:
      return l10n.categoryServiciosEscolares;
    case PlaceCategory.canchas:
      return l10n.categoryCanchas;
    case PlaceCategory.auditorios:
      return l10n.categoryAuditorios;
    case PlaceCategory.biblioteca:
      return l10n.categoryBiblioteca;
    case PlaceCategory.cafeteria:
      return l10n.categoryCafeteria;
    case PlaceCategory.estacionamientos:
      return l10n.categoryEstacionamientos;
    case PlaceCategory.oficinasAdministrativas:
      return l10n.categoryOficinasAdministrativas;
    case PlaceCategory.bienestarUniversitario:
      return l10n.categoryBienestarUniversitario;
    case PlaceCategory.servicioMedico:
      return l10n.categoryServicioMedico;
    case PlaceCategory.centroIdiomas:
      return l10n.categoryCentroIdiomas;
    case PlaceCategory.salasComputo:
      return l10n.categorySalasComputo;
    case PlaceCategory.salaProfesores:
      return l10n.categorySalaProfesores;
    case PlaceCategory.papeleria:
      return l10n.categoryPapeleria;
    case PlaceCategory.areasVerdes:
      return l10n.categoryAreasVerdes;
    case PlaceCategory.controlEscolar:
      return l10n.categoryControlEscolar;
    case PlaceCategory.vigilancia:
      return l10n.categoryVigilancia;
    case PlaceCategory.cajeroAutomatico:
      return l10n.categoryCajeroAutomatico;
  }
}
