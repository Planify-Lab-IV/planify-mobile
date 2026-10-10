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
  String get registrationTitle => 'Crear cuenta';

  @override
  String get registrationCreateAccountLink => '¿No tenés cuenta? Crear cuenta';

  @override
  String get registrationNameLabel => 'Nombre';

  @override
  String get registrationUsernameLabel => 'Usuario';

  @override
  String get registrationUsernameHelp => 'Usá minúsculas, números y _';

  @override
  String get registrationEmailLabel => 'Correo electrónico';

  @override
  String get registrationNameInvalid =>
      'El nombre debe tener entre 1 y 80 caracteres';

  @override
  String get registrationUsernameInvalid =>
      'El usuario debe tener entre 3 y 30 caracteres y usar solo minúsculas, números o _';

  @override
  String get registrationEmailInvalid => 'Ingresá un correo electrónico válido';

  @override
  String get registrationPasswordInvalid =>
      'La contraseña debe tener entre 8 y 72 caracteres';

  @override
  String get registrationSubmitButton => 'Registrarme';

  @override
  String get registrationErrorConflict =>
      'No pudimos crear la cuenta con esos datos. Si ya tenés una cuenta, iniciá sesión.';

  @override
  String get registrationErrorInvalidData =>
      'Revisá los datos ingresados e intentá nuevamente.';

  @override
  String get registrationErrorNetwork =>
      'No pudimos crear la cuenta por un problema de conexión. Intentá nuevamente.';

  @override
  String get registrationErrorGeneric =>
      'No pudimos crear la cuenta. Intentá nuevamente.';

  @override
  String get registrationBackToLogin => '¿Ya tenés cuenta? Iniciá sesión';

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
  String get nameMaxLength => 'El nombre no puede superar los 80 caracteres';

  @override
  String get pinLabel =>
      'Elegí un PIN de 4 dígitos para identificarte en este evento.';

  @override
  String get pinRecoveryTitle =>
      '¿Ya ingresaste a este evento con este nombre?';

  @override
  String get pinRecoveryMessage => 'Usá el mismo PIN para recuperar tu acceso.';

  @override
  String get pinRequired => 'Por favor ingresá tu PIN de acceso';

  @override
  String get pinMinLength => 'El PIN debe tener al menos 4 caracteres';

  @override
  String get pinInvalidFormat => 'El PIN debe tener exactamente 4 dígitos';

  @override
  String get joinButton => 'Ingresar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get loginErrorInvalidPin =>
      'PIN incorrecto. Verifica el código e intenta nuevamente.';

  @override
  String get loginErrorEventNotFound =>
      'El evento ya no existe o no está disponible.';

  @override
  String get loginErrorEventUnavailable => 'El evento no está disponible.';

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
  String get eventStatusActive => 'En planificación';

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
  String get activityLoading => 'Cargando actividad del evento...';

  @override
  String get activityLoadError =>
      'No se pudo cargar la actividad del evento. Intentá nuevamente.';

  @override
  String activityTaskCreated(String actor, String title) {
    return '$actor creó la tarea $title';
  }

  @override
  String activityAvailabilityUpdated(String actor) {
    return '$actor actualizó su disponibilidad';
  }

  @override
  String activityExpenseCreated(
    String actor,
    String description,
    String amount,
  ) {
    return '$actor agregó el gasto $description por $amount';
  }

  @override
  String activityScheduleConfirmed(String actor, String dateTime) {
    return '$actor confirmó el horario para $dateTime';
  }

  @override
  String activityUnknown(String actor) {
    return '$actor hizo un cambio en el evento';
  }

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
  String get closeExpensesAction => 'Cerrar gastos';

  @override
  String get closeExpensesDialogTitle => '¿Cerrar gastos?';

  @override
  String get closeExpensesDialogMessage =>
      'Ya no se podrán cargar gastos nuevos en este evento, pero se podrá seguir saldando.';

  @override
  String get closeExpensesConfirm => 'Sí, cerrar gastos';

  @override
  String get closeExpensesDismiss => 'Volver';

  @override
  String get closeExpensesSuccess => 'Los gastos se cerraron correctamente.';

  @override
  String get closeExpensesError =>
      'No se pudieron cerrar los gastos. Intentá nuevamente.';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String get eventLoadError =>
      'No se pudo cargar el evento. Verificá tu conexión e intentá nuevamente.';

  @override
  String get eventCancelledNotice =>
      'Este evento ha sido cancelado y ya no acepta nuevas acciones.';

  @override
  String get expensesClosedNotice =>
      'Los gastos están cerrados. Ya no se pueden cargar gastos nuevos.';

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

  @override
  String get attendanceTitle => '¿Vas a asistir?';

  @override
  String get attendanceGoing => 'Voy';

  @override
  String get attendanceNotGoing => 'No voy';

  @override
  String get attendanceConfirmed => 'Confirmado';

  @override
  String get attendanceRejected => 'Rechazado';

  @override
  String get attendancePending => 'Sin respuesta';

  @override
  String get attendanceUpdateError =>
      'No se pudo actualizar tu asistencia. Intenta nuevamente.';

  @override
  String get eventConfigTitle => 'Configuración del evento';

  @override
  String get eventConfigAction => 'Configurar participación';

  @override
  String get availabilityTitle => 'Disponibilidad semanal';

  @override
  String get availabilitySubtitle =>
      'Marcá los horarios en los que estás disponible.';

  @override
  String get availabilitySave => 'Guardar disponibilidad';

  @override
  String get availabilityLoadError => 'No se pudo cargar tu disponibilidad.';

  @override
  String get availabilitySaveSuccess => 'Tu disponibilidad fue guardada.';

  @override
  String get availabilitySaveError =>
      'No se pudo guardar tu disponibilidad. Intenta nuevamente.';

  @override
  String get availabilityHeatmapTitle => 'Disponibilidad combinada';

  @override
  String get availabilityHeatmapSubtitle =>
      'Consultá cuántas personas están disponibles en cada horario.';

  @override
  String get availabilityHeatmapLoadError =>
      'No se pudo cargar la disponibilidad combinada.';

  @override
  String availabilityHeatmapAvailableCount(int count) {
    return '$count disponibles';
  }

  @override
  String get availabilityMondayShort => 'L';

  @override
  String get availabilityTuesdayShort => 'M';

  @override
  String get availabilityWednesdayShort => 'X';

  @override
  String get availabilityThursdayShort => 'J';

  @override
  String get availabilityFridayShort => 'V';

  @override
  String get availabilitySaturdayShort => 'S';

  @override
  String get availabilitySundayShort => 'D';

  @override
  String get loadingEvent => 'Cargando evento...';

  @override
  String get scheduleConfirmationTitle => 'Confirmar horario';

  @override
  String get scheduleConfirmationSubtitle =>
      'Elegí la fecha y la hora de inicio del evento.';

  @override
  String get scheduleSelectDate => 'Elegir fecha';

  @override
  String get scheduleSelectTime => 'Elegir hora';

  @override
  String get scheduleConfirm => 'Confirmar horario';

  @override
  String get scheduleConfirmationValidationError =>
      'Elegí una fecha y hora futuras para confirmar el evento.';

  @override
  String get scheduleConfirmationAuthorizationError =>
      'Solo el organizador puede confirmar el horario.';

  @override
  String get scheduleConfirmationNotFoundError => 'No se encontró el evento.';

  @override
  String get scheduleConfirmationNetworkError =>
      'No se pudo confirmar el horario por un problema de conexión.';

  @override
  String get scheduleConfirmationGenericError =>
      'No se pudo confirmar el horario. Intentá nuevamente.';

  @override
  String get scheduleConfirmationSuccess =>
      'El horario del evento fue confirmado.';

  @override
  String get addExpenseDescriptionLabel => 'Descripción del gasto';

  @override
  String get addExpenseDescriptionHint => 'Ej. Cena de fin de año';

  @override
  String get addExpenseDescriptionRequired =>
      'Ingresá una descripción para el gasto.';

  @override
  String get addExpenseTotalLabel => 'Total del gasto';

  @override
  String get addExpenseTotalHint => 'Ej. 2.500,00';

  @override
  String get addExpenseTotalRequired => 'Ingresá el total del gasto.';

  @override
  String get addExpenseTotalInvalid => 'Ingresá un total válido mayor a cero.';

  @override
  String get addExpensePayersTitle => '¿Quiénes pagaron?';

  @override
  String get addExpensePayersSubtitle =>
      'Seleccioná una o más personas que hicieron el pago.';

  @override
  String get addExpenseDialogTitle => 'Agregar gasto';

  @override
  String get addExpenseCloseTooltip => 'Cerrar';

  @override
  String get addExpensePayerAmountsTitle => 'Montos pagados';

  @override
  String addExpensePayerAmountLabel(String name) {
    return 'Monto de $name';
  }

  @override
  String get addExpensePayerAmountInvalid => 'Ingresá un monto válido.';

  @override
  String get addExpenseSplitEvenly => 'Repartir en partes iguales';

  @override
  String addExpenseDifferenceMissing(String amount) {
    return 'Faltan $amount para completar el total.';
  }

  @override
  String addExpenseDifferenceExceeded(String amount) {
    return 'Sobran $amount respecto del total.';
  }

  @override
  String get tasksLoadError => 'No se pudieron cargar las tareas.';

  @override
  String get taskStatusUnassigned => 'Sin asignar';

  @override
  String get taskStatusPending => 'Pendiente';

  @override
  String get taskStatusCompleted => 'Completada';

  @override
  String taskAssignedTo(String name) {
    return 'Asignada a $name';
  }

  @override
  String get addExpenseDebtorsTitle => '¿Quiénes deben?';

  @override
  String get addExpenseDebtorsSubtitle =>
      'Seleccioná una o más personas que deben asumir el gasto.';

  @override
  String get addExpenseDebtorAmountsTitle => 'Montos adeudados';

  @override
  String addExpenseDebtorAmountLabel(String name) {
    return 'Monto de $name';
  }

  @override
  String get taskClaimAction => 'Tomar';

  @override
  String get taskCompleteAction => 'Completar';

  @override
  String get taskReassignAction => 'Reasignar';

  @override
  String get tasksOperationError =>
      'No se pudo actualizar la tarea. Intentá nuevamente.';

  @override
  String get createTaskDialogTitle => 'Agregar tarea';

  @override
  String get createTaskTitleLabel => '¿Qué hay que hacer?';

  @override
  String get createTaskTitleHint => 'Ej. Comprar hielo';

  @override
  String get createTaskTitleRequired => 'Ingresá un título para la tarea.';

  @override
  String get createTaskSubmit => 'Crear tarea';

  @override
  String get reassignTaskDialogTitle => 'Reasignar tarea';

  @override
  String get reassignTaskParticipantLabel => 'Elegí quién se hará cargo.';

  @override
  String get reassignTaskParticipantRequired =>
      'Elegí una persona para continuar.';

  @override
  String get reassignTaskConfirm => 'Reasignar';

  @override
  String get addExpenseDebtorAmountInvalid => 'Ingresá un monto válido.';

  @override
  String get addExpenseSplitDebtorsEvenly => 'Repartir en partes iguales';

  @override
  String addExpenseDebtorDifferenceMissing(String amount) {
    return 'Faltan $amount para completar el total.';
  }

  @override
  String addExpenseDebtorDifferenceExceeded(String amount) {
    return 'Sobran $amount respecto del total.';
  }

  @override
  String get addExpenseSave => 'Confirmar';

  @override
  String get addExpenseSaving => 'Guardando gasto...';

  @override
  String get addExpenseSaveSuccess => 'El gasto se guardó correctamente.';

  @override
  String get addExpenseValidationError =>
      'Revisá los datos del gasto, los participantes y que los montos coincidan con el total.';

  @override
  String get addExpenseAuthenticationError =>
      'Tu sesión no es válida. Volvé a iniciar sesión.';

  @override
  String get addExpenseForbiddenError =>
      'No tenés permiso para cargar gastos en este evento.';

  @override
  String get addExpenseNotFoundError => 'No se encontró el evento.';

  @override
  String get addExpenseEventUnavailableError =>
      'El evento fue cancelado y no acepta gastos.';

  @override
  String get addExpenseClosedError =>
      'Los gastos de este evento ya están cerrados.';

  @override
  String get addExpenseNetworkError =>
      'No se pudo guardar el gasto por un problema de conexión.';

  @override
  String get addExpenseSaveError =>
      'No se pudo confirmar el guardado del gasto. Intentá nuevamente.';

  @override
  String get eventDebtsTitle => 'Deudas del evento';

  @override
  String get eventDebtsLoading => 'Cargando deudas del evento...';

  @override
  String eventDebtDescription(
    String debtorName,
    String amount,
    String creditorName,
  ) {
    return '$debtorName le debe $amount a $creditorName';
  }

  @override
  String get eventDebtPending => 'Pendiente';

  @override
  String get eventDebtSettled => 'Saldada';

  @override
  String get eventDebtsAllSettled => 'Todo saldado';

  @override
  String get eventDebtsEmpty => 'Todavía no hay deudas en este evento.';

  @override
  String get eventDebtsLoadError =>
      'No se pudieron cargar las deudas del evento. Intentá nuevamente.';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationBalances => 'Balances';

  @override
  String get balancesTitle => 'Balances';

  @override
  String get balancesOwedToMe => 'Me deben';

  @override
  String get balancesIOwe => 'Debo';

  @override
  String get balancesPeopleTitle => 'Saldos por persona';

  @override
  String get balancesLoading => 'Cargando balances...';

  @override
  String get balancesEmpty => 'No tenés saldos pendientes.';

  @override
  String get balancesLoadError =>
      'No se pudieron cargar tus balances. Intentá nuevamente.';

  @override
  String get balanceStatusPay => 'A pagar';

  @override
  String get balanceStatusPending => 'Pendiente';

  @override
  String get balanceStatusSettled => 'Saldado';

  @override
  String get balancesNetLabel => 'Balance neto';

  @override
  String get balancesFilterAll => 'Todo';

  @override
  String get balancesFilterEmpty => 'No hay saldos en esta categoría.';

  @override
  String get personBalanceDetailLoading => 'Cargando detalle de saldo';

  @override
  String get personBalanceDetailLoadError =>
      'No se pudo cargar el detalle del saldo.';

  @override
  String get personBalanceDetailBreakdownTitle => 'Desglose por evento';

  @override
  String personBalanceDetailYouOwe(String amount, String name) {
    return 'Le debés \$ $amount a $name';
  }

  @override
  String personBalanceDetailOwedToYou(String name, String amount) {
    return '$name te debe \$ $amount';
  }

  @override
  String get personBalanceDetailSettled => 'Están a mano';

  @override
  String personBalanceDetailLineYouOwe(String name) {
    return 'Le debés a $name';
  }

  @override
  String personBalanceDetailLineOwedToYou(String name) {
    return '$name te debe';
  }
}
