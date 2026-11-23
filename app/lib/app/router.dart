import 'package:go_router/go_router.dart';
import 'package:pacebridge/app/shell.dart';
import 'package:pacebridge/features/compare/compare_page.dart';
import 'package:pacebridge/features/overview/overview_page.dart';
import 'package:pacebridge/features/races/races_page.dart';
import 'package:pacebridge/features/settings/settings_page.dart';

final appRouter = GoRouter(
  initialLocation: '/overview',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/overview',
          builder: (context, state) => const OverviewPage(),
        ),
        GoRoute(
          path: '/compare',
          builder: (context, state) => const ComparePage(),
        ),
        GoRoute(path: '/races', builder: (context, state) => const RacesPage()),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
