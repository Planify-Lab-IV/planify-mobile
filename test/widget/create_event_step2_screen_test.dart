import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/features/events/data/fake_events_repository.dart';
import 'package:planify/features/events/domain/event_draft.dart';
import 'package:planify/features/events/presentation/controllers/event_draft_notifier.dart';
import 'package:planify/features/events/presentation/controllers/event_draft_providers.dart';
import 'package:planify/features/events/presentation/screens/create_event_step2_screen.dart';
import 'package:planify/features/groups/data/fake_groups_repository.dart';
import 'package:planify/features/groups/domain/group.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';
import 'package:planify/l10n/app_localizations.dart';

Widget _buildTestApp({
  EventDraft? initialDraft,
  FakeGroupsRepository? fakeGroupsRepo,
  FakeEventsRepository? fakeEventsRepo,
}) {
  return ProviderScope(
    overrides: [
      if (initialDraft != null)
        eventDraftProvider.overrideWith(
          (ref) => EventDraftNotifier(initialDraft),
        ),
      groupsRepositoryProvider.overrideWithValue(
        fakeGroupsRepo ?? FakeGroupsRepository(delay: Duration.zero),
      ),
      eventsRepositoryProvider.overrideWithValue(
        fakeEventsRepo ?? FakeEventsRepository(delay: Duration.zero),
      ),
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
      home: const CreateEventStep2Screen(),
    ),
  );
}

void main() {
  group('CreateEventStep2Screen Widget Tests', () {
    const validDraft = EventDraft(
      name: 'Cumpleaños de Lucas',
      location: 'Av. Corrientes 1234',
    );

    testWidgets('renderiza encabezado, selector de modo y botones', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(initialDraft: validDraft));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Crear Evento'), findsOneWidget);
      expect(find.text('Paso 2 de 2'), findsOneWidget);
      expect(find.text('Grupo y participantes'), findsOneWidget);
      expect(find.byKey(const Key('group_mode_selector')), findsOneWidget);
      expect(find.text('Grupo existente'), findsOneWidget);
      expect(find.text('Crear grupo nuevo'), findsOneWidget);
      expect(find.byKey(const Key('wizard_step2_back_button')), findsOneWidget);
      expect(
        find.byKey(const Key('create_event_submit_button')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Crear Evento'),
        findsOneWidget,
      );
    });

    testWidgets('grupo existente: valida seleccion obligatoria de grupo', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(initialDraft: validDraft));
      await tester.pumpAndSettle();

      // Intenta enviar sin seleccionar grupo
      await tester.ensureVisible(
        find.byKey(const Key('create_event_submit_button')),
      );
      await tester.tap(find.byKey(const Key('create_event_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor seleccioná un grupo'), findsOneWidget);
    });

    testWidgets(
      'grupo existente: selecciona un grupo y crea el evento con exito mostrando el resumen',
      (tester) async {
        final fakeGroups = [
          const Group(
            id: 'grp-1',
            name: 'Amigos del Fútbol',
            memberIdentifiers: [
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
              '10',
            ],
          ),
        ];
        final fakeGroupsRepo = FakeGroupsRepository(
          delay: Duration.zero,
          initialGroups: fakeGroups,
        );
        final fakeEventsRepo = FakeEventsRepository(delay: Duration.zero);

        await tester.pumpWidget(
          _buildTestApp(
            initialDraft: validDraft,
            fakeGroupsRepo: fakeGroupsRepo,
            fakeEventsRepo: fakeEventsRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Abre el dropdown y selecciona el grupo
        await tester.tap(find.byKey(const Key('select_group_dropdown')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Amigos del Fútbol').last);
        await tester.pumpAndSettle();

        // Envia el formulario
        await tester.ensureVisible(
          find.byKey(const Key('create_event_submit_button')),
        );
        await tester.tap(find.byKey(const Key('create_event_submit_button')));
        await tester.pumpAndSettle();

        // Verifica la pantalla de exito con ID y datos
        expect(find.text('¡Evento creado con éxito!'), findsOneWidget);
        expect(find.byKey(const Key('created_event_name')), findsOneWidget);
        expect(find.text('Cumpleaños de Lucas'), findsOneWidget);
        expect(find.byKey(const Key('created_event_location')), findsOneWidget);
        expect(find.text('Av. Corrientes 1234'), findsOneWidget);
        expect(find.byKey(const Key('created_event_group')), findsOneWidget);
        expect(find.text('Amigos del Fútbol'), findsOneWidget);
        expect(find.byKey(const Key('back_to_home_button')), findsOneWidget);
      },
    );

    testWidgets(
      'grupo nuevo: valida nombre obligatorio, agrega identificadores de miembros y crea evento',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(initialDraft: validDraft));
        await tester.pumpAndSettle();

        // Cambia al modo Crear grupo nuevo
        await tester.ensureVisible(find.text('Crear grupo nuevo'));
        await tester.tap(find.text('Crear grupo nuevo'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('new_group_name_input')), findsOneWidget);
        expect(
          find.byKey(const Key('member_identifier_input')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('add_member_button')), findsOneWidget);

        // Intenta enviar con nombre vacio
        await tester.ensureVisible(
          find.byKey(const Key('create_event_submit_button')),
        );
        await tester.tap(find.byKey(const Key('create_event_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Por favor ingresá el nombre del grupo'),
          findsOneWidget,
        );

        // Ingresa nombre del nuevo grupo
        await tester.enterText(
          find.byKey(const Key('new_group_name_input')),
          'Amigos de la Primaria',
        );

        // Agrega miembros por email y username
        await tester.enterText(
          find.byKey(const Key('member_identifier_input')),
          'juan@gmail.com',
        );
        await tester.tap(find.byKey(const Key('add_member_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('member_chip_juan@gmail.com')),
          findsOneWidget,
        );
        expect(find.text('Miembros (1)'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('member_identifier_input')),
          '@pedro123',
        );
        await tester.tap(find.byKey(const Key('add_member_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('member_chip_@pedro123')), findsOneWidget);
        expect(find.text('Miembros (2)'), findsOneWidget);

        // Intenta agregar duplicado
        await tester.enterText(
          find.byKey(const Key('member_identifier_input')),
          'juan@gmail.com',
        );
        await tester.tap(find.byKey(const Key('add_member_button')));
        await tester.pump();

        expect(find.text('Este miembro ya fue agregado'), findsOneWidget);

        // Envia el formulario
        await tester.ensureVisible(
          find.byKey(const Key('create_event_submit_button')),
        );
        await tester.tap(find.byKey(const Key('create_event_submit_button')));
        await tester.pumpAndSettle();

        // Verifica exito
        expect(find.text('¡Evento creado con éxito!'), findsOneWidget);
        expect(find.text('Amigos de la Primaria'), findsOneWidget);
      },
    );

    testWidgets('muestra banner de error cuando falla la creacion del evento', (
      tester,
    ) async {
      final errorEventsRepo = FakeEventsRepository(
        delay: Duration.zero,
        shouldThrowError: true,
      );

      const draftWithGroup = EventDraft(
        name: 'Cumpleaños',
        location: 'Casa',
        isNewGroup: false,
        selectedGroupId: 'grp-1',
        selectedGroupName: 'Amigos',
      );

      await tester.pumpWidget(
        _buildTestApp(
          initialDraft: draftWithGroup,
          fakeEventsRepo: errorEventsRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('create_event_submit_button')),
      );
      await tester.tap(find.byKey(const Key('create_event_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo crear el evento. Intenta nuevamente.'),
        findsOneWidget,
      );
    });
  });
}
