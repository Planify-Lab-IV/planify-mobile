import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/core/widgets/planify_logo.dart';
import 'package:planify/data/secure_storage.dart';
import 'package:planify/features/auth/data/fake_auth_repository.dart';
import 'package:planify/features/auth/presentation/controllers/auth_providers.dart';
import 'package:planify/main.dart';

void main() {
  testWidgets('Smoke test de inicio de la aplicación Planify', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(delay: Duration.zero),
          ),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localeNotifierProvider.overrideWith(
            (ref) => LocaleNotifier()..setLocale(const Locale('es')),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PlanifyLogo), findsOneWidget);
    expect(find.text('Planify'), findsOneWidget);
    expect(find.text('Organizá tus planes, sin vueltas'), findsOneWidget);
  });
}
