import 'package:flutter_test/flutter_test.dart';
import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/data/races.dart';

RacePlan race(String id, String name, int offsetDays) {
  return RacePlan(
    id: id,
    name: name,
    date: dateOnly(DateTime.now()).add(Duration(days: offsetDays)),
    distanceKm: 42.195,
    targetPaceSeconds: 270,
  );
}

void main() {
  test('sorts upcoming races first, then ended newest first', () {
    final sorted = sortRacePlans([
      race('1', 'Past old', -30),
      race('2', 'Upcoming later', 20),
      race('3', 'Past recent', -2),
      race('4', 'Today', 0),
      race('5', 'Upcoming soon', 3),
    ]);
    expect(sorted.map((item) => item.name).toList(), [
      'Today',
      'Upcoming soon',
      'Upcoming later',
      'Past recent',
      'Past old',
    ]);
  });

  test('nearest upcoming race skips ended races', () {
    final nearest = nearestUpcomingRace([
      race('1', 'Past', -1),
      race('2', 'Future', 5),
      race('3', 'Later', 30),
    ]);
    expect(nearest?.name, 'Future');
  });

  test('race json round-trips', () {
    final original = RacePlan(
      id: '1',
      name: 'City',
      date: DateTime(2026, 11, 1),
      distanceKm: 42.195,
      targetPaceSeconds: 270,
    );
    final restored = RacePlan.fromJson(
      original.toJson().cast<String, dynamic>(),
    );
    expect(restored.name, 'City');
    expect(restored.dateIso, '2026-11-01');
    expect(restored.distanceKm, 42.195);
    expect(restored.targetPaceSeconds, 270);
  });
}
