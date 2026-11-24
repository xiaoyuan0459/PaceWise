import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/analytics.dart';
import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/data/races.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;

class RacesPage extends ConsumerWidget {
  const RacesPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    RacePlan? existing,
  }) async {
    final notifier = ref.read(racePlansProvider.notifier);
    final result = await showModalBottomSheet<RacePlan>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RaceFormSheet(existing: existing),
    );
    if (result == null || !context.mounted) return;
    await notifier.upsert(result);
    if (!context.mounted) return;
    _toast(context, AppLocalizations.of(context).raceSaved);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RacePlan race,
  ) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(racePlansProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.raceDeleteTitle),
        content: Text(l10n.raceDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await notifier.remove(race.id);
    if (!context.mounted) return;
    _toast(context, l10n.raceDeleted);
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final races = ref.watch(racePlansProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(l10n.navRaces),
          actions: [
            IconButton(
              tooltip: l10n.raceAdd,
              icon: const Icon(Icons.add),
              onPressed: () => _openForm(context, ref),
            ),
            const SizedBox(width: 4),
          ],
        ),
        races.when(
          data: (plans) {
            if (plans.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyRaces(onAdd: () => _openForm(context, ref)),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final race = plans[index];
                  final previousEnded = index > 0 && plans[index - 1].ended;
                  final showHeader = index == 0 || previousEnded != race.ended;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeader && race.ended) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 0 : 20,
                            bottom: 8,
                          ),
                          child: Text(
                            l10n.raceEnded,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RaceCard(
                          race: race,
                          onEdit: () => _openForm(context, ref, existing: race),
                          onDelete: () => _delete(context, ref, race),
                          onReview: () => showDialog<void>(
                            context: context,
                            builder: (_) => RaceReviewDialog(race: race),
                          ),
                        ),
                      ),
                    ],
                  );
                }, childCount: plans.length),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyRaces(onAdd: () => _openForm(context, ref)),
          ),
        ),
      ],
    );
  }
}

class _EmptyRaces extends StatelessWidget {
  const _EmptyRaces({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.raceEmpty, style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.raceAdd),
          ),
        ],
      ),
    );
  }
}

class _RaceCard extends StatelessWidget {
  const _RaceCard({
    required this.race,
    required this.onEdit,
    required this.onDelete,
    required this.onReview,
  });

