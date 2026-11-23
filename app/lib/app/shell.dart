import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations =
        <({String path, IconData icon, IconData selectedIcon, String label})>[
          (
            path: '/overview',
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: l10n.navOverview,
          ),
          (
            path: '/compare',
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: l10n.navCompare,
          ),
          (
            path: '/races',
            icon: Icons.flag_outlined,
            selectedIcon: Icons.flag,
            label: l10n.navRaces,
          ),
          (
            path: '/settings',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l10n.navSettings,
          ),
        ];
    final selected = destinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );
    final index = selected < 0 ? 0 : selected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final body = SafeArea(child: child);
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (value) =>
                      context.go(destinations[value].path),
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) =>
                context.go(destinations[value].path),
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
