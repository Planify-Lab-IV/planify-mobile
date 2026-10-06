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
    final imageProvider = MemoryImage(Uint8List.fromList(<int>[]));

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
