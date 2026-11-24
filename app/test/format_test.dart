import 'package:flutter_test/flutter_test.dart';
import 'package:pacebridge/data/format.dart';

void main() {
  test('formats pace, distance and percent', () {
    expect(formatPace(null), '--');
    expect(formatPace(0), '--');
    expect(formatPace(312), '5:12');
    expect(formatPace(300.4), '5:00');
    expect(formatKilometers(12345), '12.3');
    expect(formatRaceDistance(42.195), '42.195');
    expect(formatRaceDistance(21.1), '21.1');
    expect(formatRaceDistance(10), '10');
    expect(formatPercent(.756), '76%');
    expect(formatPercent(null), '--');
  });

  test('parses pace input', () {
    expect(parsePace('4:30'), 270);
    expect(parsePace(' 5:05 '), 305);
    expect(parsePace('4:3'), isNull);
    expect(parsePace('4:75'), isNull);
    expect(parsePace('abc'), isNull);
    expect(parsePace('0:30'), isNull);
  });

  test('formats dates in the core date format', () {
    expect(formatIsoDate(DateTime(2026, 1, 2)), '2026-01-02');
    expect(formatShortDate(DateTime(2026, 11, 24)), '11/24');
    expect(formatSyncTime(DateTime(2026, 1, 2, 3, 4)), '01-02 03:04');
    expect(formatShortDateTime(DateTime(2026, 11, 24, 7, 5)), '11/24 07:05');
  });

  test('formats workout duration', () {
    expect(formatDuration(null), '--');
    expect(formatDuration(0), '--');
    expect(formatDuration(2700), '45:00');
    expect(formatDuration(3900), '1:05:00');
  });
}
