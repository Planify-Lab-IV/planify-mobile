import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/balances/data/http_balances_repository.dart';
import 'package:planify/features/balances/presentation/controllers/balances_providers.dart';

void main() {
  test('balancesRepositoryProvider uses the injected HTTP client', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(balancesRepositoryProvider);

    expect(repository, isA<HttpBalancesRepository>());
    expect((repository as HttpBalancesRepository).dio, same(dio));
  });
}
