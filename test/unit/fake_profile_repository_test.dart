import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/profile/data/fake_profile_repository.dart';
import 'package:planify/features/profile/domain/user_profile.dart';

void main() {
  group('FakeProfileRepository', () {
    test('devuelve el perfil inicial inyectado', () async {
      const profile = UserProfile(
        name: 'Ana Gómez',
        username: 'ana.gomez',
        email: 'ana@example.com',
      );
      final repository = FakeProfileRepository(
        delay: Duration.zero,
        initialProfile: profile,
      );

      expect(await repository.getMyProfile(), profile);
    });

    test(
      'actualiza el nombre en memoria y conserva los datos no enviados',
      () async {
        final repository = FakeProfileRepository(delay: Duration.zero);

        final updated = await repository.updateProfile(name: 'Juan García');

        expect(updated.name, 'Juan García');
        expect(updated.username, 'juan.perez');
        expect(updated.email, 'juan.perez@planify.com');
        expect(await repository.getMyProfile(), updated);
      },
    );

    test(
      'guarda la ruta local de avatar y conserva el nombre actual',
      () async {
        final repository = FakeProfileRepository(delay: Duration.zero);

        final updated = await repository.updateProfile(
          avatarFilePath: '/tmp/profile.webp',
        );

        expect(updated.name, 'Juan Pérez');
        expect(updated.avatarUrl, '/tmp/profile.webp');
        expect(await repository.getMyProfile(), updated);
      },
    );

    test('simula errores tanto al cargar como al guardar', () async {
      final repository = FakeProfileRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );

      expect(repository.getMyProfile(), throwsException);
      expect(repository.updateProfile(name: 'Juan'), throwsException);
    });
  });
}
