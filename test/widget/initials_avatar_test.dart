import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/initials_avatar.dart';

void main() {
  Widget buildSubject({ImageProvider<Object>? imageProvider}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: InitialsAvatar(
          name: 'Juan Pérez',
          imageProvider: imageProvider,
          radius: 24,
        ),
      ),
    );
  }

  testWidgets('muestra las iniciales cuando no recibe una imagen', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(find.text('JP'), findsOneWidget);
    expect(avatar.foregroundImage, isNull);
    expect(avatar.radius, 24);
  });

  testWidgets('usa la imagen recibida como imagen principal del avatar', (
    tester,
  ) async {
    final imageProvider = MemoryImage(Uint8List.fromList(_transparentPng));

    await tester.pumpWidget(buildSubject(imageProvider: imageProvider));

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(avatar.foregroundImage, same(imageProvider));
  });

  test('calcula iniciales para nombres simples, compuestos y vacíos', () {
    expect(InitialsAvatar.initialsFor('Lucía'), 'L');
    expect(InitialsAvatar.initialsFor('  María  González  '), 'MG');
    expect(InitialsAvatar.initialsFor('   '), '?');
  });
}

const _transparentPng = <int>[
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
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
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
