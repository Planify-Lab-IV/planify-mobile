// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloTest => 'Hello, this is an i18n test';

  @override
  String get identifierLabel => 'Email or username';

  @override
  String get identifierHint => 'organizer@planify.com';

  @override
  String get identifierRequired => 'Please enter your email or username';

  @override
  String get identifierInvalid => 'Please enter a valid email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loggingIn => 'Signing in...';

  @override
  String get loginErrorGeneric => 'Could not sign in. Please try again.';

  @override
  String get loginErrorInvalidCredentials =>
      'Invalid credentials. Please verify your email and password.';

  @override
  String get logoutButton => 'Sign Out';

  @override
  String welcomeOrganizer(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get welcome => 'Welcome!';

  @override
  String get organizerPanelTitle => 'Organizer Dashboard';

  @override
  String get sessionActiveDescription =>
      'You have successfully signed in as an event organizer on Planify.';

  @override
  String get tokenLabel => 'Session Token';

  @override
  String get roleLabel => 'Role';

  @override
  String get emailLabel => 'Email';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get orDivider => 'or';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Sign in to your account or continue as guest';

  @override
  String get appTagline => 'Organize your plans, effortlessly';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get pinLabel => 'Event PIN';

  @override
  String get pinRequired => 'Please enter the event PIN';

  @override
  String get pinMinLength => 'PIN must be at least 4 characters';

  @override
  String get joinButton => 'Join';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get loginErrorInvalidPin =>
      'Invalid PIN. Please check the code and try again.';

  @override
  String get eventIdLabel => 'Event ID';

  @override
  String get participantPanelTitle => 'Participant Dashboard';

  @override
  String get sessionActiveParticipantDescription =>
      'You have successfully joined as an event participant.';

  @override
  String get guestRole => 'Guest';

  @override
  String get organizerRole => 'Organizer';

  @override
  String get eventLabel => 'Event';

  @override
  String get createEventTitle => 'Create Event';

  @override
  String get createEventButton => 'Create new event';

  @override
  String get step1Badge => 'Step 1 of 2';

  @override
  String get step1Title => 'Basic information';

  @override
  String get step1Subtitle => 'Enter your event\'s name and location.';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get eventNameHint => 'e.g. Lucas\'s Birthday';

  @override
  String get eventNameRequired => 'Please enter the event name';

  @override
  String get eventLocationLabel => 'Location or address';

  @override
  String get eventLocationHint => 'e.g. Lucas\' house or 1234 Main St';

  @override
  String get eventLocationRequired => 'Please enter the event location';

  @override
  String get continueButton => 'Continue';

  @override
  String get backButton => 'Back';

  @override
  String get step2Badge => 'Step 2 of 2';

  @override
  String get step2Title => 'Group and participants';

  @override
  String get step2Subtitle =>
      'Choose an existing group or create a new one with its members.';

  @override
  String get existingGroupOption => 'Existing group';

  @override
  String get existingGroupSubtitle => 'Select a group you already created';

  @override
  String get newGroupOption => 'Create new group';

  @override
  String get newGroupSubtitle => 'Create a new group and invite participants';

  @override
  String get selectGroupLabel => 'Select group';

  @override
  String get selectGroupHint => 'Choose a group...';

  @override
  String get selectGroupRequired => 'Please select a group';

  @override
  String get loadingGroups => 'Loading groups...';

  @override
  String get errorLoadingGroups => 'Could not load groups';

  @override
  String get retryButton => 'Retry';

  @override
  String get noGroupsAvailable =>
      'You have no created groups. You can create a new one.';

  @override
  String get newGroupNameLabel => 'New group name';

  @override
  String get newGroupNameHint => 'e.g. Football Friends';

  @override
  String get newGroupNameRequired => 'Please enter the group name';

  @override
  String get memberIdentifierLabel => 'Member (email or username)';

  @override
  String get memberIdentifierHint => 'example@email.com or @username';

  @override
  String get addMemberButton => 'Add';

  @override
  String get memberAlreadyAdded => 'This member has already been added';

  @override
  String get memberIdentifierEmpty => 'Enter a valid email or username';

  @override
  String membersListTitle(int count) {
    return 'Members ($count)';
  }

  @override
  String get createEventSubmitButton => 'Create Event';

  @override
  String get creatingEventLoading => 'Creating event...';

  @override
  String get createEventErrorGeneric =>
      'Could not create event. Please try again.';

  @override
  String get createEventSuccessTitle => 'Event created successfully!';

  @override
  String get createEventSuccessSubtitle =>
      'Your event is ready and assigned to its group.';

  @override
  String get createdEventIdLabel => 'Event ID';

  @override
  String get assignedGroupLabel => 'Assigned group';

  @override
  String get backToHomeButton => 'Back to home';

  @override
  String get viewEventDetailButton => 'View event details';

  @override
  String get draftSummaryTitle => 'Draft summary';

  @override
  String get draftEventName => 'Name';

  @override
  String get draftEventLocation => 'Location';

  @override
  String get generateWithAi => 'Generate with AI';

  @override
  String get generateWithAiComingSoon => 'AI event generation coming soon';

  @override
  String get eventDetailTitle => 'Event Details';

  @override
  String get eventStatusLabel => 'Status';

  @override
  String get eventStatusActive => 'Active';

  @override
  String get eventStatusCancelled => 'Cancelled';

  @override
  String get eventDateFallback => 'Date TBD';

  @override
  String get quickActionsTitle => 'Quick actions';

  @override
  String get quickActionInvite => 'Invite';

  @override
  String get quickActionAddExpense => 'Add expense';

  @override
  String get quickActionAddTask => 'Add task';

  @override
  String get quickActionSettle => 'Settle up';

  @override
  String get tasksSectionTitle => 'Tasks';

  @override
  String get noTasksPlaceholder => 'No tasks assigned yet.';

  @override
  String get activityLogSectionTitle => 'Recent activity';

  @override
  String get noActivityPlaceholder =>
      'No activity recorded for this event yet.';

  @override
  String get featureUnderDevelopment => 'This feature will be available soon.';

  @override
  String get cancelEventAction => 'Cancel event';

  @override
  String get cancelEventDialogTitle => 'Cancel event?';

  @override
  String get cancelEventDialogMessage =>
      'Are you sure you want to cancel this event? This action cannot be undone.';

  @override
  String get cancelEventConfirm => 'Yes, cancel event';

  @override
  String get cancelEventDismiss => 'Back';

  @override
  String get cancelEventSuccess => 'The event was successfully cancelled.';

  @override
  String get cancelEventError =>
      'Could not cancel the event. Please try again.';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get eventCancelledNotice =>
      'This event has been cancelled and no longer accepts new actions.';

  @override
  String get eventActionsTooltip => 'Event options';

  @override
  String get cancellingEvent => 'Cancelling event...';

  @override
  String get invitationErrorInvalid => 'The invitation link is invalid.';

  @override
  String get invitationErrorNotFound =>
      'The event for this invitation was not found.';

  @override
  String get invitationErrorExpired =>
      'The invitation has expired or is no longer available.';

  @override
  String get invitationErrorNetwork =>
      'Network error while validating invitation. Please check your connection.';

  @override
  String get invitationErrorGeneric =>
      'Could not process invitation. Please try again.';

  @override
  String get invitationBannerEvent => 'You have an event invitation!';

  @override
  String get resolvingInvitation => 'Loading invitation...';

  @override
  String get attendanceTitle => 'Will you attend?';

  @override
  String get attendanceGoing => 'Going';

  @override
  String get attendanceNotGoing => 'Not going';

  @override
  String get attendanceConfirmed => 'Confirmed';

  @override
  String get attendanceRejected => 'Rejected';

  @override
  String get attendancePending => 'No response';

  @override
  String get attendanceUpdateError =>
      'We could not update your attendance. Please try again.';
}
