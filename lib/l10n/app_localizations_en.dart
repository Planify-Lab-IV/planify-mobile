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
}
