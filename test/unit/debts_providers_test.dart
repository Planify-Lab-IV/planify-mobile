import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/debts/data/http_debts_repository.dart';
import 'package:planify/features/debts/presentation/controllers/debts_providers.dart';

void main() {
  test('debtsRepositoryProvider uses the injected HTTP client', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(debtsRepositoryProvider);

    expect(repository, isA<HttpDebtsRepository>());
    expect((repository as HttpDebtsRepository).dio, same(dio));
  });
}
