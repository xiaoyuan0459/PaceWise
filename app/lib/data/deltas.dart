import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/widgets/metric_widgets.dart';

typedef DeltaInfo = ({String label, DeltaTone tone});

/// 数值越高越好：跑力、恢复占比。
DeltaInfo? higherIsBetter(
  AppLocalizations l10n,
  num? current,
  num? previous, {
  int digits = 1,
  double epsilon = .05,
  String suffix = '',
}) {
  if (current == null || previous == null) return null;
  final delta = current - previous;
  if (delta.abs() <= epsilon) {
    return (label: l10n.deltaFlat, tone: DeltaTone.neutral);
  }
  final value = '${formatDecimal(delta.abs(), digits: digits)}$suffix';
  return delta > 0
      ? (label: l10n.deltaUp(value), tone: DeltaTone.positive)
      : (label: l10n.deltaDown(value), tone: DeltaTone.negative);
}

/// 数量多少：跑量。
DeltaInfo? moreIsBetter(
  AppLocalizations l10n,
  num? current,
  num? previous, {
  int digits = 1,
  double epsilon = .05,
}) {
  if (current == null || previous == null) return null;
  final delta = current - previous;
  if (delta.abs() <= epsilon) {
    return (label: l10n.deltaFlat, tone: DeltaTone.neutral);
  }
  final value = formatDecimal(delta.abs(), digits: digits);
  return delta > 0
      ? (label: l10n.deltaMore(value), tone: DeltaTone.positive)
      : (label: l10n.deltaLess(value), tone: DeltaTone.negative);
}

/// 数值越低越好：平均配速。
DeltaInfo? lowerIsBetter(
  AppLocalizations l10n,
  num? current,
  num? previous, {
  double epsilon = .5,
}) {
  if (current == null || previous == null) return null;
  final improvement = previous - current;
  if (improvement.abs() < epsilon) {
    return (label: l10n.deltaFlat, tone: DeltaTone.neutral);
  }
  final seconds = improvement.abs().round().toString();
  return improvement > 0
      ? (label: l10n.deltaFaster(seconds), tone: DeltaTone.positive)
      : (label: l10n.deltaSlower(seconds), tone: DeltaTone.negative);
}

/// 只报变化，不判断好坏：训练负荷。
DeltaInfo? neutralChange(
  AppLocalizations l10n,
  num? current,
  num? previous, {
  int digits = 0,
  double epsilon = .5,
}) {
  if (current == null || previous == null) return null;
  final delta = current - previous;
  if (delta.abs() < epsilon) {
    return (label: l10n.deltaFlat, tone: DeltaTone.neutral);
  }
  final value = formatDecimal(delta.abs(), digits: digits);
  return delta > 0
      ? (label: l10n.deltaMore(value), tone: DeltaTone.neutral)
      : (label: l10n.deltaLess(value), tone: DeltaTone.neutral);
}

/// 0–1 的占比按百分点变化：恢复状态。
DeltaInfo? percentPoints(
  AppLocalizations l10n,
  num? current,
  num? previous, {
  double epsilon = .005,
}) {
  if (current == null || previous == null) return null;
  final delta = (current - previous) * 100;
  if (delta.abs() < epsilon * 100) {
    return (label: l10n.deltaFlat, tone: DeltaTone.neutral);
  }
  final value = '${delta.abs().round()}%';
  return delta > 0
      ? (label: l10n.deltaUp(value), tone: DeltaTone.positive)
      : (label: l10n.deltaDown(value), tone: DeltaTone.negative);
}
