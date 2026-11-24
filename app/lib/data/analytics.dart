import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pacebridge/data/bridge.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;

/// 当前窗口的五个核心指标 + 上一周期对照。
final metricSummaryProvider =
    FutureProvider.family<rust.MetricSummaryDto?, int>((ref, days) async {
      return bridgeCall(() => rust.metricSummary(windowDays: days));
    });

typedef TrendQuery = ({String metric, int days});

/// 单指标逐日趋势：`power` / `distance` / `pace` / `load` / `recovery`。
final metricTrendProvider =
    FutureProvider.family<List<rust.TrendPointDto>, TrendQuery>((
      ref,
      query,
    ) async {
      return bridgeCall(
            () =>
                rust.metricTrend(metric: query.metric, windowDays: query.days),
          ) ??
          const [];
    });

/// 每日训练负荷，做堆叠柱状图用。
final loadDistributionProvider =
    FutureProvider.family<List<rust.LoadDayDto>, int>((ref, days) async {
      return bridgeCall(() => rust.loadDistribution(windowDays: days)) ??
          const [];
    });

/// 每日恢复分。
final recoveryDaysProvider =
    FutureProvider.family<List<rust.RecoveryDayDto>, int>((ref, days) async {
      return bridgeCall(() => rust.recoveryDays(windowDays: days)) ?? const [];
    });

/// 最近训练明细，开始时间倒序。
final recentWorkoutsProvider =
    FutureProvider.family<List<rust.WorkoutSummaryDto>, int>((
      ref,
      limit,
    ) async {
      return bridgeCall(() => rust.recentWorkouts(limit: limit)) ?? const [];
    });

/// 同步完成或重新授权后让所有分析查询重新取数。
void invalidateAnalytics(WidgetRef ref) {
  ref.invalidate(metricSummaryProvider);
  ref.invalidate(metricTrendProvider);
  ref.invalidate(loadDistributionProvider);
  ref.invalidate(recoveryDaysProvider);
  ref.invalidate(recentWorkoutsProvider);
}
