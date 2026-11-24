import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pacebridge/data/format.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户手动维护的赛事计划。字段和 PRD 的赛事计划保持一致：
/// 名称、日期、距离、目标配速；配速在内存里用秒/公里保存。
class RacePlan {
  const RacePlan({
    required this.id,
    required this.name,
    required this.date,
    required this.distanceKm,
    required this.targetPaceSeconds,
  });

  final String id;
  final String name;
  final DateTime date;
  final double distanceKm;
  final int targetPaceSeconds;

  String get dateIso => formatIsoDate(date);

  String get targetPaceLabel => formatPace(targetPaceSeconds);

  bool get ended => date.isBefore(dateOnly(DateTime.now()));

  /// 距离比赛还有几天；今天比赛是 0。
  int get daysLeft => date.difference(dateOnly(DateTime.now())).inDays;

  RacePlan copyWith({
    String? name,
    DateTime? date,
    double? distanceKm,
    int? targetPaceSeconds,
  }) {
    return RacePlan(
      id: id,
      name: name ?? this.name,
      date: date ?? this.date,
      distanceKm: distanceKm ?? this.distanceKm,
      targetPaceSeconds: targetPaceSeconds ?? this.targetPaceSeconds,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'date': dateIso,
    'distanceKm': distanceKm,
    'targetPaceSeconds': targetPaceSeconds,
  };

  factory RacePlan.fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.tryParse('${json['date']}');
    return RacePlan(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      date: dateOnly(parsedDate ?? DateTime.now()),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      targetPaceSeconds: (json['targetPaceSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 进行中的比赛按日期升序在前，已结束的比赛按日期倒序在后。
List<RacePlan> sortRacePlans(Iterable<RacePlan> races) {
  final today = dateOnly(DateTime.now());
  final sorted = races.toList();
  sorted.sort((left, right) {
    final leftEnded = left.date.isBefore(today);
    final rightEnded = right.date.isBefore(today);
    if (leftEnded != rightEnded) return leftEnded ? 1 : -1;
    final byDate = leftEnded
        ? right.date.compareTo(left.date)
        : left.date.compareTo(right.date);
    return byDate != 0 ? byDate : left.name.compareTo(right.name);
  });
  return sorted;
}

/// 最近一场还没结束的比赛，给对比页的解读用。
RacePlan? nearestUpcomingRace(Iterable<RacePlan> races) {
  final today = dateOnly(DateTime.now());
  final upcoming = races.where((race) => !race.date.isBefore(today)).toList()
    ..sort((left, right) => left.date.compareTo(right.date));
  return upcoming.isEmpty ? null : upcoming.first;
}

class RacePlanStore {
  static const _storageKey = 'race_plans_v1';

  Future<List<RacePlan>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RacePlan.fromJson)
          .where(
            (race) =>
                race.name.isNotEmpty &&
                race.distanceKm > 0 &&
                race.targetPaceSeconds > 0,
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<RacePlan> races) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(races.map((race) => race.toJson()).toList()),
      );
    } catch (_) {
      // 本地缓存不可用时仍保留当前内存状态，不把保存失败抛到界面。
    }
  }
}

class RacePlansNotifier extends AsyncNotifier<List<RacePlan>> {
  final RacePlanStore _store = RacePlanStore();

  @override
  Future<List<RacePlan>> build() async => sortRacePlans(await _store.load());

  Future<void> upsert(RacePlan race) async {
    final current = state.asData?.value ?? const <RacePlan>[];
    final next = sortRacePlans([
      ...current.where((item) => item.id != race.id),
      race,
    ]);
    state = AsyncData(next);
    await _store.save(next);
  }

  Future<void> remove(String id) async {
    final current = state.asData?.value ?? const <RacePlan>[];
    final next = current.where((race) => race.id != id).toList();
    state = AsyncData(next);
    await _store.save(next);
  }
}

final racePlansProvider =
    AsyncNotifierProvider<RacePlansNotifier, List<RacePlan>>(
      RacePlansNotifier.new,
    );
