import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/fake_auth_repository.dart';
import '../../domain/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

// el provider puede ser accedido globalmente por los widgets
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Punto de extensión: en PLANIFY-36 se puede reemplazar por HttpAuthRepository(dio: ref.watch(dioClientProvider))
  return FakeAuthRepository();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repository, storage);
});
