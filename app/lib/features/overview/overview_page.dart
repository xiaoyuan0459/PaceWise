import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/analytics.dart';
import 'package:pacebridge/data/auth.dart';
import 'package:pacebridge/data/deltas.dart';
import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/data/prefs.dart';
import 'package:pacebridge/data/sync.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;
import 'package:pacebridge/widgets/charts.dart';
import 'package:pacebridge/widgets/metric_widgets.dart';

class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key});

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrivacyNoticeIfNeeded();
    });
  }

  Future<void> _showPrivacyNoticeIfNeeded() async {
    final shouldShow = await PrivacyNoticeStore.shouldShow();
    if (!mounted || !shouldShow) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_outline),
        title: Text(l10n.privacyTitle),
        content: Text(l10n.privacyBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.privacyOk),
          ),
        ],
      ),
    );
    await PrivacyNoticeStore.markSeen();
  }

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context);
    final authorized =
        ref.read(authStatusProvider).asData?.value?.authorized ?? false;
    if (!authorized) {
      _toast(l10n.syncNotAuthorized);
      return;
    }
    setState(() => _syncing = true);
    try {
      final outcome = await performSync();
      if (!mounted) return;
      ref.invalidate(syncStateProvider);
      ref.invalidate(authStatusProvider);
      invalidateAnalytics(ref);
      _toast(
        outcome.success
            ? '${l10n.syncDone} · ${outcome.records}'
            : '${l10n.syncFailed}: ${outcome.message ?? ''}',
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(metricSummaryProvider(30)).asData?.value;
    final auth = ref.watch(authStatusProvider).asData?.value;
    final powerTrend =
        ref
            .watch(metricTrendProvider((metric: 'power', days: 30)))
            .asData
            ?.value ??
        const [];
    final hasData = summary != null && summary.workouts > 0;
    final recentWorkouts =
        ref.watch(recentWorkoutsProvider(3)).asData?.value ?? const [];

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(l10n.navOverview),
          actions: [
            IconButton(
              tooltip: l10n.syncNow,
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
            ),
            const SizedBox(width: 4),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MetricsCard(summary: summary),
              if (!hasData) ...[
                const SizedBox(height: 16),
                _EmptyCard(
                  authorized: auth?.authorized ?? false,
                  onConnect: () => context.go('/settings'),
                  onSync: _syncing ? null : _sync,
                ),
              ],
              if (hasData) ...[
                const SizedBox(height: 16),
                _PowerTrendCard(points: powerTrend),
                if (recentWorkouts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RecentTrainingCard(workouts: recentWorkouts),
                ],
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.compare_arrows),
                    title: Text(l10n.viewComparison),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/compare'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.localOnly,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.summary});

  final rust.MetricSummaryDto? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = this.summary;

    final powerDelta = higherIsBetter(
      l10n,
      summary?.currentPower,
      summary?.previousPower,
    );
    final distanceDelta = moreIsBetter(
      l10n,
      summary?.distanceMeters,
      summary?.previousDistanceMeters,
    );
    final paceDelta = lowerIsBetter(
      l10n,
      summary?.avgPaceSecPerKm,
      summary?.previousAvgPaceSecPerKm,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.currentPower,
                  value: summary?.currentPower == null
                      ? '--'
                      : formatDecimal(summary!.currentPower),
                  unit: '',
                  delta: powerDelta,
                ),
              ),
              const VerticalDivider(width: 12),
              Expanded(
                child: _MetricTile(
                  label: l10n.distance30d,
                  value: formatKilometers(summary?.distanceMeters),
                  unit: 'km',
                  delta: distanceDelta,
                ),
              ),
              const VerticalDivider(width: 12),
              Expanded(
                child: _MetricTile(
                  label: l10n.averagePace,
                  value: formatPace(summary?.avgPaceSecPerKm),
                  unit: '/km',
                  delta: paceDelta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
  });

  final String label;
  final String value;
  final String unit;
  final ({String label, DeltaTone tone})? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (delta == null)
          Text(
            '—',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          DeltaChip(label: delta!.label, tone: delta!.tone),
      ],
    );
  }
}

