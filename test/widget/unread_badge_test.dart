import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/theme/app_colors.dart';
import 'package:planify/core/theme/app_theme.dart';
import 'package:planify/core/widgets/unread_badge.dart';

void main() {
  for (final count in [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99]) {
    testWidgets('renderiza el contador $count según el límite 9+', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: UnreadBadge(count: count)),
        ),
      );
      final badge = find.byType(UnreadBadge);
      final text = find.descendant(of: badge, matching: find.byType(Text));
      if (count <= 0) {
        expect(text, findsNothing);
        expect(tester.getSize(badge), Size.zero);
      } else {
        expect(tester.widget<Text>(text).data, count > 9 ? '9+' : '$count');
        final container = tester.widget<Container>(
          find.descendant(of: badge, matching: find.byType(Container)),
        );
        expect(
          (container.decoration! as BoxDecoration).color,
          AppColors.accent,
        );
      }
    });
  }
}
