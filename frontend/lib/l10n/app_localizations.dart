import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'El Mapita UTB'**
  String get appTitle;

  /// No description provided for @filterByPlace.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por lugar'**
  String get filterByPlace;

  /// No description provided for @allPlaces.
  ///
  /// In es, this message translates to:
  /// **'Todos los lugares'**
  String get allPlaces;

  /// No description provided for @emptyCategoryMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay lugares en esta categoría'**
  String get emptyCategoryMessage;

  /// No description provided for @noticeTitle.
  ///
  /// In es, this message translates to:
  /// **'Aviso importante'**
  String get noticeTitle;

  /// No description provided for @noticeBody.
  ///
  /// In es, this message translates to:
  /// **'Esta aplicación es para uso exclusivo de la comunidad UTB.'**
  String get noticeBody;

  /// No description provided for @noticeAccept.
  ///
  /// In es, this message translates to:
  /// **'Estoy de acuerdo'**
  String get noticeAccept;

  /// No description provided for @languageToggleTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cambiar idioma'**
  String get languageToggleTooltip;

  /// No description provided for @categorySalones.
  ///
  /// In es, this message translates to:
  /// **'Salones'**
  String get categorySalones;

  /// No description provided for @categoryLaboratorios.
  ///
  /// In es, this message translates to:
  /// **'Laboratorios'**
  String get categoryLaboratorios;

  /// No description provided for @categoryBanos.
  ///
  /// In es, this message translates to:
  /// **'Baños'**
  String get categoryBanos;

  /// No description provided for @categoryServiciosEscolares.
  ///
  /// In es, this message translates to:
  /// **'Servicios Escolares'**
  String get categoryServiciosEscolares;

  /// No description provided for @categoryCanchas.
  ///
  /// In es, this message translates to:
  /// **'Canchas Deportivas'**
  String get categoryCanchas;

  /// No description provided for @categoryAuditorios.
  ///
  /// In es, this message translates to:
  /// **'Auditorios'**
  String get categoryAuditorios;

  /// No description provided for @categoryBiblioteca.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get categoryBiblioteca;

  /// No description provided for @categoryCafeteria.
  ///
  /// In es, this message translates to:
  /// **'Cafetería'**
  String get categoryCafeteria;

  /// No description provided for @categoryEstacionamientos.
  ///
  /// In es, this message translates to:
  /// **'Estacionamientos'**
  String get categoryEstacionamientos;

  /// No description provided for @categoryOficinasAdministrativas.
  ///
  /// In es, this message translates to:
  /// **'Oficinas Administrativas'**
  String get categoryOficinasAdministrativas;

  /// No description provided for @categoryBienestarUniversitario.
  ///
  /// In es, this message translates to:
  /// **'Bienestar Universitario'**
  String get categoryBienestarUniversitario;

  /// No description provided for @categoryServicioMedico.
  ///
  /// In es, this message translates to:
  /// **'Servicio Médico'**
  String get categoryServicioMedico;

  /// No description provided for @categoryCentroIdiomas.
  ///
  /// In es, this message translates to:
  /// **'Centro de Idiomas'**
  String get categoryCentroIdiomas;

  /// No description provided for @categorySalasComputo.
  ///
  /// In es, this message translates to:
  /// **'Salas de Cómputo'**
  String get categorySalasComputo;

  /// No description provided for @categorySalaProfesores.
  ///
  /// In es, this message translates to:
  /// **'Sala de Profesores'**
  String get categorySalaProfesores;

  /// No description provided for @categoryPapeleria.
  ///
  /// In es, this message translates to:
  /// **'Papelería y Fotocopiado'**
  String get categoryPapeleria;

  /// No description provided for @categoryAreasVerdes.
  ///
  /// In es, this message translates to:
  /// **'Áreas Verdes y Plazas'**
  String get categoryAreasVerdes;

  /// No description provided for @categoryControlEscolar.
  ///
  /// In es, this message translates to:
  /// **'Control Escolar'**
  String get categoryControlEscolar;

  /// No description provided for @categoryVigilancia.
  ///
  /// In es, this message translates to:
  /// **'Vigilancia y Accesos'**
  String get categoryVigilancia;

  /// No description provided for @categoryCajeroAutomatico.
  ///
  /// In es, this message translates to:
  /// **'Cajero Automático'**
  String get categoryCajeroAutomatico;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
