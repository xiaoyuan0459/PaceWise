import 'package:pacebridge/data/prefs.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;

/// 一次同步的结果，页面只负责翻译和展示。
class SyncOutcome {
  const SyncOutcome({
    required this.success,
    required this.days,
    required this.records,
    this.message,
  });

  final bool success;
  final int days;
  final int records;
  final String? message;
}

/// 首次同步回填 365 天，之后只取近 180 天的增量。
Future<SyncOutcome> performSync() async {
  final lastSync = await SyncPrefs.lastSync();
  final days = lastSync == null ? 365 : 180;
  try {
    final report = await rust.syncOfficial(days: days);
    if (report.success) {
      await SyncPrefs.recordNow();
    }
    return SyncOutcome(
      success: report.success,
      days: days,
      records: report.recordsWritten.toInt(),
      message: report.message,
    );
  } catch (error) {
    return SyncOutcome(
      success: false,
      days: days,
      records: 0,
      message: '$error',
    );
  }
}
