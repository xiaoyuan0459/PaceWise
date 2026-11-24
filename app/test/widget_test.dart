import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/analytics.dart';
import 'package:pacebridge/data/format.dart';
import 'package:pacebridge/features/compare/compare_page.dart';
import 'package:pacebridge/features/overview/overview_page.dart';
import 'package:pacebridge/features/races/races_page.dart';
import 'package:pacebridge/features/settings/settings_page.dart';
import 'package:pacebridge/l10n/app_localizations.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(child: _app(child, locale: locale));
}

Widget wrapAnalytics(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      metricSummaryProvider.overrideWith((ref, days) async => fakeSummary()),
      metricTrendProvider.overrideWith((ref, query) async {
        return switch (query.metric) {
          'power' => fakeTrend(48, .2),
          'distance' => fakeTrend(3000, 100),
          'pace' => fakeTrend(320, -.3),
          _ => const <rust.TrendPointDto>[],
        };
      }),
      loadDistributionProvider.overrideWith(
        (ref, days) async => [
          for (var index = 0; index < 30; index++)
            rust.LoadDayDto(
              date: fakeDay(29 - index),
              trimp: 30 + index.toDouble(),
              displayLoad: 120 + index * 10,
            ),
        ],
      ),
      recoveryDaysProvider.overrideWith(
        (ref, days) async => [
          for (var index = 0; index < 30; index++)
            rust.RecoveryDayDto(
              date: fakeDay(29 - index),
              recoveryScore: 60,
              fullyRecovered: index % 3 == 0,
            ),
        ],
      ),
      recentWorkoutsProvider.overrideWith((ref, limit) async => fakeWorkouts()),
    ],
    child: _app(child, locale: locale),
  );
}

List<rust.WorkoutSummaryDto> fakeWorkouts() {
  final now = DateTime.now();
  return [
    rust.WorkoutSummaryDto(
      workoutId: 'w1',
      workoutType: 'run',
      startTimeMs: now
          .subtract(const Duration(days: 1, hours: 2))
          .millisecondsSinceEpoch,
      durationSeconds: 2700,
      distanceMeters: 8400,
      avgPaceSecPerKm: 321,
      avgHr: 148,
      trainingLoad: 62,
    ),
    rust.WorkoutSummaryDto(
      workoutId: 'w2',
      workoutType: 'strength',
      startTimeMs: now
          .subtract(const Duration(days: 2, hours: 1))
          .millisecondsSinceEpoch,
      durationSeconds: 1800,
      trainingLoad: 24,
    ),
  ];
}

rust.MetricSummaryDto fakeSummary() {
  return const rust.MetricSummaryDto(
    windowDays: 90,
    currentPower: 52.3,
    previousPower: 50.1,
    distanceMeters: 128400,
    previousDistanceMeters: 110200,
    avgPaceSecPerKm: 312,
    previousAvgPaceSecPerKm: 318,
    trainingLoad: 420,
    previousTrainingLoad: 390,
    trainingLoadScore: 640,
    previousTrainingLoadScore: 600,
    recoveryRatio: .72,
    previousRecoveryRatio: .66,
    workouts: 18,
    previousWorkouts: 15,
  );
}

String fakeDay(int daysAgo) {
  return formatIsoDate(
    dateOnly(DateTime.now()).subtract(Duration(days: daysAgo)),
  );
}

List<rust.TrendPointDto> fakeTrend(double base, double step) {
  return [
    for (var index = 0; index < 30; index++)
      rust.TrendPointDto(date: fakeDay(29 - index), value: base + step * index),
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'privacy_notice_seen_v1': true});
  });

  testWidgets('overview shows metrics and the empty state', (tester) async {
    await tester.pumpWidget(wrap(const OverviewPage()));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('No training data yet'), findsOneWidget);
    expect(find.text('Connect Zepp'), findsOneWidget);
    expect(find.text('Current power'), findsOneWidget);
    expect(find.text('30-day distance'), findsOneWidget);
    expect(find.text('Average pace'), findsOneWidget);
  });

  testWidgets('compare switches windows and shows all metrics', (tester) async {
    await tester.pumpWidget(wrap(const ComparePage()));
    await tester.pumpAndSettle();

    expect(find.text('90 days'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Average pace'), findsOneWidget);
    expect(find.text('Training load'), findsOneWidget);
    expect(find.text('Recovery'), findsOneWidget);
    expect(find.textContaining('No upcoming race yet'), findsOneWidget);

    await tester.tap(find.text('180 days'));
    await tester.pumpAndSettle();
    expect(find.text('180 days'), findsOneWidget);
    expect(find.text('Training load'), findsOneWidget);
  });

  testWidgets('races shows the empty state and opens the form', (tester) async {
    await tester.pumpWidget(wrap(const RacesPage()));
    await tester.pumpAndSettle();

    expect(find.text('No race plans yet'), findsOneWidget);
    await tester.tap(find.text('Add race'));
    await tester.pumpAndSettle();

    expect(find.text('New race plan'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Race name'), findsOneWidget);
    expect(find.text('Target pace'), findsOneWidget);
  });

  testWidgets('settings shows account, sync and privacy entries', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Not connected'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('pages fit a narrow phone screen and the race form opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final page in <Widget>[
      const OverviewPage(),
      const ComparePage(),
      const RacesPage(),
      const SettingsPage(),
    ]) {
      await tester.pumpWidget(wrap(page));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: page.runtimeType.toString(),
      );
    }

    await tester.pumpWidget(wrap(const RacesPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add race'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('New race plan'), findsOneWidget);
  });

  testWidgets('populated overview and compare fit a phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrapAnalytics(const OverviewPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('52.3'), findsWidgets);
    expect(find.text('128.4'), findsWidgets);
    expect(find.text('5:12'), findsWidgets);
    expect(find.text('Recent training'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('8.4 km'), findsOneWidget);
    expect(find.text('No training data yet'), findsNothing);

    await tester.pumpWidget(wrapAnalytics(const ComparePage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('52.3'), findsWidgets);
    expect(find.text('128.4'), findsWidgets);
    expect(find.text('640'), findsWidgets);
    expect(find.text('72%'), findsWidgets);
  });

  testWidgets('race cards and review fit a phone screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = dateOnly(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'privacy_notice_seen_v1': true,
      'race_plans_v1': jsonEncode([
        {
          'id': '1',
          'name': 'City Marathon',
          'date': formatIsoDate(today.add(const Duration(days: 20))),
          'distanceKm': 42.195,
          'targetPaceSeconds': 270,
        },
        {
          'id': '2',
          'name': 'Old Race',
          'date': formatIsoDate(today.subtract(const Duration(days: 10))),
          'distanceKm': 21.1,
          'targetPaceSeconds': 300,
        },
      ]),
    });

    await tester.pumpWidget(wrap(const RacesPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('City Marathon'), findsOneWidget);
    expect(find.text('Old Race'), findsOneWidget);
    expect(find.text('20 days to go'), findsOneWidget);
    expect(find.text('Finished'), findsWidgets);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Race review'), findsOneWidget);
    expect(find.text('No workout found on race day.'), findsOneWidget);
  });
}
