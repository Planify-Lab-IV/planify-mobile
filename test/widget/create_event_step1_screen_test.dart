import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/presentation/controllers/event_draft_notifier.dart';
import 'package:planify/features/events/presentation/controllers/event_draft_providers.dart';
import 'package:planify/features/events/presentation/screens/create_event_step1_screen.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/presentation/screens/create_event_step2_screen.dart';
import 'package:planify/features/groups/data/fake_groups_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildTestApp({
  EventDraft? initialDraft,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      if (initialDraft != null)
        eventDraftProvider.overrideWith(
          (ref) => EventDraftNotifier(initialDraft),
        ),
      groupsRepositoryProvider.overrideWithValue(
        FakeGroupsRepository(delay: Duration.zero),
      ),
      eventsRepositoryProvider.overrideWithValue(
        FakeEventsRepository(delay: Duration.zero),
      ),
      ...overrides,
    ],
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
      home: const CreateEventStep1Screen(),
    ),
  );
}

void main() {
  group('CreateEventStep1Screen Widget Tests', () {
    testWidgets('renderiza titulo, badge de paso, campos y boton continuar', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Crear Evento'), findsOneWidget);
      expect(find.text('Paso 1 de 2'), findsOneWidget);
      expect(find.text('Información básica'), findsOneWidget);
      expect(
        find.text('Ingresá el nombre y el lugar de tu evento.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('event_name_input')), findsOneWidget);
      expect(find.byKey(const Key('event_location_input')), findsOneWidget);
      expect(find.byKey(const Key('wizard_continue_button')), findsOneWidget);
      expect(find.byKey(const Key('generate_with_ai_button')), findsOneWidget);
      expect(find.text('Generar con IA'), findsOneWidget);
    });

    testWidgets(
      'pulsar Generar con IA muestra mensaje de funcionalidad próxima',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('generate_with_ai_button')),
        );
        await tester.tap(find.byKey(const Key('generate_with_ai_button')));
        await tester.pump();

        expect(
          find.text('Generación de eventos con IA disponible próximamente'),
          findsOneWidget,
        );
      },
    );

    testWidgets('muestra errores de validación si los campos están vacíos', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('wizard_continue_button')),
      );
      await tester.tap(find.byKey(const Key('wizard_continue_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Por favor ingresa el nombre del evento'),
        findsOneWidget,
      );
      expect(
        find.text('Por favor ingresa el lugar del evento'),
        findsOneWidget,
      );
      // No debe avanzar al paso 2 si hay errores de validación
      expect(find.byType(CreateEventStep2Screen), findsNothing);
    });

    testWidgets('muestra errores si se ingresan solo espacios en blanco', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('event_name_input')),
        '     ',
      );
      await tester.enterText(
        find.byKey(const Key('event_location_input')),
        '   ',
      );

      await tester.ensureVisible(
        find.byKey(const Key('wizard_continue_button')),
      );
      await tester.tap(find.byKey(const Key('wizard_continue_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Por favor ingresa el nombre del evento'),
        findsOneWidget,
      );
      expect(
        find.text('Por favor ingresa el lugar del evento'),
        findsOneWidget,
      );
    });

    testWidgets('completa paso 1 con datos validos y navega a paso 2', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('event_name_input')),
        'Cumpleaños de Lucas',
      );
      await tester.enterText(
        find.byKey(const Key('event_location_input')),
        'Av. Corrientes 1234',
      );

      await tester.ensureVisible(
        find.byKey(const Key('wizard_continue_button')),
      );
      await tester.tap(find.byKey(const Key('wizard_continue_button')));
      await tester.pumpAndSettle();

      // Verifica que se navegó al Paso 2
      expect(find.byType(CreateEventStep2Screen), findsOneWidget);
      expect(find.text('Paso 2 de 2'), findsOneWidget);
      expect(find.text('Grupo y participantes'), findsOneWidget);
      await tester.tap(find.byKey(const Key('group_mode_selector')));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'persistencia de datos: al volver del paso 2 al paso 1 se conservan los campos y permite editarlos',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // 1. Ingresar datos en Paso 1
        await tester.enterText(
          find.byKey(const Key('event_name_input')),
          'Asado Fin de Año',
        );
        await tester.enterText(
          find.byKey(const Key('event_location_input')),
          'Club Social',
        );

        // 2. Avanzar a Paso 2
        await tester.ensureVisible(
          find.byKey(const Key('wizard_continue_button')),
        );
        await tester.tap(find.byKey(const Key('wizard_continue_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CreateEventStep2Screen), findsOneWidget);

        // 3. Volver al Paso 1 con el botón atrás
        await tester.ensureVisible(
          find.byKey(const Key('wizard_step2_back_button')),
        );
        await tester.tap(find.byKey(const Key('wizard_step2_back_button')));
        await tester.pumpAndSettle();

        // Verifica que estamos en Paso 1 y los campos conservan el valor
        expect(find.byType(CreateEventStep1Screen), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Asado Fin de Año'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'Club Social'),
          findsOneWidget,
        );

        // 4. Modificar el lugar y volver a avanzar
        await tester.enterText(
          find.byKey(const Key('event_location_input')),
          'Quinta de Pedro',
        );
        await tester.ensureVisible(
          find.byKey(const Key('wizard_continue_button')),
        );
        await tester.tap(find.byKey(const Key('wizard_continue_button')));
        await tester.pumpAndSettle();

        // Verifica que el Paso 2 se muestra
        expect(find.byType(CreateEventStep2Screen), findsOneWidget);
      },
    );

    testWidgets(
      'persistencia de grupo: al completar nombre de nuevo grupo y miembros en paso 2, volver a paso 1 y reingresar, se conservan nombre y miembros',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // 1. Completar Paso 1 y avanzar
        await tester.enterText(
          find.byKey(const Key('event_name_input')),
          'Cumpleaños de Lucas',
        );
        await tester.enterText(
          find.byKey(const Key('event_location_input')),
          'Av. Corrientes 1234',
        );
        await tester.ensureVisible(
          find.byKey(const Key('wizard_continue_button')),
        );
        await tester.tap(find.byKey(const Key('wizard_continue_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CreateEventStep2Screen), findsOneWidget);

        // 2. Cambiar a "Crear grupo nuevo", ingresar nombre de grupo y agregar miembros
        await tester.ensureVisible(find.text('Crear grupo nuevo'));
        await tester.tap(find.text('Crear grupo nuevo'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('new_group_name_input')),
          'Amigos de la Primaria',
        );
        await tester.enterText(
          find.byKey(const Key('member_identifier_input')),
          'juan@gmail.com',
        );
        await tester.ensureVisible(find.byKey(const Key('add_member_button')));
        await tester.tap(find.byKey(const Key('add_member_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('member_chip_juan@gmail.com')),
          findsOneWidget,
        );

        // 3. Volver al Paso 1 con el botón atrás
        await tester.ensureVisible(
          find.byKey(const Key('wizard_step2_back_button')),
        );
        await tester.tap(find.byKey(const Key('wizard_step2_back_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CreateEventStep1Screen), findsOneWidget);

        // 4. Avanzar nuevamente al Paso 2
        await tester.ensureVisible(
          find.byKey(const Key('wizard_continue_button')),
        );
        await tester.tap(find.byKey(const Key('wizard_continue_button')));
        await tester.pumpAndSettle();

        expect(find.byType(CreateEventStep2Screen), findsOneWidget);

        // 5. Verificar que se conservan tanto el nombre del nuevo grupo como los miembros
        expect(
          find.widgetWithText(TextFormField, 'Amigos de la Primaria'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('member_chip_juan@gmail.com')),
          findsOneWidget,
        );
      },
    );
  });
}