  final RacePlan race;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        race.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        race.dateIso,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RaceStatus(race: race),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _RaceInfo(
                  icon: Icons.route,
                  label: '${formatRaceDistance(race.distanceKm)} km',
                ),
                _RaceInfo(
                  icon: Icons.speed,
                  label: '${race.targetPaceLabel} /km',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (race.ended)
                  TextButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(l10n.raceReview),
                  ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.edit),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RaceStatus extends StatelessWidget {
  const _RaceStatus({required this.race});

  final RacePlan race;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ended = race.ended;
    final color = ended
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    final label = ended
        ? l10n.raceEnded
        : race.daysLeft == 0
        ? l10n.raceToday
        : l10n.raceDaysLeft(race.daysLeft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RaceInfo extends StatelessWidget {
  const _RaceInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}

/// 新增 / 编辑赛事计划的底部表单。
class RaceFormSheet extends StatefulWidget {
  const RaceFormSheet({this.existing, super.key});

  final RacePlan? existing;

  @override
  State<RaceFormSheet> createState() => _RaceFormSheetState();
}

class _RaceFormSheetState extends State<RaceFormSheet> {
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _paceController = TextEditingController();
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.name ?? '';
    _distanceController.text = existing == null
        ? ''
        : _distanceText(existing.distanceKm);
    _paceController.text = existing?.targetPaceLabel ?? '';
    _date = existing?.date ?? dateOnly(DateTime.now());
    for (final controller in [
      _nameController,
      _distanceController,
      _paceController,
    ]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _distanceController.dispose();
    _paceController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String _distanceText(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  bool get _canSubmit {
    final name = _nameController.text.trim();
    final distance = double.tryParse(_distanceController.text.trim());
    return name.isNotEmpty &&
        name.length <= 30 &&
        distance != null &&
        distance >= .1 &&
        distance <= 100 &&
        parsePace(_paceController.text) != null;
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final initial = _date.isBefore(today) ? today : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _date = dateOnly(picked));
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final distance = double.parse(_distanceController.text.trim());
    final pace = parsePace(_paceController.text);
    if (name.isEmpty || distance < .1 || distance > 100 || pace == null) {
      return;
    }
    final plan = RacePlan(
      id: widget.existing?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      date: _date,
      distanceKm: distance,
      targetPaceSeconds: pace,
    );
    Navigator.of(context).pop(plan);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final distanceText = _distanceController.text.trim();
    final distanceValue = double.tryParse(distanceText);
    final distanceError =
        distanceText.isEmpty ||
            (distanceValue != null &&
                distanceValue >= .1 &&
                distanceValue <= 100)
        ? null
        : l10n.raceDistanceInvalid;
    final paceText = _paceController.text.trim();
    final paceError = paceText.isEmpty || parsePace(paceText) != null
        ? null
        : l10n.racePaceInvalid;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? l10n.raceNewTitle
                              : l10n.raceEditTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.close,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    maxLength: 30,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.raceName,
                      hintText: l10n.raceNameHint,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.raceDistance,
                      hintText: l10n.raceDistanceHint,
                      suffixText: 'km',
                      errorText: distanceError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paceController,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.raceTargetPace,
                      hintText: l10n.racePaceHint,
                      suffixText: '/km',
                      errorText: paceError,
                    ),
                    onSubmitted: (_) {
                      if (_canSubmit) _submit();
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l10n.raceDate),
                      child: Row(
                        children: [
                          Text(formatIsoDate(_date)),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 赛后复盘：目标配速 vs 比赛当天的实际配速。
class RaceReviewDialog extends ConsumerWidget {
  const RaceReviewDialog({required this.race, super.key});

  final RacePlan race;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final daysSince = dateOnly(DateTime.now()).difference(race.date).inDays;
    final windowDays = math.max(2, daysSince + 1);
    final pacePoints =
        ref
            .watch(metricTrendProvider((metric: 'pace', days: windowDays)))
            .asData
            ?.value ??
        const [];
    final distancePoints =
        ref
            .watch(metricTrendProvider((metric: 'distance', days: windowDays)))
            .asData
            ?.value ??
        const [];
    final actualPace = _valueOn(pacePoints, race.dateIso);
    final actualDistance = _valueOn(distancePoints, race.dateIso);

    return AlertDialog(
      title: Text(l10n.raceReviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              race.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              race.dateIso,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _ReviewRow(
              label: l10n.raceReviewTargetPace,
              value: '${race.targetPaceLabel} /km',
            ),
            _ReviewRow(
              label: l10n.raceReviewActualPace,
              value: actualPace == null
                  ? '--'
                  : '${formatPace(actualPace)} /km',
            ),
            _ReviewRow(
              label: l10n.raceReviewActualDistance,
              value: actualDistance == null
                  ? '--'
                  : '${formatKilometers(actualDistance)} km',
            ),
            if (actualPace == null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.raceReviewNoRecord,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                _comparison(l10n, race.targetPaceSeconds, actualPace),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  double? _valueOn(List<rust.TrendPointDto> points, String date) {
    for (final point in points) {
      if (point.date == date) return point.value;
    }
    return null;
  }

  String _comparison(
    AppLocalizations l10n,
    int targetSeconds,
    double actualSeconds,
  ) {
    final diff = actualSeconds - targetSeconds;
    if (diff.abs() < .5) return l10n.raceReviewEven;
    final seconds = diff.abs().round().toString();
    return diff < 0
        ? l10n.raceReviewFaster(seconds)
        : l10n.raceReviewSlower(seconds);
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
