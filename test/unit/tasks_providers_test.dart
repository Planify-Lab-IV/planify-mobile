import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/tasks/data/http_tasks_repository.dart';
import 'package:planify/features/tasks/presentation/controllers/tasks_providers.dart';

void main() {
  test('tasksRepositoryProvider creates an HttpTasksRepository', () {
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(Dio())],
    );
    addTearDown(container.dispose);

    expect(container.read(tasksRepositoryProvider), isA<HttpTasksRepository>());
  });
}
