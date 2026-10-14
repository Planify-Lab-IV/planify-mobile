import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

enum SplashPhase { brand, loading, completed }

/// Tiempo ya consumido desde main(), antes de crear el controlador.
final startupElapsedProvider = Provider<Duration>((ref) => Duration.zero);

final splashNotifierProvider =
    StateNotifierProvider<SplashNotifier, SplashPhase>((ref) {
      final notifier = SplashNotifier(
        elapsed: ref.read(startupElapsedProvider),
      );
      final auth = ref.read(authNotifierProvider);
      if (auth is! AuthCheckingInitialSession) notifier.complete();
      ref.listen<AuthState>(authNotifierProvider, (previous, next) {
        if (next is! AuthCheckingInitialSession) notifier.complete();
      });
      return notifier;
    });

/// Vive en el ProviderScope raíz: ni rebuilds ni resume reinician el plazo.
class SplashNotifier extends StateNotifier<SplashPhase> {
  static const maximumDuration = Duration(seconds: 2);
  Timer? _timer;

  SplashNotifier({Duration elapsed = Duration.zero})
    : super(
        elapsed >= maximumDuration ? SplashPhase.loading : SplashPhase.brand,
      ) {
    if (state == SplashPhase.brand) {
      _timer = Timer(maximumDuration - elapsed, () {
        state = SplashPhase.loading;
      });
    }
  }

  void complete() {
    _timer?.cancel();
    _timer = null;
    if (state != SplashPhase.completed) state = SplashPhase.completed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
