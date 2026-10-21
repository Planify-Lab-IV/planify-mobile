import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../groups/presentation/screens/groups_screen.dart';
import '../../../balances/presentation/screens/balances_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../controllers/registered_home_tab_provider.dart';

// Shell compartida por sesiones registradas. Las sesiones anónimas no llegan
// a este widget desde main.dart y, por eso, no pueden navegar a Balances.
class RegisteredHomeShell extends ConsumerWidget {
  final Widget home;

  const RegisteredHomeShell({super.key, required this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = AppLocalizations.of(context)!;
    final selectedIndex = ref.watch(registeredHomeSelectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          home,
          const GroupsScreen(),
          const BalancesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('registered_navigation_bar'),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(registeredHomeSelectedTabProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            key: const Key('registered_navigation_home'),
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: i18n.navigationHome,
          ),
          NavigationDestination(
            key: const Key('registered_navigation_groups'),
            icon: const Icon(Icons.group_outlined),
            selectedIcon: const Icon(Icons.group_rounded),
            label: i18n.navigationGroups,
          ),
          NavigationDestination(
            key: const Key('registered_navigation_balances'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: i18n.navigationBalances,
          ),
          NavigationDestination(
            key: const Key('registered_navigation_profile'),
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: i18n.navigationProfile,
          ),
        ],
      ),
    );
  }
}
