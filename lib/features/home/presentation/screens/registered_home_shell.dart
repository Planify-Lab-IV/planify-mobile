import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../balances/presentation/screens/balances_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

// Shell compartida por sesiones registradas. Las sesiones anónimas no llegan
// a este widget desde main.dart y, por eso, no pueden navegar a Balances.
class RegisteredHomeShell extends StatefulWidget {
  final Widget home;

  const RegisteredHomeShell({super.key, required this.home});

  @override
  State<RegisteredHomeShell> createState() => _RegisteredHomeShellState();
}

class _RegisteredHomeShellState extends State<RegisteredHomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [widget.home, const BalancesScreen(), const ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('registered_navigation_bar'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            key: const Key('registered_navigation_home'),
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: i18n.navigationHome,
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
