// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'El Mapita UTB';

  @override
  String get filterByPlace => 'Filter by place';

  @override
  String get allPlaces => 'All places';

  @override
  String get emptyCategoryMessage => 'No places in this category';

  @override
  String get noticeTitle => 'Important notice';

  @override
  String get noticeBody =>
      'This application is for the exclusive use of the UTB community.';

  @override
  String get noticeAccept => 'I agree';

  @override
  String get languageToggleTooltip => 'Change language';

  @override
  String get categorySalones => 'Classrooms';

  @override
  String get categoryLaboratorios => 'Laboratories';

  @override
  String get categoryBanos => 'Restrooms';

  @override
  String get categoryServiciosEscolares => 'Student Services';

  @override
  String get categoryCanchas => 'Sports Courts';

  @override
  String get categoryAuditorios => 'Auditoriums';

  @override
  String get categoryBiblioteca => 'Library';

  @override
  String get categoryCafeteria => 'Cafeteria';

  @override
  String get categoryEstacionamientos => 'Parking Lots';

  @override
  String get categoryOficinasAdministrativas => 'Administrative Offices';

  @override
  String get categoryBienestarUniversitario => 'Student Wellness';

  @override
  String get categoryServicioMedico => 'Medical Service';

  @override
  String get categoryCentroIdiomas => 'Language Center';

  @override
  String get categorySalasComputo => 'Computer Labs';

  @override
  String get categorySalaProfesores => 'Faculty Lounge';

  @override
  String get categoryPapeleria => 'Stationery & Copy Center';

  @override
  String get categoryAreasVerdes => 'Green Areas & Plazas';

  @override
  String get categoryControlEscolar => 'Registrar\'s Office';

  @override
  String get categoryVigilancia => 'Security & Access';

  @override
  String get categoryCajeroAutomatico => 'ATM';

  @override
  String get navMap3d => '3D Map';

  @override
  String get navPlaces => 'Places';

  @override
  String get model3dTitle => 'Campus 3D model';

  @override
  String get model3dAlt => 'UTB campus 3D model';

  @override
  String get modelLoadError => 'Could not load the 3D model.';

  @override
  String get retry => 'Retry';

  @override
  String get goTo => 'Go to…';

  @override
  String get pickDestination => 'Where do you want to go?';

  @override
  String get pickDestinationFiltered =>
      'Where do you want to go? (filtered categories)';

  @override
  String get noBuildingsInFilter =>
      'There are no buildings in the current filter';

  @override
  String destinationChip(String name) {
    return 'Destination: $name';
  }

  @override
  String get guideOnTooltip => 'Arrival guide: on (tap to turn off)';

  @override
  String get guideOffTooltip => 'Arrival guide: off (tap to turn on)';

  @override
  String get guideOnMessage => 'Arrival guide on';

  @override
  String get guideOffMessage => 'Arrival guide off';

  @override
  String guideHeading(String name, int meters) {
    return 'Heading to $name · $meters m';
  }

  @override
  String guideNear(String name, int meters) {
    return 'Near $name · $meters m';
  }

  @override
  String guideArrived(String name) {
    return 'You have arrived at $name!';
  }

  @override
  String get statusOutside => 'Position far from the area';

  @override
  String get statusDenied =>
      'Enable location permission to see yourself on the map';

  @override
  String get statusUnavailable => 'Could not get your location';

  @override
  String categoriesCount(int count) {
    return '$count categories';
  }
}
