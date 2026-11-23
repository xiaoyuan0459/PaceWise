import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

class RacesPage extends StatelessWidget {
  const RacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(l10n.navRaces)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.raceEmpty,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.raceAdd),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
