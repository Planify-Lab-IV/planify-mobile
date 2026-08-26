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
  String get step2Title => 'Step 2: Coming soon';

  @override
  String get step2Subtitle =>
      'In the next steps you will be able to configure date, time, and participants.';

  @override
  String get draftSummaryTitle => 'Draft summary';

  @override
  String get draftEventName => 'Name';

  @override
  String get draftEventLocation => 'Location';
}
