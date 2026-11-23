import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  int _windowDays = 90;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(l10n.navCompare)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Center(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 30, label: Text(l10n.window30)),
                    ButtonSegment(value: 90, label: Text(l10n.window90)),
                    ButtonSegment(value: 180, label: Text(l10n.window180)),
                  ],
                  selected: {_windowDays},
                  onSelectionChanged: (selection) {
                    setState(() => _windowDays = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.analysisReady,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.waitingForBridge,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
