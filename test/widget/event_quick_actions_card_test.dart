import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/detail/widgets/event_quick_actions_card.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildCard({
    required bool canInvite,
    bool isCancelled = false,
    VoidCallback? onInviteTap,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(
        body: EventQuickActionsCard(
          eventId: 'evt-123',
          participants: const [],
          canInvite: canInvite,
          isCancelled: isCancelled,
          onInviteTap: onInviteTap ?? () {},
          onSettleTap: () {},
        ),
      ),
    );
  }

  testWidgets('Invitar ejecuta su callback para el organizador', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      buildCard(canInvite: true, onInviteTap: () => calls++),
    );

    await tester.tap(find.byKey(const Key('quick_action_invite')));
    expect(calls, 1);
  });

  testWidgets('Invitar no ejecuta su callback cuando no está habilitado', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      buildCard(canInvite: false, onInviteTap: () => calls++),
    );

    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('quick_action_invite')))
          .onTap,
      isNull,
    );

    await tester.tap(find.byKey(const Key('quick_action_invite')));
    expect(calls, 0);
  });

  testWidgets('Invitar permanece deshabilitado en un evento cancelado', (
    tester,
  ) async {
    await tester.pumpWidget(buildCard(canInvite: true, isCancelled: true));

    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('quick_action_invite')))
          .onTap,
      isNull,
    );
  });
}
