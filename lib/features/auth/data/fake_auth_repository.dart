import '../../../data/secure_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/registration_rules.dart';
import '../domain/user_session.dart';
import 'auth_exceptions.dart';

class FakeAuthRepository implements AuthRepository {
  final SecureStorage _storage;
  final Duration delay;
  final Set<String> _usedUsernames;
  final Set<String> _usedEmails;
  UserSession? _currentSession;

  FakeAuthRepository({
    SecureStorage? storage,
    this.delay = const Duration(milliseconds: 800),
    Iterable<String> usedUsernames = const [],
    Iterable<String> usedEmails = const [],
  }) : _storage = storage ?? FakeSecureStorage(),
       _usedUsernames = usedUsernames.map((username) => username.trim()).toSet(),
       _usedEmails = usedEmails
           .map((email) => email.trim().toLowerCase())
           .toSet();

  @override
  Future<UserSession> login({
    required String identifier,
    required String password,
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final trimmedIdentifier = identifier.trim();
    final trimmedPassword = password.trim();

    // Simulación de error de red para testing
    if (trimmedIdentifier == 'network.error@planify.com') {
      throw const NetworkAuthException();
    }

    if (trimmedIdentifier.isEmpty || trimmedPassword.length < 6) {
      throw const InvalidCredentialsException();
    }

    final isEmail = trimmedIdentifier.contains('@');

    // creo el token con la info del usuario
    final session = OrganizerSession(
      userId: 'org-${trimmedIdentifier.hashCode.abs()}',
      // si el usuario no escribio el mail, en el posta eso lo recibiria del back, aca simulamos eso
      email: isEmail ? trimmedIdentifier : '$trimmedIdentifier@example.com',
      // lo mismo aca
      name: isEmail ? trimmedIdentifier.split('@').first : trimmedIdentifier,
      username: isEmail
          ? trimmedIdentifier.split('@').first
          : trimmedIdentifier,
      token:
          'fake-org-token:$trimmedIdentifier:${DateTime.now().millisecondsSinceEpoch}',
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<UserSession> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final normalizedName = name.trim();
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail == 'network.error@planify.com') {
      throw const NetworkAuthException();
    }

    if (!isValidRegistrationName(normalizedName) ||
        !isValidRegistrationUsername(normalizedUsername) ||
        !isValidRegistrationEmail(normalizedEmail) ||
        !isValidRegistrationPassword(password)) {
      throw const InvalidRegistrationDataException();
    }

    if (_usedUsernames.contains(normalizedUsername) ||
        _usedEmails.contains(normalizedEmail)) {
      throw const RegistrationConflictException();
    }

    final session = OrganizerSession(
      userId: 'org-${normalizedUsername.hashCode.abs()}',
      name: normalizedName,
      username: normalizedUsername,
      email: normalizedEmail,
      token:
          'fake-org-token:$normalizedUsername:${DateTime.now().millisecondsSinceEpoch}',
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<UserSession> loginAnonymously({
    required String name,
    required String pin,
    String? eventId,
  }) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    final trimmedName = name.trim();
    final trimmedPin = pin.trim();

    // Simulación de error de red para testing
    if (trimmedName == 'network.error' || trimmedPin == '0000') {
      throw const NetworkAuthException();
    }

    if (trimmedPin == '9999') {
      throw const InvalidPinException();
    }

    if (trimmedName.isEmpty || trimmedPin.length < 4) {
      throw const InvalidPinException();
    }

    final resolvedEventId = eventId ?? 'evt-fake-demo';

    final session = AnonymousSession(
      participantId: 'anon-${trimmedName.hashCode.abs()}',
      name: trimmedName,
      eventId: resolvedEventId,
      token:
          'fake-guest-token:$trimmedName:$resolvedEventId:${DateTime.now().millisecondsSinceEpoch}',
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<void> logout() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    _currentSession = null;
  }

  // en el repo real, sacaria el token de la session y se la paso al back para que
  // lo valide y me devuelva al usuario
  @override
  Future<UserSession?> getCurrentSession() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (_currentSession != null) return _currentSession;

    // si la app se cerro y volvio a abrir, lee el token guardado
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;

    // esto simula la decodificacion del token JWT sin backend
    final parts = token.split(':');
    if (token.startsWith('fake-guest-token:')) {
      final name = parts.length > 1 ? parts[1] : 'Invitado';
      final eventId = parts.length > 2 ? parts[2] : 'evt-fake-demo';
      _currentSession = AnonymousSession(
        participantId: 'anon-${name.hashCode.abs()}',
        name: name,
        eventId: eventId,
        token: token,
      );
      return _currentSession;
    }

    return null;
  }
}
