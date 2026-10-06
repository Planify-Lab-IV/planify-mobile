import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile', () {
    const profile = UserProfile(
      name: 'Juan Pérez',
      username: 'juan.perez',
      email: 'juan@example.com',
    );

    test('preserva los datos de cuenta y permite no tener avatar', () {
      expect(profile.name, 'Juan Pérez');
      expect(profile.username, 'juan.perez');
      expect(profile.email, 'juan@example.com');
      expect(profile.avatarUrl, isNull);
    });

    test(
      'copyWith actualiza el avatar sin alterar los datos de solo lectura',
      () {
        final updated = profile.copyWith(avatarUrl: '/tmp/avatar.jpg');

        expect(updated.name, 'Juan Pérez');
        expect(updated.username, 'juan.perez');
        expect(updated.email, 'juan@example.com');
        expect(updated.avatarUrl, '/tmp/avatar.jpg');
      },
    );

    test('compara perfiles por valor, incluido el avatar opcional', () {
      expect(
        profile,
        const UserProfile(
          name: 'Juan Pérez',
          username: 'juan.perez',
          email: 'juan@example.com',
        ),
      );
      expect(profile, isNot(profile.copyWith(avatarUrl: '/tmp/avatar.jpg')));
    });
  });
}
