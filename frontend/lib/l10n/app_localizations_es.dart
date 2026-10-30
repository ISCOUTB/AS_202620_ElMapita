// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'El Mapita UTB';

  @override
  String get filterByPlace => 'Filtrar por lugar';

  @override
  String get allPlaces => 'Todos los lugares';

  @override
  String get emptyCategoryMessage => 'No hay lugares en esta categoría';

  @override
  String get noticeTitle => 'Aviso importante';

  @override
  String get noticeBody =>
      'Esta aplicación es para uso exclusivo de la comunidad UTB.';

  @override
  String get noticeAccept => 'Estoy de acuerdo';

  @override
  String get languageToggleTooltip => 'Cambiar idioma';

  @override
  String get categorySalones => 'Salones';

  @override
  String get categoryLaboratorios => 'Laboratorios';

  @override
  String get categoryBanos => 'Baños';

  @override
  String get categoryServiciosEscolares => 'Servicios Escolares';

  @override
  String get categoryCanchas => 'Canchas Deportivas';

  @override
  String get categoryAuditorios => 'Auditorios';

  @override
  String get categoryBiblioteca => 'Biblioteca';

  @override
  String get categoryCafeteria => 'Cafetería';

  @override
  String get categoryEstacionamientos => 'Estacionamientos';

  @override
  String get categoryOficinasAdministrativas => 'Oficinas Administrativas';

  @override
  String get categoryBienestarUniversitario => 'Bienestar Universitario';

  @override
  String get categoryServicioMedico => 'Servicio Médico';

  @override
  String get categoryCentroIdiomas => 'Centro de Idiomas';

  @override
  String get categorySalasComputo => 'Salas de Cómputo';

  @override
  String get categorySalaProfesores => 'Sala de Profesores';

  @override
  String get categoryPapeleria => 'Papelería y Fotocopiado';

  @override
  String get categoryAreasVerdes => 'Áreas Verdes y Plazas';

  @override
  String get categoryControlEscolar => 'Control Escolar';

  @override
  String get categoryVigilancia => 'Vigilancia y Accesos';

  @override
  String get categoryCajeroAutomatico => 'Cajero Automático';

  @override
  String get navMap3d => 'Mapa 3D';

  @override
  String get navPlaces => 'Lugares';

  @override
  String get model3dTitle => 'Modelo 3D del campus';

  @override
  String get model3dAlt => 'Modelo 3D del campus UTB';

  @override
  String get modelLoadError => 'No se pudo cargar el modelo 3D.';

  @override
  String get retry => 'Reintentar';

  @override
  String get goTo => 'Ir a…';

  @override
  String get pickDestination => '¿A dónde quieres ir?';

  @override
  String get pickDestinationFiltered =>
      '¿A dónde quieres ir? (categorías filtradas)';

  @override
  String get noBuildingsInFilter => 'No hay edificios en el filtro actual';

  @override
  String destinationChip(String name) {
    return 'Destino: $name';
  }

  @override
  String get guideOnTooltip =>
      'Guía de llegada: activada (tocar para desactivar)';

  @override
  String get guideOffTooltip =>
      'Guía de llegada: desactivada (tocar para activar)';

  @override
  String get guideOnMessage => 'Guía de llegada activada';

  @override
  String get guideOffMessage => 'Guía de llegada desactivada';

  @override
  String guideHeading(String name, int meters) {
    return 'Rumbo a $name · $meters m';
  }

  @override
  String guideNear(String name, int meters) {
    return 'Cerca de $name · $meters m';
  }

  @override
  String guideArrived(String name) {
    return '¡Llegaste a $name!';
  }

  @override
  String get statusOutside => 'Posición lejana de la zona';

  @override
  String get statusDenied =>
      'Activa el permiso de ubicación para verte en el mapa';

  @override
  String get statusUnavailable => 'No se pudo obtener tu ubicación';

  @override
  String categoriesCount(int count) {
    return '$count categorías';
  }
}
