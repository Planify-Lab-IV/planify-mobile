// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get helloTest => 'Hola, esta es una prueba de i18n';

  @override
  String get identifierLabel => 'Correo o usuario';

  @override
  String get identifierHint => 'organizador@planify.com';

  @override
  String get identifierRequired => 'Por favor ingresa tu correo o usuario';

  @override
  String get identifierInvalid => 'Ingresa un correo electrónico válido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Por favor ingresa tu contraseña';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get loggingIn => 'Iniciando sesión...';

  @override
  String get loginErrorGeneric =>
      'No se pudo iniciar sesión. Intenta nuevamente.';

  @override
  String get loginErrorInvalidCredentials =>
      'Credenciales inválidas. Verifica tu correo y contraseña.';

  @override
  String get logoutButton => 'Cerrar Sesión';

  @override
  String welcomeOrganizer(String name) {
    return '¡Bienvenido, $name!';
  }

  @override
  String get welcome => '¡Bienvenido!';

  @override
  String get organizerPanelTitle => 'Panel de Organizador';

  @override
  String get sessionActiveDescription =>
      'Has iniciado sesión correctamente como organizador de eventos en Planify.';

  @override
  String get tokenLabel => 'Token de Sesión';

  @override
  String get roleLabel => 'Rol';

  @override
  String get emailLabel => 'Correo';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get orDivider => 'o';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginSubtitle => 'Ingresa a tu cuenta o continúa como invitado';

  @override
  String get appTagline => 'Organizá tus planes, sin vueltas';

  @override
  String get nameLabel => 'Nombre o apodo';

  @override
  String get nameRequired => 'Por favor ingresa tu nombre';

  @override
  String get nameMinLength => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get pinLabel => 'PIN del evento';

  @override
  String get pinRequired => 'Por favor ingresa el PIN del evento';

  @override
  String get pinMinLength => 'El PIN debe tener al menos 4 caracteres';

  @override
  String get joinButton => 'Ingresar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get loginErrorInvalidPin =>
      'PIN incorrecto. Verifica el código e intenta nuevamente.';

  @override
  String get eventIdLabel => 'ID del Evento';

  @override
  String get participantPanelTitle => 'Panel de Participante';

  @override
  String get sessionActiveParticipantDescription =>
      'Has ingresado correctamente como participante del evento.';

  @override
  String get guestRole => 'Invitado';

  @override
  String get organizerRole => 'Organizador';

  @override
  String get eventLabel => 'Evento';
}
