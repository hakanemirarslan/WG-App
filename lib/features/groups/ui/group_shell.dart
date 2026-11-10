import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/group_live_updates.dart';

/// Navigation around the five group tabs (SPEC 11, screen 3): a bottom tab bar on
/// phones, a sidebar on the left on wide windows (`wideLayoutBreakpoint`).
/// [navigationShell] keeps each tab's state alive while switching tabs.
class GroupShell extends ConsumerWidget {
  const GroupShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _sidebarWidth = 180.0;

  /// Branch index of the settings page (router.dart); it has no tab of its own.
  static const _settingsBranch = 5;

  void _select(int index) =>
      navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One subscription for all tabs: group photo/name and member changes arrive live.
    ref.watch(groupLiveUpdatesProvider);
    final l10n = AppLocalizations.of(context)!;
    final divider = Theme.of(context).colorScheme.outlineVariant;
    final tabs = [
      (icon: Icons.home_outlined, label: l10n.overviewTab),
      (icon: Icons.checklist, label: l10n.tabList),
      (icon: Icons.receipt_long, label: l10n.tabExpenses),
      (icon: Icons.account_balance_wallet_outlined, label: l10n.tabBalance),
      (icon: Icons.group, label: l10n.tabGroup),
    ];

    final onSettings = navigationShell.currentIndex == _settingsBranch;
    final scheme = Theme.of(context).colorScheme;

    if (isWideLayout(context)) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                // On the settings page no tab is selected; the bottom item is.
                selectedIndex: onSettings ? null : navigationShell.currentIndex,
                onDestinationSelected: _select,
                // Extended: icon and label side by side, like a desktop sidebar. Labels
                // under the icons had to squeeze "Harcamalar" into a narrow column.
                extended: true,
                minExtendedWidth: _sidebarWidth,
                labelType: NavigationRailLabelType.none,
                groupAlignment: -1,
                leading: const SizedBox(height: 8),
                // Settings (and logout) live on the groups page on phones; on the
                // desktop they also sit at the bottom of the sidebar.
                trailingAtBottom: true,
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: _sidebarWidth - 24,
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(l10n.settingsTitle),
                      shape: const StadiumBorder(),
                      selected: onSettings,
                      selectedTileColor: scheme.primaryContainer,
                      selectedColor: scheme.onPrimaryContainer,
                      onTap: () => _select(_settingsBranch),
                    ),
                  ),
                ),
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
          // The settings branch has no tab; if the window shrinks while it is open,
          // highlight the overview instead of an index the bar does not have.
          selectedIndex: onSettings ? 0 : navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final tab in tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
          ],
        ),
      ),
    );
  }
}
