import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/providers/core_providers.dart';
import 'package:planify/features/groups/data/http_group_management_repository.dart';
import 'package:planify/features/groups/presentation/controllers/groups_providers.dart';

void main() {
  test('the management provider uses the authenticated HTTP client', () {
    final dio = Dio();
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final repository = container.read(groupManagementRepositoryProvider);

    expect(repository, isA<HttpGroupManagementRepository>());
    expect((repository as HttpGroupManagementRepository).dio, same(dio));
  });
}
