import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/analytics.dart';
import 'package:pacebridge/data/deltas.dart';
import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/data/races.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;
import 'package:pacebridge/widgets/charts.dart';
import 'package:pacebridge/widgets/metric_widgets.dart';

class ComparePage extends ConsumerStatefulWidget {
  const ComparePage({super.key});

  @override
  ConsumerState<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends ConsumerState<ComparePage> {
  int _windowDays = 90;
  bool _insightExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = ref.watch(metricSummaryProvider(_windowDays)).asData?.value;
    final powerTrend = _periodTrend('power');
    final distanceTrend = _trend('distance');
    final paceTrend = _periodTrend('pace');
    final loadDays =
        ref.watch(loadDistributionProvider(_windowDays)).asData?.value ??
        const [];
    final recoveryDays =
        ref.watch(recoveryDaysProvider(_windowDays)).asData?.value ?? const [];
    final races = ref.watch(racePlansProvider).asData?.value ?? const [];
    final upcomingRace = nearestUpcomingRace(races);
    final insight = _buildInsight(l10n, summary, upcomingRace);
    final incomplete = _isIncomplete(distanceTrend);

    final cards = <Widget>[
      _MetricCard(
        title: l10n.metricPower,
        info: l10n.metricPowerInfo,
        value: summary?.currentPower == null
            ? '--'
            : formatDecimal(summary!.currentPower),
        unit: '',
        delta: higherIsBetter(
          l10n,
          summary?.currentPower,
          summary?.previousPower,
        ),
        chart: powerTrend.current.isEmpty
            ? const ChartEmpty()
            : TrendLineChart(
                points: _linePoints(powerTrend.current),
                previousPoints: _linePoints(powerTrend.previous),
                valueFormatter: (value) => formatDecimal(value),
              ),
        extra: _SeriesLegend(
          currentColor: theme.colorScheme.primary,
          previousColor: theme.colorScheme.primary.withValues(alpha: .45),
        ),
        footer: _periodFooter(
          l10n,
          summary?.currentPower == null
              ? '--'
              : formatDecimal(summary!.currentPower),
          summary?.previousPower == null
              ? '--'
              : formatDecimal(summary!.previousPower),
        ),
      ),
      _MetricCard(
        title: l10n.metricDistance,
        info: l10n.metricDistanceInfo,
        value: formatKilometers(summary?.distanceMeters),
        unit: 'km',
        delta: moreIsBetter(
          l10n,
          summary?.distanceMeters,
          summary?.previousDistanceMeters,
        ),
        chart: distanceTrend.isEmpty
            ? const ChartEmpty()
            : TrendBarChart(
                points: _barPoints(distanceTrend, scale: .001),
                valueFormatter: (value) => formatDecimal(value),
              ),
        footer: _periodFooter(
          l10n,
          formatKilometers(summary?.distanceMeters),
          formatKilometers(summary?.previousDistanceMeters),
        ),
      ),
      _MetricCard(
        title: l10n.metricPace,
        info: l10n.metricPaceInfo,
        value: formatPace(summary?.avgPaceSecPerKm),
        unit: '/km',
        delta: lowerIsBetter(
          l10n,
          summary?.avgPaceSecPerKm,
          summary?.previousAvgPaceSecPerKm,
        ),
        chart: paceTrend.current.isEmpty
            ? const ChartEmpty()
            : TrendLineChart(
                points: _linePoints(paceTrend.current),
                previousPoints: _linePoints(paceTrend.previous),
                color: theme.colorScheme.tertiary,
                valueFormatter: (value) => formatPace(value),
              ),
        extra: _SeriesLegend(
          currentColor: theme.colorScheme.tertiary,
          previousColor: theme.colorScheme.tertiary.withValues(alpha: .45),
        ),
        footer: _periodFooter(
          l10n,
          formatPace(summary?.avgPaceSecPerKm),
          formatPace(summary?.previousAvgPaceSecPerKm),
        ),
      ),
      _MetricCard(
        title: l10n.metricLoad,
        info: l10n.metricLoadInfo,
        value: summary?.trainingLoadScore == null
            ? '--'
            : '${summary!.trainingLoadScore}',
        unit: '',
        delta: neutralChange(
          l10n,
          summary?.trainingLoadScore,
          summary?.previousTrainingLoadScore,
        ),
        chart: loadDays.every((day) => day.displayLoad == null)
            ? const ChartEmpty()
            : TrendBarChart(
                points: _loadPoints(context, loadDays),
                valueFormatter: (value) => value.round().toString(),
              ),
        footer: '${l10n.weeklyAverage}: ${summary?.trainingLoadScore ?? '--'}',
        extra: _LoadLegend(
          easy: l10n.loadEasy,
          moderate: l10n.loadModerate,
          hard: l10n.loadHard,
        ),
      ),
      _MetricCard(
        title: l10n.metricRecovery,
        info: l10n.metricRecoveryInfo,
        value: formatPercent(summary?.recoveryRatio),
        unit: '',
        delta: percentPoints(
          l10n,
          summary?.recoveryRatio,
          summary?.previousRecoveryRatio,
        ),
        chart: Center(
          child: RecoveryRing(
            ratio: summary?.recoveryRatio,
            centerLabel: formatPercent(summary?.recoveryRatio),
            caption: l10n.fullyRecovered,
          ),
        ),
        footer: _recoveryFooter(l10n, recoveryDays),
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(l10n.navCompare)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                    setState(() {
                      _windowDays = selection.first;
                      _insightExpanded = false;
                    });
                  },
                ),
              ),
              if (incomplete) ...[
                const SizedBox(height: 12),
                Center(
                  child: DeltaChip(
                    label: l10n.dataIncomplete,
                    tone: DeltaTone.neutral,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _InsightCard(
                sentences: insight,
                expanded: _insightExpanded,
                onToggle: () =>
                    setState(() => _insightExpanded = !_insightExpanded),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final width = wide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final card in cards)
                        SizedBox(width: width, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.straighten,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.calibratedUnits,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  List<rust.TrendPointDto> _trend(String metric) {
    return ref
            .watch(metricTrendProvider((metric: metric, days: _windowDays)))
            .asData
            ?.value ??
        const [];
  }

  /// 一次取两期数据，按当前周期起点拆成本期和上期，用于折线对比。
  ({List<rust.TrendPointDto> current, List<rust.TrendPointDto> previous})
  _periodTrend(String metric) {
    final points =
        ref
            .watch(metricTrendProvider((metric: metric, days: _windowDays * 2)))
            .asData
            ?.value ??
        const <rust.TrendPointDto>[];
    final windowStart = dateOnly(DateTime.now())
        .subtract(Duration(days: _windowDays - 1));
    final current = <rust.TrendPointDto>[];
    final previous = <rust.TrendPointDto>[];
    for (final point in points) {
      if (DateTime.parse(point.date).isBefore(windowStart)) {
        previous.add(point);
      } else {
        current.add(point);
      }
    }
    return (current: current, previous: previous);
  }

  List<ChartPoint> _linePoints(List<rust.TrendPointDto> points) {
    return [
      for (final point in points)
        ChartPoint(date: DateTime.parse(point.date), value: point.value),
    ];
  }

  List<ChartPoint> _barPoints(
    List<rust.TrendPointDto> points, {
    double scale = 1,
  }) {
    return [
      for (final point in points)
        ChartPoint(
          date: DateTime.parse(point.date),
          value: point.value * scale,
        ),
    ];
  }

  List<ChartPoint> _loadPoints(
    BuildContext context,
    List<rust.LoadDayDto> days,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final day in days)
        if (day.displayLoad != null)
          ChartPoint(
            date: DateTime.parse(day.date),
            value: day.displayLoad!.toDouble(),
            color: day.displayLoad! <= 200
                ? scheme.tertiary
                : day.displayLoad! <= 500
                ? scheme.secondary
                : scheme.primary,
          ),
    ];
  }

  String _periodFooter(AppLocalizations l10n, String current, String previous) {
    return '${l10n.thisPeriod} $current · ${l10n.previousPeriod} $previous';
  }

  String _recoveryFooter(
    AppLocalizations l10n,
    List<rust.RecoveryDayDto> days,
  ) {
    final measured = days.where((day) => day.fullyRecovered != null).length;
    final recovered = days.where((day) => day.fullyRecovered == true).length;
    if (measured == 0) return l10n.metricNoData;
    return '${l10n.fullyRecovered}: $recovered/$measured';
  }

  bool _isIncomplete(List<rust.TrendPointDto> points) {
    if (points.isEmpty) return false;
    final windowStart = dateOnly(DateTime.now())
        .subtract(Duration(days: _windowDays - 1));
    final earliest = DateTime.parse(points.first.date);
    return earliest.difference(windowStart).inDays > 7;
  }

  List<String> _buildInsight(
    AppLocalizations l10n,
    rust.MetricSummaryDto? summary,
    RacePlan? upcomingRace,
  ) {
    final sentences = <String>[];
    if (summary == null || summary.workouts == 0) {
      sentences.add(l10n.insightEmpty);
    } else {
      if (summary.currentPower != null) {
        final change = higherIsBetter(
          l10n,
          summary.currentPower,
          summary.previousPower,
        );
        sentences.add(
          l10n.insightPower(
            formatDecimal(summary.currentPower),
            change?.label ?? l10n.deltaUnknown,
          ),
        );
      }
      final distanceChange = moreIsBetter(
        l10n,
        summary.distanceMeters,
        summary.previousDistanceMeters,
      );
      sentences.add(
        l10n.insightDistance(
          formatKilometers(summary.distanceMeters),
          distanceChange?.label ?? l10n.deltaUnknown,
        ),
      );
      if (summary.avgPaceSecPerKm != null) {
        final paceChange = lowerIsBetter(
          l10n,
          summary.avgPaceSecPerKm,
          summary.previousAvgPaceSecPerKm,
        );
        sentences.add(
          l10n.insightPace(
            formatPace(summary.avgPaceSecPerKm),
            paceChange?.label ?? l10n.deltaUnknown,
          ),
        );
      }
    }
    if (upcomingRace != null) {
      sentences.add(
        l10n.insightRace(
          upcomingRace.daysLeft,
          upcomingRace.name,
          upcomingRace.targetPaceLabel,
        ),
      );
    } else {
      sentences.add(l10n.insightNoRace);
    }
    return sentences;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.info,
    required this.value,
    required this.unit,
    required this.delta,
    required this.chart,
    required this.footer,
    this.extra,
  });

  final String title;
  final String info;
  final String value;
  final String unit;
  final DeltaInfo? delta;
  final Widget chart;
  final String footer;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                MetricInfoButton(title: title, body: info),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              DeltaChip(label: delta!.label, tone: delta!.tone),
            const SizedBox(height: 12),
            chart,
            if (extra != null) ...[const SizedBox(height: 8), extra!],
            const SizedBox(height: 8),
            Text(
              footer,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.sentences,
    required this.expanded,
    required this.onToggle,
  });

  final List<String> sentences;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.insightTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (sentences.length > 1)
                  TextButton(
                    onPressed: onToggle,
                    child: Text(expanded ? l10n.collapse : l10n.expand),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Text(
                sentences.join(' '),
                maxLines: expanded ? null : 2,
                overflow: expanded ? null : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesLegend extends StatelessWidget {
  const _SeriesLegend({
    required this.currentColor,
    required this.previousColor,
  });

  final Color currentColor;
  final Color previousColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegendDot(color: currentColor, label: l10n.thisPeriod),
        _LegendDot(color: previousColor, label: l10n.previousPeriod),
      ],
    );
  }
}

class _LoadLegend extends StatelessWidget {
  const _LoadLegend({
    required this.easy,
    required this.moderate,
    required this.hard,
  });

  final String easy;
  final String moderate;
  final String hard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegendDot(color: scheme.tertiary, label: easy),
        _LegendDot(color: scheme.secondary, label: moderate),
        _LegendDot(color: scheme.primary, label: hard),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
