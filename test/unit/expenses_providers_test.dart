import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/expenses/data/fake_expenses_repository.dart';
import 'package:planify/features/expenses/presentation/controllers/expenses_providers.dart';

void main() {
  test('expensesRepositoryProvider uses the fake implementation for now', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(expensesRepositoryProvider),
      isA<FakeExpensesRepository>(),
    );
  });
}
