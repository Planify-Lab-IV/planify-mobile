import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/features/friends/data/fake_friends_repository.dart';
import 'package:planify/features/friends/presentation/controllers/friends_providers.dart';
import 'package:planify/features/profile/data/avatar_picker.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/data/profile_exceptions.dart';
import 'package:planify/features/profile/domain/avatar_upload.dart';
import 'package:planify/features/profile/domain/user_profile.dart';
import 'package:planify/features/profile/presentation/controllers/profile_providers.dart';
import 'package:planify/features/profile/presentation/controllers/profile_state.dart';
import 'package:planify/features/profile/presentation/screens/profile_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  final avatar = AvatarUpload(
    bytes: Uint8List.fromList(_transparentImage),
    filename: 'avatar.png',
    mimeType: 'image/png',
  );

  testWidgets('previsualiza el avatar seleccionado con MemoryImage', (
    tester,
  ) async {
    final container = await _buildContainer(
      avatarPicker: _AvatarPicker(avatar),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_avatar_button')));
    await tester.pump();

    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(circleAvatar.foregroundImage, isA<MemoryImage>());
    expect(container.read(profileNotifierProvider).pendingAvatar, same(avatar));
  });

  testWidgets('muestra avatar remoto y fallback de iniciales', (tester) async {
    final remoteContainer = await _buildContainer(
      avatarPicker: const _AvatarPicker(null),
      initialProfile: const UserProfile(
        name: 'Alice Example',
        username: 'alice',
        email: 'alice@example.com',
        avatarUrl: 'https://cdn.planify.test/avatar.jpg',
      ),
    );
    addTearDown(remoteContainer.dispose);

    await tester.pumpWidget(_buildScreen(remoteContainer));
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage,
      isA<NetworkImage>(),
    );
    expect(find.text('AE'), findsOneWidget);
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

    expect(container.read(profileNotifierProvider).pendingAvatar, isNull);
  });

  testWidgets('muestra error claro de formato sin perder el nombre editado', (
    tester,
  ) async {
    final container = await _buildContainer(
      avatarPicker: _FailingAvatarPicker(
        const InvalidAvatarFileException(
          AvatarUploadValidationError.unsupportedFormat,
        ),
      ),
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

    expect(find.text('Elegí una imagen JPEG, PNG o WebP.'), findsOneWidget);
    expect(container.read(profileNotifierProvider).draftName, 'Alice Personal');
  });

  testWidgets('conserva el nombre y muestra error de red al guardar', (
    tester,
  ) async {
    final container = await _buildContainer(
      avatarPicker: const _AvatarPicker(null),
      profileRepository: _NetworkFailingProfileRepository(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('profile_name_field')),
      'Alice Personal',
    );
    await tester.tap(find.byKey(const Key('profile_save_button')));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'No se pudieron guardar los cambios por un problema de conexión. Intentá nuevamente.',
      ),
      findsOneWidget,
    );
    expect(container.read(profileNotifierProvider).draftName, 'Alice Personal');
    expect(
      container.read(profileNotifierProvider).saveFailure,
      ProfileSaveFailure.network,
    );
  });
}

Future<ProviderContainer> _buildContainer({
  required AvatarPicker avatarPicker,
  FakeProfileRepository? profileRepository,
  UserProfile? initialProfile,
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
        profileRepository ??
            FakeProfileRepository(
              delay: Duration.zero,
              initialProfile: initialProfile,
            ),
      ),
      friendsRepositoryProvider.overrideWithValue(
        FakeFriendsRepository(delay: Duration.zero),
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
      home: const ProfileScreen(),
    ),
  );
}

class _AvatarPicker implements AvatarPicker {
  final AvatarUpload? avatar;

  const _AvatarPicker(this.avatar);

  @override
  Future<AvatarUpload?> pickAvatar() async => avatar;
}

class _FailingAvatarPicker implements AvatarPicker {
  final Exception error;

  _FailingAvatarPicker(this.error);

  @override
  Future<AvatarUpload?> pickAvatar() => Future<AvatarUpload?>.error(error);
}

class _NetworkFailingProfileRepository extends FakeProfileRepository {
  _NetworkFailingProfileRepository() : super(delay: Duration.zero);

  @override
  Future<UserProfile> updateProfile({String? name, AvatarUpload? avatar}) {
    throw const NetworkProfileException();
  }
}

class _ImmediateSecureStorage implements SecureStorage {
  String? _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;
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
