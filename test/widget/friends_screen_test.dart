import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/person_row.dart';
import 'package:planify/features/friends/data/fake_friends_repository.dart';
import 'package:planify/features/friends/domain/friend_requests.dart';
import 'package:planify/features/friends/domain/friends_repository.dart';
import 'package:planify/features/friends/presentation/controllers/friends_providers.dart';
import 'package:planify/features/friends/presentation/screens/friends_screen.dart';
import 'package:planify/l10n/app_localizations.dart';

void main() {
  Widget buildScreen({
    required ProviderContainer container,
    Locale locale = const Locale('es'),
  }) {
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
        locale: locale,
        home: const FriendsScreen(),
      ),
    );
  }

  ProviderContainer buildContainer({FriendsRepository? repository}) {
    return ProviderContainer(
      overrides: [
        friendsRepositoryProvider.overrideWithValue(
          repository ?? FakeFriendsRepository(delay: Duration.zero),
        ),
      ],
    );
  }

  testWidgets('renderiza las secciones iniciales con solicitudes y amigos', (
    tester,
  ) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container: container));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('friends_search_field')), findsOneWidget);
    expect(find.byKey(const Key('friends_search_results')), findsNothing);
    expect(find.byKey(const Key('friends_requests_section')), findsOneWidget);
    expect(
      find.byKey(const Key('friends_sent_requests_section')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('friends_list_section')), findsOneWidget);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('@ana'), findsOneWidget);
    expect(
      find.byKey(const Key('friend_accept_button_friend-ana')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('friend_reject_button_friend-ana')),
      findsOneWidget,
    );
    expect(find.byTooltip('Aceptar'), findsOneWidget);
    expect(find.byTooltip('Rechazar'), findsOneWidget);

    expect(find.text('Bruno Díaz'), findsOneWidget);
    expect(find.text('@bruno'), findsOneWidget);
    expect(
      find.byKey(const Key('friend_cancel_button_friend-bruno')),
      findsOneWidget,
    );

    expect(find.text('Carla Gómez'), findsOneWidget);
    expect(find.text('@carla'), findsOneWidget);
  });

  testWidgets(
    'búsqueda de menos de dos caracteres no busca ni muestra resultados',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'a',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('friends_search_results')), findsNothing);
    },
  );

  testWidgets(
    'muestra resultados con sus relaciones y estado vacío cuando no hay coincidencia',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      // Búsqueda con relación none (Diego)
      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'diego',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('friends_search_results')), findsOneWidget);
      expect(
        find.byKey(const Key('friend_add_button_friend-diego')),
        findsOneWidget,
      );

      // Búsqueda con relación requestReceived (Ana)
      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'ana',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('friend_accept_button_friend-ana')),
        findsNWidgets(2), // Uno en búsqueda, uno en solicitudes recibidas
      );

      // Búsqueda con relación requestSent (Bruno)
      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'bruno',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Solicitud enviada'), findsOneWidget);
      expect(
        find.byKey(const Key('friend_cancel_button_friend-bruno')),
        findsNWidgets(2), // Uno en búsqueda, uno en solicitudes enviadas
      );

      // Búsqueda sin coincidencias
      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'zzzzz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No encontramos personas.'), findsOneWidget);
    },
  );

  testWidgets(
    'enviar solicitud pasa el resultado a enviado y agrega a solicitudes enviadas',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'diego',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final addButton = find.byKey(const Key('friend_add_button_friend-diego'));
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // En los resultados de búsqueda ahora muestra Solicitud enviada y botón Cancelar
      expect(
        find.descendant(
          of: find.byKey(const Key('friends_search_results')),
          matching: find.text('Solicitud enviada'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('friend_cancel_button_friend-diego')),
        findsNWidgets(2), // Uno en resultados, uno en enviadas
      );

      // En la sección de enviadas ahora está Diego Ruiz
      expect(
        find.descendant(
          of: find.byKey(const Key('friends_sent_requests_section')),
          matching: find.text('Diego Ruiz'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'aceptar solicitud la quita de recibidas y la suma a la lista de amigos',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      final acceptButton = find.byKey(
        const Key('friend_accept_button_friend-ana'),
      );
      expect(acceptButton, findsOneWidget);

      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      // Desaparece de solicitudes recibidas y se muestra el estado vacío
      expect(find.text('No tenés solicitudes pendientes.'), findsOneWidget);

      // Aparece en la sección de amigos
      expect(
        find.descendant(
          of: find.byKey(const Key('friends_list_section')),
          matching: find.text('Ana Pérez'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'rechazar solicitud la quita de recibidas y restaura la relación en búsqueda',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'ana',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final rejectButton = find.byKey(
        const Key('friend_reject_button_friend-ana'),
      );
      expect(rejectButton, findsOneWidget);

      await tester.tap(rejectButton);
      await tester.pumpAndSettle();

      // Desaparece de recibidas
      expect(
        find.descendant(
          of: find.byKey(const Key('friends_requests_section')),
          matching: find.text('Ana Pérez'),
        ),
        findsNothing,
      );

      // En la búsqueda ahora tiene relación none (botón Agregar)
      expect(
        find.descendant(
          of: find.byKey(const Key('friends_search_results')),
          matching: find.byKey(const Key('friend_add_button_friend-ana')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'cancelar solicitud la quita de enviadas y restaura la relación en búsqueda',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('friends_search_field')),
        'bruno',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final cancelButtons = find.byKey(
        const Key('friend_cancel_button_friend-bruno'),
      );
      expect(cancelButtons, findsNWidgets(2));

      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Sección de enviadas se oculta al quedar vacía
      expect(
        find.byKey(const Key('friends_sent_requests_section')),
        findsNothing,
      );

      // En búsqueda ahora tiene relación none (botón Agregar)
      expect(
        find.descendant(
          of: find.byKey(const Key('friends_search_results')),
          matching: find.byKey(const Key('friend_add_button_friend-bruno')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra SnackBar cuando la solicitud ya no está disponible al aceptar',
    (tester) async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final container = buildContainer(repository: repository);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      repository.markRequestUnavailable('request-ana');

      final acceptButton = find.byKey(
        const Key('friend_accept_button_friend-ana'),
      );
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      expect(find.text('Esa solicitud ya no está disponible'), findsOneWidget);
      expect(find.text('No tenés solicitudes pendientes.'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra SnackBar cuando la solicitud ya no está disponible al cancelar',
    (tester) async {
      final repository = FakeFriendsRepository(delay: Duration.zero);
      final container = buildContainer(repository: repository);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      repository.markRequestUnavailable('request-bruno');

      final cancelButton = find.byKey(
        const Key('friend_cancel_button_friend-bruno'),
      );
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.text('Esa solicitud ya no está disponible'), findsOneWidget);
      expect(
        find.byKey(const Key('friends_sent_requests_section')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'muestra el aviso si Recibidas desmonta la fila durante la recarga',
    (tester) async {
      const delay = Duration(milliseconds: 300);
      final repository = FakeFriendsRepository(delay: delay);
      final container = buildContainer(repository: repository);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pump(delay);
      await tester.pump();

      repository.markRequestUnavailable('request-ana');
      await tester.tap(
        find.byKey(const Key('friend_accept_button_friend-ana')),
      );
      await tester.pump();
      await tester.pump(delay);
      await tester.pump();

      expect(
        find.byKey(const Key('friend_accept_button_friend-ana')),
        findsNothing,
      );

      await tester.pump(delay);
      await tester.pump();

      expect(find.text('Esa solicitud ya no está disponible'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra el aviso si Enviadas desmonta la fila durante la recarga',
    (tester) async {
      const delay = Duration(milliseconds: 300);
      final repository = FakeFriendsRepository(delay: delay);
      final container = buildContainer(repository: repository);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pump(delay);
      await tester.pump();

      repository.markRequestUnavailable('request-bruno');
      await tester.tap(
        find.byKey(const Key('friend_cancel_button_friend-bruno')),
      );
      await tester.pump();
      await tester.pump(delay);
      await tester.pump();

      expect(
        find.byKey(const Key('friends_sent_requests_section')),
        findsNothing,
      );

      await tester.pump(delay);
      await tester.pump();

      expect(find.text('Esa solicitud ya no está disponible'), findsOneWidget);
    },
  );

  testWidgets('muestra SnackBar genérico cuando una acción falla', (
    tester,
  ) async {
    final repository = FakeFriendsRepository(delay: Duration.zero);
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container: container));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('friends_search_field')),
      'diego',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    repository.shouldThrowError = true;

    final addButton = find.byKey(const Key('friend_add_button_friend-diego'));
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo actualizar la solicitud. Intentá nuevamente.'),
      findsOneWidget,
    );
  });

  testWidgets('maneja errores de forma independiente por sección', (
    tester,
  ) async {
    final repository = _FailingRequestsRepository();
    final container = buildContainer(repository: repository);
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container: container));
    await tester.pumpAndSettle();

    // Sección de solicitudes muestra error y reintento
    expect(
      find.text('No se pudo cargar esta sección. Intentá nuevamente.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);

    // Sección de amigos carga correctamente
    expect(find.byKey(const Key('friends_list_section')), findsOneWidget);
    expect(find.text('Carla Gómez'), findsOneWidget);

    // Reintentar tras resolver la falla
    repository.failRequests = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
  });

  testWidgets('pull to refresh recarga solicitudes y amigos', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildScreen(container: container));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Carla Gómez'), findsOneWidget);
  });

  testWidgets(
    'no expone correos electrónicos y utiliza PersonRow en todas las secciones',
    (tester) async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(buildScreen(container: container));
      await tester.pumpAndSettle();

      expect(find.textContaining('@planify'), findsNothing);
      expect(find.byType(PersonRow), findsAtLeastNWidgets(3));
    },
  );

  testWidgets('resuelve textos localizados en idioma inglés', (tester) async {
    final container = buildContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      buildScreen(container: container, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Search people'), findsOneWidget);
    expect(find.text('Requests · Received'), findsOneWidget);
    expect(find.text('Requests · Sent'), findsOneWidget);
    expect(find.text('My friends'), findsOneWidget);
    expect(find.byTooltip('Accept'), findsOneWidget);
    expect(find.byTooltip('Decline'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}

class _FailingRequestsRepository extends FakeFriendsRepository {
  bool failRequests = true;

  _FailingRequestsRepository() : super(delay: Duration.zero);

  @override
  Future<FriendRequests> getRequests() async {
    if (failRequests) {
      throw Exception('Network error');
    }
    return super.getRequests();
  }
}
