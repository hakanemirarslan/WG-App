import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

/// Bottom navigation around the five group tabs (SPEC 11, screen 3).
/// [navigationShell] keeps each tab's state alive while switching tabs.
class GroupShell extends StatelessWidget {
  const GroupShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.overviewTab),
          NavigationDestination(icon: const Icon(Icons.checklist), label: l10n.tabList),
          NavigationDestination(icon: const Icon(Icons.receipt_long), label: l10n.tabExpenses),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: l10n.tabBalance,
          ),
          NavigationDestination(icon: const Icon(Icons.group), label: l10n.tabGroup),
        ],
      ),
    );
  }
}
