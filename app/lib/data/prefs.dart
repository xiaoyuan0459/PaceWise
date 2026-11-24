import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 首次进入概览时的隐私提示只显示一次。
class PrivacyNoticeStore {
  static const _seenKey = 'privacy_notice_seen_v1';

  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_seenKey) ?? false);
    } catch (_) {
      // 插件不可用（widget test）时不弹窗，别让提示挡住页面。
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {}
  }
}

/// 上次成功同步的时间；首次同步要用更长的窗口。
class SyncState {
  const SyncState({this.lastSync});

  final DateTime? lastSync;

  bool get hasSynced => lastSync != null;
}

class SyncPrefs {
  static const _lastSyncKey = 'last_sync_epoch_ms';

  static Future<DateTime?> lastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_lastSyncKey);
      if (millis == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  static Future<void> recordNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}

final syncStateProvider = FutureProvider<SyncState>((ref) async {
  final lastSync = await SyncPrefs.lastSync();
  return SyncState(lastSync: lastSync);
});
