import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/person_row.dart';
import 'package:planify/features/friends/domain/person.dart';

void main() {
  const defaultPerson = Person(
    id: 'user_1',
    name: 'Ana Gómez',
    username: 'anagomez',
    relationship: FriendRelationship.none,
  );

  Widget buildSubject({
    Person person = defaultPerson,
    Widget? trailing,
    ImageProvider<Object>? imageProvider,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: PersonRow(
              person: person,
              trailing: trailing,
              imageProvider: imageProvider,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra nombre, @username y las iniciales sin imagen', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('@anagomez'), findsOneWidget);
    expect(find.text('AG'), findsOneWidget);

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, isNull);
    expect(avatar.radius, 20);
  });

  testWidgets('renderiza sin trailing cuando no se proporciona', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('renderiza el widget trailing cuando se especifica', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        trailing: FilledButton(onPressed: () {}, child: const Text('Aceptar')),
      ),
    );

    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets(
    'formatea el identificador con @ sin duplicarlo si ya lo incluye',
    (tester) async {
      const personWithAt = Person(
        id: 'user_2',
        name: 'Carlos Ruiz',
        username: '@carlosruiz',
        relationship: FriendRelationship.friend,
      );

      await tester.pumpWidget(buildSubject(person: personWithAt));

      expect(find.text('@carlosruiz'), findsOneWidget);
      expect(find.text('@@carlosruiz'), findsNothing);
    },
  );

  testWidgets('pasa imageProvider al avatar cuando se provee', (tester) async {
    final imageProvider = MemoryImage(Uint8List.fromList(_transparentPng));

    await tester.pumpWidget(buildSubject(imageProvider: imageProvider));

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.foregroundImage, same(imageProvider));
  });

  testWidgets('invoca el callback onTap al presionar la fila', (tester) async {
    var wasTapped = false;

    await tester.pumpWidget(
      buildSubject(
        onTap: () {
          wasTapped = true;
        },
      ),
    );

    await tester.tap(find.byType(PersonRow));
    await tester.pump();

    expect(wasTapped, isTrue);
  });

  testWidgets('maneja nombres y usernames largos sin overflow', (tester) async {
    const longPerson = Person(
      id: 'user_long',
      name: 'María de los Ángeles María de los Ángeles González Pérez',
      username: 'maria_de_los_angeles_gonzalez_perez_muy_largo',
      relationship: FriendRelationship.requestReceived,
    );

    await tester.pumpWidget(
      buildSubject(
        person: longPerson,
        trailing: const SizedBox(width: 80, child: Text('Acción')),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('María de los Ángeles'), findsOneWidget);
  });
}

const List<int> _transparentPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  11,
  73,
  68,
  65,
  84,
  120,
  1,
  99,
  96,
  0,
  0,
  0,
  2,
  0,
  1,
  229,
  39,
  222,
  250,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
