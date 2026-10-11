import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/events/data/events_repository_provider.dart';
import 'package:planify/features/events/data/http_events_repository.dart';
import 'package:planify/features/expenses/data/http_expenses_repository.dart';
import 'package:planify/features/expenses/presentation/controllers/expenses_providers.dart';

void main() {
  test('expensesRepositoryProvider uses the injected HTTP client', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(expensesRepositoryProvider),
      isA<HttpExpensesRepository>(),
    );
    expect(
      (container.read(expensesRepositoryProvider) as HttpExpensesRepository)
          .dio,
      same(dio),
    );
  });

  test('eventsRepositoryProvider uses the HTTP implementation', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(eventsRepositoryProvider);

    expect(repository, isA<HttpEventsRepository>());
    expect((repository as HttpEventsRepository).dio, same(dio));
  });
}
