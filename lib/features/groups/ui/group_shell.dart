import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout.dart';
import '../../../l10n/app_localizations.dart';

/// Navigation around the five group tabs (SPEC 11, screen 3): a bottom tab bar on
/// phones, a sidebar on the left on wide windows (`wideLayoutBreakpoint`).
/// [navigationShell] keeps each tab's state alive while switching tabs.
class GroupShell extends StatelessWidget {
  const GroupShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) =>
      navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final divider = Theme.of(context).colorScheme.outlineVariant;
    final tabs = [
      (icon: Icons.home_outlined, label: l10n.overviewTab),
      (icon: Icons.checklist, label: l10n.tabList),
      (icon: Icons.receipt_long, label: l10n.tabExpenses),
      (icon: Icons.account_balance_wallet_outlined, label: l10n.tabBalance),
      (icon: Icons.group, label: l10n.tabGroup),
    ];

    if (isWideLayout(context)) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
                // Extended: icon and label side by side, like a desktop sidebar. Labels
                // under the icons had to squeeze "Harcamalar" into a narrow column.
                extended: true,
                minExtendedWidth: 220,
                labelType: NavigationRailLabelType.none,
                groupAlignment: -1,
                leading: const SizedBox(height: 8),
                destinations: [
                  for (final tab in tabs)
                    NavigationRailDestination(
                      icon: Icon(tab.icon),
                      label: Text(tab.label),
                      // Air between the items; the default packs them tightly.
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: divider),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: divider)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
      ),
    );
  }
}
