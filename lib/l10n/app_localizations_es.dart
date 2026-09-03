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

  @override
  String get createEventTitle => 'Crear Evento';

  @override
  String get createEventButton => 'Crear nuevo evento';

  @override
  String get step1Badge => 'Paso 1 de 2';

  @override
  String get step1Title => 'Información básica';

  @override
  String get step1Subtitle => 'Ingresá el nombre y el lugar de tu evento.';

  @override
  String get eventNameLabel => 'Nombre del evento';

  @override
  String get eventNameHint => 'Ej. Cumpleaños de Lucas';

  @override
  String get eventNameRequired => 'Por favor ingresa el nombre del evento';

  @override
  String get eventLocationLabel => 'Lugar o dirección';

  @override
  String get eventLocationHint => 'Ej. Casa de Lucas o Av. Corrientes 1234';

  @override
  String get eventLocationRequired => 'Por favor ingresa el lugar del evento';

  @override
  String get continueButton => 'Continuar';

  @override
  String get backButton => 'Atrás';

  @override
  String get step2Badge => 'Paso 2 de 2';

  @override
  String get step2Title => 'Grupo y participantes';

  @override
  String get step2Subtitle =>
      'Elegí un grupo existente o creá uno nuevo con sus miembros.';

  @override
  String get existingGroupOption => 'Grupo existente';

  @override
  String get existingGroupSubtitle =>
      'Seleccioná un grupo que ya tengas creado';

  @override
  String get newGroupOption => 'Crear grupo nuevo';

  @override
  String get newGroupSubtitle => 'Armá un grupo nuevo e invitá participantes';

  @override
  String get selectGroupLabel => 'Seleccionar grupo';

  @override
  String get selectGroupHint => 'Elegí un grupo...';

  @override
  String get selectGroupRequired => 'Por favor seleccioná un grupo';

  @override
  String get loadingGroups => 'Cargando grupos...';

  @override
  String get errorLoadingGroups => 'No se pudieron cargar los grupos';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get noGroupsAvailable =>
      'No tenés grupos creados. Podés crear uno nuevo.';

  @override
  String get newGroupNameLabel => 'Nombre del nuevo grupo';

  @override
  String get newGroupNameHint => 'Ej. Amigos del Fútbol';

  @override
  String get newGroupNameRequired => 'Por favor ingresá el nombre del grupo';

  @override
  String get memberIdentifierLabel => 'Miembro (email o usuario)';

  @override
  String get memberIdentifierHint => 'ejemplo@correo.com o @usuario';

  @override
  String get addMemberButton => 'Agregar';

  @override
  String get memberAlreadyAdded => 'Este miembro ya fue agregado';

  @override
  String get memberIdentifierEmpty => 'Ingresá un email o usuario válido';

  @override
  String membersListTitle(int count) {
    return 'Miembros ($count)';
  }

  @override
  String get createEventSubmitButton => 'Crear Evento';

  @override
  String get creatingEventLoading => 'Creando evento...';

  @override
  String get createEventErrorGeneric =>
      'No se pudo crear el evento. Intenta nuevamente.';

  @override
  String get createEventSuccessTitle => '¡Evento creado con éxito!';

  @override
  String get createEventSuccessSubtitle =>
      'Tu evento ya está listo y asignado a su grupo.';

  @override
  String get createdEventIdLabel => 'ID del Evento';

  @override
  String get assignedGroupLabel => 'Grupo asignado';

  @override
  String get backToHomeButton => 'Volver al inicio';

  @override
  String get viewEventDetailButton => 'Ver detalle del evento';

  @override
  String get draftSummaryTitle => 'Resumen del borrador';

  @override
  String get draftEventName => 'Nombre';

  @override
  String get draftEventLocation => 'Lugar';

  @override
  String get generateWithAi => 'Generar con IA';

  @override
  String get generateWithAiComingSoon =>
      'Generación de eventos con IA disponible próximamente';

  @override
  String get eventDetailTitle => 'Detalle del evento';

  @override
  String get eventStatusLabel => 'Estado';

  @override
  String get eventStatusActive => 'Activo';

  @override
  String get eventStatusCancelled => 'Cancelado';

  @override
  String get eventDateFallback => 'Fecha a definir';

  @override
  String get quickActionsTitle => 'Acciones rápidas';

  @override
  String get quickActionInvite => 'Invitar';

  @override
  String get quickActionAddExpense => 'Agregar gasto';

  @override
  String get quickActionAddTask => 'Agregar tarea';

  @override
  String get quickActionSettle => 'Saldar';

  @override
  String get tasksSectionTitle => 'Tareas';

  @override
  String get noTasksPlaceholder => 'No hay tareas asignadas todavía.';

  @override
  String get activityLogSectionTitle => 'Actividad reciente';

  @override
  String get noActivityPlaceholder =>
      'Sin actividad registrada en este evento.';

  @override
  String get featureUnderDevelopment =>
      'Esta funcionalidad estará disponible próximamente.';

  @override
  String get cancelEventAction => 'Cancelar evento';

  @override
  String get cancelEventDialogTitle => '¿Cancelar evento?';

  @override
  String get cancelEventDialogMessage =>
      '¿Estás seguro de que querés cancelar este evento? Esta acción no se puede deshacer.';

  @override
  String get cancelEventConfirm => 'Sí, cancelar evento';

  @override
  String get cancelEventDismiss => 'Volver';

  @override
  String get cancelEventSuccess => 'El evento fue cancelado correctamente.';

  @override
  String get cancelEventError =>
      'No se pudo cancelar el evento. Intenta nuevamente.';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String get eventCancelledNotice =>
      'Este evento ha sido cancelado y ya no acepta nuevas acciones.';

  @override
  String get eventActionsTooltip => 'Opciones del evento';

  @override
  String get cancellingEvent => 'Cancelando evento...';

  @override
  String get invitationErrorInvalid => 'El enlace de invitación no es válido.';

  @override
  String get invitationErrorNotFound =>
      'No se encontró el evento correspondiente a la invitación.';

  @override
  String get invitationErrorExpired =>
      'La invitación ha expirado o ya no está disponible.';

  @override
  String get invitationErrorNetwork =>
      'Error de conexión al validar la invitación. Verifica tu red.';

  @override
  String get invitationErrorGeneric =>
      'No se pudo procesar la invitación. Intenta nuevamente.';

  @override
  String get invitationBannerEvent => '¡Tenés una invitación a un evento!';

  @override
  String get resolvingInvitation => 'Cargando invitación...';
}
