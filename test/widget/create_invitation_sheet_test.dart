import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/invitations/data/fake_invitations_repository.dart';
import 'package:planify/features/invitations/data/invitation_exceptions.dart';
import 'package:planify/features/invitations/domain/invitations_repository.dart';
import 'package:planify/features/invitations/presentation/controllers/invitation_providers.dart';
import 'package:planify/features/invitations/presentation/widgets/create_invitation_sheet.dart';
import 'package:planify/l10n/app_localizations.dart';

class _RetryingInvitationsRepository implements InvitationsRepository {
  int createCalls = 0;

  @override
  Future<String> createInvitation(String eventId) async {
    createCalls++;
    if (createCalls == 1) throw const NetworkInvitationException();
    return 'planify://invite/token-after-retry';
  }

  @override
  Future<String> resolveInvitationToken(String token) {
    throw UnimplementedError();
  }
}

void main() {
  Widget buildApp(InvitationsRepository repository) {
    return ProviderScope(
      overrides: [invitationsRepositoryProvider.overrideWithValue(repository)],
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open_create_invitation_sheet'),
                onPressed: () =>
                    CreateInvitationSheet.show(context, eventId: 'evt-123'),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra carga, link y actualiza el botón al copiarlo', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      buildApp(FakeInvitationsRepository(delay: const Duration(seconds: 1))),
    );
    await tester.tap(find.byKey(const Key('open_create_invitation_sheet')));
    await tester.pump();
    expect(find.byKey(const Key('create_invitation_loading')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create_invitation_url')), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_invitation_copy_button')));
    await tester.pump();
    expect(copiedText, 'planify://invite/token-valid-123');
    expect(find.widgetWithText(FilledButton, 'Link copiado'), findsOneWidget);
    expect(
      find.byKey(const Key('create_invitation_copied_snackbar')),
      findsNothing,
    );
    final copyButton = tester.widget<FilledButton>(
      find.byKey(const Key('create_invitation_copy_button')),
    );
    expect(
      copyButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.success,
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.widgetWithText(FilledButton, 'Copiar link'), findsOneWidget);
    final restoredCopyButton = tester.widget<FilledButton>(
      find.byKey(const Key('create_invitation_copy_button')),
    );
    expect(restoredCopyButton.style, isNull);
  });

  testWidgets('muestra error y permite reintentar', (tester) async {
    final repository = _RetryingInvitationsRepository();
    await tester.pumpWidget(buildApp(repository));
    await tester.tap(find.byKey(const Key('open_create_invitation_sheet')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se pudo crear el link por un problema de conexión. Intentá nuevamente.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('create_invitation_retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_invitation_url')), findsOneWidget);
    expect(repository.createCalls, 2);
  });
}
