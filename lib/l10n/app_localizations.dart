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

  /// No description provided for @helloTest.
  ///
  /// In es, this message translates to:
  /// **'Hola, esta es una prueba de i18n'**
  String get helloTest;

  /// No description provided for @identifierLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo o usuario'**
  String get identifierLabel;

  /// No description provided for @identifierHint.
  ///
  /// In es, this message translates to:
  /// **'organizador@planify.com'**
  String get identifierHint;

  /// No description provided for @identifierRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu correo o usuario'**
  String get identifierRequired;

  /// No description provided for @identifierInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido'**
  String get identifierInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In es, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu contraseña'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginButton;

  /// No description provided for @loggingIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciando sesión...'**
  String get loggingIn;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Intenta nuevamente.'**
  String get loginErrorGeneric;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Credenciales inválidas. Verifica tu correo y contraseña.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @logoutButton.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get logoutButton;

  /// No description provided for @welcomeOrganizer.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido, {name}!'**
  String welcomeOrganizer(String name);

  /// No description provided for @welcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido!'**
  String get welcome;

  /// No description provided for @organizerPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de Organizador'**
  String get organizerPanelTitle;

  /// No description provided for @sessionActiveDescription.
  ///
  /// In es, this message translates to:
  /// **'Has iniciado sesión correctamente como organizador de eventos en Planify.'**
  String get sessionActiveDescription;

  /// No description provided for @tokenLabel.
  ///
  /// In es, this message translates to:
  /// **'Token de Sesión'**
  String get tokenLabel;

  /// No description provided for @roleLabel.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get roleLabel;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get emailLabel;

  /// No description provided for @continueAsGuest.
  ///
  /// In es, this message translates to:
  /// **'Continuar como invitado'**
  String get continueAsGuest;

  /// No description provided for @orDivider.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get orDivider;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa a tu cuenta o continúa como invitado'**
  String get loginSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Organizá tus planes, sin vueltas'**
  String get appTagline;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre o apodo'**
  String get nameLabel;

  /// No description provided for @nameRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu nombre'**
  String get nameRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In es, this message translates to:
  /// **'El nombre debe tener al menos 2 caracteres'**
  String get nameMinLength;

  /// No description provided for @pinLabel.
  ///
  /// In es, this message translates to:
  /// **'PIN del evento'**
  String get pinLabel;

  /// No description provided for @pinRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa el PIN del evento'**
  String get pinRequired;

  /// No description provided for @pinMinLength.
  ///
  /// In es, this message translates to:
  /// **'El PIN debe tener al menos 4 caracteres'**
  String get pinMinLength;

  /// No description provided for @joinButton.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get joinButton;

  /// No description provided for @cancelButton.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// No description provided for @loginErrorInvalidPin.
  ///
  /// In es, this message translates to:
  /// **'PIN incorrecto. Verifica el código e intenta nuevamente.'**
  String get loginErrorInvalidPin;

  /// No description provided for @eventIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID del Evento'**
  String get eventIdLabel;

  /// No description provided for @participantPanelTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de Participante'**
  String get participantPanelTitle;

  /// No description provided for @sessionActiveParticipantDescription.
  ///
  /// In es, this message translates to:
  /// **'Has ingresado correctamente como participante del evento.'**
  String get sessionActiveParticipantDescription;

  /// No description provided for @guestRole.
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get guestRole;

  /// No description provided for @organizerRole.
  ///
  /// In es, this message translates to:
  /// **'Organizador'**
  String get organizerRole;

  /// No description provided for @eventLabel.
  ///
  /// In es, this message translates to:
  /// **'Evento'**
  String get eventLabel;

  /// No description provided for @createEventTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear Evento'**
  String get createEventTitle;

  /// No description provided for @createEventButton.
  ///
  /// In es, this message translates to:
  /// **'Crear nuevo evento'**
  String get createEventButton;

  /// No description provided for @step1Badge.
  ///
  /// In es, this message translates to:
  /// **'Paso 1 de 2'**
  String get step1Badge;

  /// No description provided for @step1Title.
  ///
  /// In es, this message translates to:
  /// **'Información básica'**
  String get step1Title;

  /// No description provided for @step1Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el nombre y el lugar de tu evento.'**
  String get step1Subtitle;

  /// No description provided for @eventNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del evento'**
  String get eventNameLabel;

  /// No description provided for @eventNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Cumpleaños de Lucas'**
  String get eventNameHint;

  /// No description provided for @eventNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa el nombre del evento'**
  String get eventNameRequired;

  /// No description provided for @eventLocationLabel.
  ///
  /// In es, this message translates to:
  /// **'Lugar o dirección'**
  String get eventLocationLabel;

  /// No description provided for @eventLocationHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Casa de Lucas o Av. Corrientes 1234'**
  String get eventLocationHint;

  /// No description provided for @eventLocationRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa el lugar del evento'**
  String get eventLocationRequired;

  /// No description provided for @continueButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueButton;

  /// No description provided for @backButton.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get backButton;

  /// No description provided for @step2Badge.
  ///
  /// In es, this message translates to:
  /// **'Paso 2 de 2'**
  String get step2Badge;

  /// No description provided for @step2Title.
  ///
  /// In es, this message translates to:
  /// **'Paso 2: Próximamente'**
  String get step2Title;

  /// No description provided for @step2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'En los próximos pasos podrás configurar fecha, hora, gastos y participantes.'**
  String get step2Subtitle;

  /// No description provided for @draftSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen del borrador'**
  String get draftSummaryTitle;

  /// No description provided for @draftEventName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get draftEventName;

  /// No description provided for @draftEventLocation.
  ///
  /// In es, this message translates to:
  /// **'Lugar'**
  String get draftEventLocation;

  /// No description provided for @generateWithAi.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA'**
  String get generateWithAi;

  /// No description provided for @generateWithAiComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Generación de eventos con IA disponible próximamente'**
  String get generateWithAiComingSoon;

  /// No description provided for @invitationErrorInvalid.
  ///
  /// In es, this message translates to:
  /// **'El enlace de invitación no es válido.'**
  String get invitationErrorInvalid;

  /// No description provided for @invitationErrorNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el evento correspondiente a la invitación.'**
  String get invitationErrorNotFound;

  /// No description provided for @invitationErrorExpired.
  ///
  /// In es, this message translates to:
  /// **'La invitación ha expirado o ya no está disponible.'**
  String get invitationErrorExpired;

  /// No description provided for @invitationErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión al validar la invitación. Verifica tu red.'**
  String get invitationErrorNetwork;

  /// No description provided for @invitationErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo procesar la invitación. Intenta nuevamente.'**
  String get invitationErrorGeneric;

  /// No description provided for @invitationBannerEvent.
  ///
  /// In es, this message translates to:
  /// **'¡Tenés una invitación a un evento!'**
  String get invitationBannerEvent;

  /// No description provided for @resolvingInvitation.
  ///
  /// In es, this message translates to:
  /// **'Cargando invitación...'**
  String get resolvingInvitation;
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