class _PowerTrendCard extends StatelessWidget {
  const _PowerTrendCard({required this.points});

  final List<rust.TrendPointDto> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chartPoints = [
      for (final point in points)
        ChartPoint(date: DateTime.parse(point.date), value: point.value),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.powerTrend, style: theme.textTheme.titleMedium),
                      Text(
                        l10n.last30Days,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (points.isNotEmpty && points.length < 7)
                  DeltaChip(
                    label: l10n.dataIncomplete,
                    tone: DeltaTone.neutral,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (chartPoints.isEmpty)
              const ChartEmpty()
            else
              TrendLineChart(
                points: chartPoints,
                valueFormatter: (value) => formatDecimal(value),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTrainingCard extends StatelessWidget {
  const _RecentTrainingCard({required this.workouts});

  final List<rust.WorkoutSummaryDto> workouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.history, color: theme.colorScheme.primary),
            title: Text(l10n.recentTraining),
            subtitle: Text(l10n.recentTrainingNote),
          ),
          const Divider(height: 1),
          for (final workout in workouts) _workoutTile(context, theme, workout),
        ],
      ),
    );
  }

  Widget _workoutTile(
    BuildContext context,
    ThemeData theme,
    rust.WorkoutSummaryDto workout,
  ) {
    final l10n = AppLocalizations.of(context);
    final distance = workout.distanceMeters;
    final pace = workout.avgPaceSecPerKm;
    final hasDistance = distance != null && distance > 0;
    final start = DateTime.fromMillisecondsSinceEpoch(workout.startTimeMs);
    return ListTile(
      dense: true,
      leading: Icon(_workoutTypeIcon(workout.workoutType), size: 20),
      title: Text(
        _workoutTypeLabel(l10n, workout),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formatShortDateTime(start)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            hasDistance
                ? '${formatKilometers(distance)} km'
                : formatDuration(workout.durationSeconds),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            pace != null
                ? '${formatPace(pace)} /km'
                : hasDistance
                ? formatDuration(workout.durationSeconds)
                : '',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _workoutTypeLabel(
  AppLocalizations l10n,
  rust.WorkoutSummaryDto workout,
) {
  final custom = workout.customLabel?.trim();
  if (custom != null && custom.isNotEmpty) return custom;
  return switch (workout.workoutType) {
    'run' || 'running' => l10n.workoutTypeRun,
    'trail_running' || 'trail_run' => l10n.workoutTypeTrailRun,
    'treadmill' => l10n.workoutTypeTreadmill,
    'walk' || 'walking' => l10n.workoutTypeWalk,
    'ride' || 'cycling' || 'bike' => l10n.workoutTypeRide,
    'swim' || 'swimming' => l10n.workoutTypeSwim,
    'strength' || 'strength_training' => l10n.workoutTypeStrength,
    'hike' || 'hiking' => l10n.workoutTypeHike,
    _ => workout.workoutType,
  };
}

IconData _workoutTypeIcon(String type) => switch (type) {
  'trail_running' || 'trail_run' || 'hike' || 'hiking' => Icons.terrain,
  'walk' || 'walking' => Icons.directions_walk,
  'ride' || 'cycling' || 'bike' => Icons.directions_bike,
  'swim' || 'swimming' => Icons.pool,
  'strength' || 'strength_training' => Icons.fitness_center,
  _ => Icons.directions_run,
};

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.authorized,
    required this.onConnect,
    required this.onSync,
  });

  final bool authorized;
  final VoidCallback onConnect;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.directions_run,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(l10n.noTrainingData, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.localOnly,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: authorized ? onSync : onConnect,
              icon: Icon(authorized ? Icons.sync : Icons.link),
              label: Text(authorized ? l10n.syncNow : l10n.connectZepp),
            ),
          ],
        ),
      ),
    );
  }
}
