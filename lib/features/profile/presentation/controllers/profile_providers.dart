import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fake_profile_repository.dart';
import '../../domain/profile_repository.dart';

// Punto único de sustitución para la integración con el backend.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});
