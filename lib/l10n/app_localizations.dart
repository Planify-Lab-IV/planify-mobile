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
  /// **'Grupo y participantes'**
  String get step2Title;

  /// No description provided for @step2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí un grupo existente o creá uno nuevo con sus miembros.'**
  String get step2Subtitle;

  /// No description provided for @existingGroupOption.
  ///
  /// In es, this message translates to:
  /// **'Grupo existente'**
  String get existingGroupOption;

  /// No description provided for @existingGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná un grupo que ya tengas creado'**
  String get existingGroupSubtitle;

  /// No description provided for @newGroupOption.
  ///
  /// In es, this message translates to:
  /// **'Crear grupo nuevo'**
  String get newGroupOption;

  /// No description provided for @newGroupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Armá un grupo nuevo e invitá participantes'**
  String get newGroupSubtitle;

  /// No description provided for @selectGroupLabel.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar grupo'**
  String get selectGroupLabel;

  /// No description provided for @selectGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Elegí un grupo...'**
  String get selectGroupHint;

  /// No description provided for @selectGroupRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor seleccioná un grupo'**
  String get selectGroupRequired;

  /// No description provided for @loadingGroups.
  ///
  /// In es, this message translates to:
  /// **'Cargando grupos...'**
  String get loadingGroups;

  /// No description provided for @errorLoadingGroups.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los grupos'**
  String get errorLoadingGroups;

  /// No description provided for @retryButton.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retryButton;

  /// No description provided for @noGroupsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No tenés grupos creados. Podés crear uno nuevo.'**
  String get noGroupsAvailable;

  /// No description provided for @newGroupNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del nuevo grupo'**
  String get newGroupNameLabel;

  /// No description provided for @newGroupNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Amigos del Fútbol'**
  String get newGroupNameHint;

  /// No description provided for @newGroupNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresá el nombre del grupo'**
  String get newGroupNameRequired;

  /// No description provided for @memberIdentifierLabel.
  ///
  /// In es, this message translates to:
  /// **'Miembro (email o usuario)'**
  String get memberIdentifierLabel;

  /// No description provided for @memberIdentifierHint.
  ///
  /// In es, this message translates to:
  /// **'ejemplo@correo.com o @usuario'**
  String get memberIdentifierHint;

  /// No description provided for @addMemberButton.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get addMemberButton;

  /// No description provided for @memberAlreadyAdded.
  ///
  /// In es, this message translates to:
  /// **'Este miembro ya fue agregado'**
  String get memberAlreadyAdded;

  /// No description provided for @memberIdentifierEmpty.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un email o usuario válido'**
  String get memberIdentifierEmpty;

  /// No description provided for @membersListTitle.
  ///
  /// In es, this message translates to:
  /// **'Miembros ({count})'**
  String membersListTitle(int count);

  /// No description provided for @createEventSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Evento'**
  String get createEventSubmitButton;

  /// No description provided for @creatingEventLoading.
  ///
  /// In es, this message translates to:
  /// **'Creando evento...'**
  String get creatingEventLoading;

  /// No description provided for @createEventErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el evento. Intenta nuevamente.'**
  String get createEventErrorGeneric;

  /// No description provided for @createEventSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Evento creado con éxito!'**
  String get createEventSuccessTitle;

  /// No description provided for @createEventSuccessSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu evento ya está listo y asignado a su grupo.'**
  String get createEventSuccessSubtitle;

  /// No description provided for @createdEventIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID del Evento'**
  String get createdEventIdLabel;

  /// No description provided for @assignedGroupLabel.
  ///
  /// In es, this message translates to:
  /// **'Grupo asignado'**
  String get assignedGroupLabel;

  /// No description provided for @backToHomeButton.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get backToHomeButton;

  /// No description provided for @viewEventDetailButton.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle del evento'**
  String get viewEventDetailButton;

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

  /// No description provided for @eventDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del evento'**
  String get eventDetailTitle;

  /// No description provided for @eventStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get eventStatusLabel;

  /// No description provided for @eventStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get eventStatusActive;

  /// No description provided for @eventStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get eventStatusCancelled;

  /// No description provided for @eventDateFallback.
  ///
  /// In es, this message translates to:
  /// **'Fecha a definir'**
  String get eventDateFallback;

  /// No description provided for @quickActionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get quickActionsTitle;

  /// No description provided for @quickActionInvite.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get quickActionInvite;

  /// No description provided for @quickActionAddExpense.
  ///
  /// In es, this message translates to:
  /// **'Agregar gasto'**
  String get quickActionAddExpense;

  /// No description provided for @quickActionAddTask.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarea'**
  String get quickActionAddTask;

  /// No description provided for @quickActionSettle.
  ///
  /// In es, this message translates to:
  /// **'Saldar'**
  String get quickActionSettle;

  /// No description provided for @tasksSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get tasksSectionTitle;

  /// No description provided for @noTasksPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'No hay tareas asignadas todavía.'**
  String get noTasksPlaceholder;

  /// No description provided for @activityLogSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get activityLogSectionTitle;

  /// No description provided for @noActivityPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad registrada en este evento.'**
  String get noActivityPlaceholder;

  /// No description provided for @featureUnderDevelopment.
  ///
  /// In es, this message translates to:
  /// **'Esta funcionalidad estará disponible próximamente.'**
  String get featureUnderDevelopment;

  /// No description provided for @cancelEventAction.
  ///
  /// In es, this message translates to:
  /// **'Cancelar evento'**
  String get cancelEventAction;

  /// No description provided for @cancelEventDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar evento?'**
  String get cancelEventDialogTitle;

  /// No description provided for @cancelEventDialogMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que querés cancelar este evento? Esta acción no se puede deshacer.'**
  String get cancelEventDialogMessage;

  /// No description provided for @cancelEventConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar evento'**
  String get cancelEventConfirm;

  /// No description provided for @cancelEventDismiss.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get cancelEventDismiss;

  /// No description provided for @cancelEventSuccess.
  ///
  /// In es, this message translates to:
  /// **'El evento fue cancelado correctamente.'**
  String get cancelEventSuccess;

  /// No description provided for @cancelEventError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar el evento. Intenta nuevamente.'**
  String get cancelEventError;

  /// No description provided for @eventNotFound.
  ///
  /// In es, this message translates to:
  /// **'Evento no encontrado'**
  String get eventNotFound;

  /// No description provided for @eventCancelledNotice.
  ///
  /// In es, this message translates to:
  /// **'Este evento ha sido cancelado y ya no acepta nuevas acciones.'**
  String get eventCancelledNotice;

  /// No description provided for @eventActionsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Opciones del evento'**
  String get eventActionsTooltip;

  /// No description provided for @cancellingEvent.
  ///
  /// In es, this message translates to:
  /// **'Cancelando evento...'**
  String get cancellingEvent;

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

  /// No description provided for @attendanceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Vas a asistir?'**
  String get attendanceTitle;

  /// No description provided for @attendanceGoing.
  ///
  /// In es, this message translates to:
  /// **'Voy'**
  String get attendanceGoing;

  /// No description provided for @attendanceNotGoing.
  ///
  /// In es, this message translates to:
  /// **'No voy'**
  String get attendanceNotGoing;

  /// No description provided for @attendanceConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get attendanceConfirmed;

  /// No description provided for @attendanceRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get attendanceRejected;

  /// No description provided for @attendancePending.
  ///
  /// In es, this message translates to:
  /// **'Sin respuesta'**
  String get attendancePending;

  /// No description provided for @attendanceUpdateError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar tu asistencia. Intenta nuevamente.'**
  String get attendanceUpdateError;
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
