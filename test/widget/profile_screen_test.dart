import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/domain/user_session.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/auth/presentation/controllers/auth_state.dart';
import 'package:planify/features/profile/data/avatar_picker.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/presentation/controllers/profile_providers.dart';
import 'package:planify/features/profile/presentation/screens/profile_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  testWidgets('habilita Guardar solo cuando hay cambios válidos', (
    tester,
  ) async {
    final container = await _buildContainer(
      avatarPicker: const _AvatarPicker(null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('profile_identity_header')), findsOneWidget);
    expect(find.byKey(const Key('profile_content_card')), findsOneWidget);
    expect(find.byKey(const Key('profile_username_field')), findsOneWidget);
    expect(find.byKey(const Key('profile_email_field')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile_identity_header')),
        matching: find.byKey(const Key('profile_name_field')),
      ),
      findsOneWidget,
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppTheme.light.colorScheme.primaryContainer);

    ElevatedButton saveButton() => tester.widget<ElevatedButton>(
      find.byKey(const Key('profile_save_button')),
    );

    expect(saveButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('profile_name_field')),
      'Alice Personal',
    );
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);

    await tester.enterText(find.byKey(const Key('profile_name_field')), '   ');
    await tester.pump();
    expect(saveButton().onPressed, isNull);
  });

  testWidgets('guardar solo un avatar no cambia el nombre de la sesión', (
    tester,
  ) async {
    final container = await _buildContainer(
      avatarPicker: _AvatarPicker('/tmp/avatar.jpg'),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('profile_avatar_button')));
    await tester.pump();

    var avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isA<MemoryImage>());
    expect(
      container.read(profileNotifierProvider).pendingAvatarFilePath,
      '/tmp/avatar.jpg',
    );

    await tester.ensureVisible(find.byKey(const Key('profile_save_button')));
    await tester.tap(find.byKey(const Key('profile_save_button')));
    await tester.pumpAndSettle();

    avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isA<MemoryImage>());
    expect(
      container.read(profileNotifierProvider).profile?.avatarUrl,
      '/tmp/avatar.jpg',
    );

    final authState = container.read(authNotifierProvider) as AuthAuthenticated;
    expect((authState.session as OrganizerSession).name, 'alice');
  });

  test('usa NetworkImage para las URLs que devuelve el selector web', () {
    expect(
      profileAvatarImageProvider('blob:https://planify.test/avatar'),
      isA<NetworkImage>(),
    );
    expect(
      profileAvatarImageProvider('https://cdn.planify.test/avatar.jpg'),
      isA<NetworkImage>(),
    );
    expect(profileAvatarImageProvider('/tmp/avatar.jpg'), isA<FileImage>());
  });

  testWidgets('cancelar la galería no modifica el perfil', (tester) async {
    final container = await _buildContainer(
      avatarPicker: const _AvatarPicker(null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('profile_avatar_button')));
    await tester.pump();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    final saveButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('profile_save_button')),
    );
    expect(avatar.foregroundImage, isNull);
    expect(
      container.read(profileNotifierProvider).pendingAvatarFilePath,
      isNull,
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('un error al guardar conserva el borrador', (tester) async {
    final repository = FakeProfileRepository(delay: Duration.zero);
    final container = await _buildContainer(
      avatarPicker: const _AvatarPicker(null),
      profileRepository: repository,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('profile_name_field')),
      'Alice Personal',
    );
    await tester.pump();
    repository.shouldThrowError = true;

    await tester.ensureVisible(find.byKey(const Key('profile_save_button')));
    await tester.tap(find.byKey(const Key('profile_save_button')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No se pudieron guardar los cambios. Intentá nuevamente.'),
      findsOneWidget,
    );
    expect(container.read(profileNotifierProvider).draftName, 'Alice Personal');
  });

  testWidgets('muestra feedback y conserva el borrador si falla la galería', (
    tester,
  ) async {
    final container = await _buildContainer(
      avatarPicker: _FailingAvatarPicker(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('profile_name_field')),
      'Alice Personal',
    );

    await tester.tap(find.byKey(const Key('profile_avatar_button')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('profile_avatar_picker_error_snackbar')),
      findsOneWidget,
    );
    expect(container.read(profileNotifierProvider).draftName, 'Alice Personal');
  });
}

Future<ProviderContainer> _buildContainer({
  required AvatarPicker avatarPicker,
  FakeProfileRepository? profileRepository,
}) async {
  final storage = _ImmediateSecureStorage();
  final authRepository = FakeAuthRepository(
    storage: storage,
    delay: Duration.zero,
  );
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      secureStorageProvider.overrideWithValue(storage),
      profileRepositoryProvider.overrideWithValue(
        profileRepository ?? FakeProfileRepository(delay: Duration.zero),
      ),
      avatarPickerProvider.overrideWithValue(avatarPicker),
    ],
  );

  await container
      .read(authNotifierProvider.notifier)
      .login(identifier: 'alice', password: 'password123');
  return container;
}

Widget _buildScreen(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: ProfileScreen(
        avatarImageProvider: (_) =>
            MemoryImage(Uint8List.fromList(_transparentImage)),
      ),
    ),
  );
}

class _AvatarPicker implements AvatarPicker {
  final String? path;

  const _AvatarPicker(this.path);

  @override
  Future<String?> pickAvatar() async => path;
}

class _FailingAvatarPicker implements AvatarPicker {
  @override
  Future<String?> pickAvatar() {
    throw PlatformException(code: 'photo_access_denied');
  }
}

class _ImmediateSecureStorage implements SecureStorage {
  String? _token;

  @override
  Future<void> deleteToken() async {
    _token = null;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
}

const _transparentImage = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0xf8,
  0xcf,
  0xc0,
  0xf0,
  0x1f,
  0x00,
  0x05,
  0x00,
  0x01,
  0xff,
  0x89,
  0x99,
  0x3d,
  0x1d,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
