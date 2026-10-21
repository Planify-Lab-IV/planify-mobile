import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/features/home/presentation/controllers/registered_home_tab_provider.dart';

void main() {
  test('starts on Home and can select Groups', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(registeredHomeSelectedTabProvider), 0);

    container.read(registeredHomeSelectedTabProvider.notifier).state =
        registeredHomeGroupsTabIndex;

    expect(
      container.read(registeredHomeSelectedTabProvider),
      registeredHomeGroupsTabIndex,
    );
  });
}
