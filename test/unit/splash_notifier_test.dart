import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/splash/presentation/controllers/splash_providers.dart';

void main() {
  testWidgets('vence a los dos segundos sin reiniciarse', (tester) async {
    final notifier = SplashNotifier();
    addTearDown(notifier.dispose);
    expect(notifier.state, SplashPhase.brand);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(notifier.state, SplashPhase.brand);
    await tester.pump(const Duration(milliseconds: 1));
    expect(notifier.state, SplashPhase.loading);
    notifier.complete();
    expect(notifier.state, SplashPhase.completed);
  });

  testWidgets('resolución anticipada cancela el timer', (tester) async {
    final notifier = SplashNotifier();
    addTearDown(notifier.dispose);
    await tester.pump(const Duration(milliseconds: 100));
    notifier.complete();
    await tester.pump(const Duration(seconds: 2));
    expect(notifier.state, SplashPhase.completed);
  });

  testWidgets('consume el tiempo transcurrido antes de crear el provider', (
    tester,
  ) async {
    final notifier = SplashNotifier(
      elapsed: const Duration(milliseconds: 1500),
    );
    addTearDown(notifier.dispose);
    await tester.pump(const Duration(milliseconds: 500));
    expect(notifier.state, SplashPhase.loading);
  });

  test('si el presupuesto ya venció inicia en carga', () {
    final notifier = SplashNotifier(elapsed: const Duration(seconds: 3));
    expect(notifier.state, SplashPhase.loading);
    notifier.dispose();
  });

  testWidgets('dispose cancela el timer pendiente', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final notifier = SplashNotifier();
    notifier.dispose();
    // El framework verifica que no quedan timers al terminar este test.
  });
}
