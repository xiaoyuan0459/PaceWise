// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Run AI';

  @override
  String get navOverview => 'Overview';

  @override
  String get navCompare => 'Compare';

  @override
  String get navRaces => 'Races';

  @override
  String get navSettings => 'Settings';

  @override
  String get noTrainingData => 'No training data yet';

  @override
  String get connectZepp => 'Connect Zepp';

  @override
  String get currentPower => 'Current power';

  @override
  String get distance30d => '30-day distance';

  @override
  String get averagePace => 'Average pace';

  @override
  String get metricNoData => 'No data';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get localOnly => 'Your data stays on this device';

  @override
  String get version => 'Version';

  @override
  String get window30 => '30 days';

  @override
  String get window90 => '90 days';

  @override
  String get window180 => '180 days';

  @override
  String get analysisReady => 'Analysis engine ready';

  @override
  String get waitingForBridge => 'Waiting for the Flutter–Rust bridge';

  @override
  String get settingsAccount => 'Account';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncDone => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncWindow90 => 'Last 90 days';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsDataDir => 'Data folder';

  @override
  String get settingsAppData => 'App data';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsAbout => 'About';

  @override
  String get raceEmpty => 'No race plans yet';

  @override
  String get raceAdd => 'Add race';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get vsPrevious => 'vs previous';

  @override
  String get powerTrend => 'Power trend';

  @override
  String get viewComparison => 'View comparison';

  @override
  String get recentTraining => 'Recent training';

  @override
  String get recentTrainingNote => 'Latest synced workouts';

  @override
  String get workoutTypeRun => 'Run';

  @override
  String get workoutTypeTrailRun => 'Trail run';

  @override
  String get workoutTypeTreadmill => 'Treadmill';

  @override
  String get workoutTypeWalk => 'Walk';

  @override
  String get workoutTypeRide => 'Ride';

  @override
  String get workoutTypeSwim => 'Swim';

  @override
  String get workoutTypeStrength => 'Strength';

  @override
  String get workoutTypeHike => 'Hike';

  @override
  String workoutsCount(int count) {
    return '$count workouts';
  }

  @override
  String get privacyTitle => 'Your data stays on this device';

  @override
  String get privacyBody =>
      'Training data is stored locally. Watch data is read from the official Zepp API only when you tap sync — never in the background, and raw health data is never uploaded.';

  @override
  String get privacyOk => 'Got it';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get privacySectionBody =>
      'Training data stays on this device. Sync reads incremental data from the official Zepp API only when you start it; nothing is uploaded in the background.';

  @override
  String get syncNotAuthorized => 'Connect your Zepp account before syncing';

  @override
  String get syncWindowFirst => 'First sync: last 365 days';

  @override
  String get syncWindowLater => 'Sync last 180 days';

  @override
  String get syncWindow180Short => 'Last 180 days';

  @override
  String lastSyncAt(String time) {
    return 'Last sync $time';
  }

  @override
  String get neverSynced => 'Not synced yet';

  @override
  String get metricPower => 'Power';

  @override
  String get metricDistance => 'Distance';

  @override
  String get metricPace => 'Average pace';

  @override
  String get metricLoad => 'Training load';

  @override
  String get metricRecovery => 'Recovery';

  @override
  String get metricPowerInfo =>
      'Instant power estimated from pace and grade. Higher means more output per unit time.';

  @override
  String get metricDistanceInfo =>
      'Total running distance (road, trail and treadmill) in the selected window.';

  @override
  String get metricPaceInfo =>
      'Distance-weighted average pace from moving time. Lower is better.';

  @override
  String get metricLoadInfo =>
      'TRIMP accumulated from heart rate and duration; the weekly average is mapped to 0–1000.';

  @override
  String get metricRecoveryInfo =>
      'Share of days with a fully recovered score in the selected window.';

  @override
  String get metricInfoAction => 'Metric details';

  @override
  String get thisPeriod => 'This period';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String deltaUp(String value) {
    return 'up $value';
  }

  @override
  String deltaDown(String value) {
    return 'down $value';
  }

  @override
  String deltaMore(String value) {
    return '$value more';
  }

  @override
  String deltaLess(String value) {
    return '$value less';
  }

  @override
  String deltaFaster(String value) {
    return '${value}s faster';
  }

  @override
  String deltaSlower(String value) {
    return '${value}s slower';
  }

  @override
  String get deltaFlat => 'flat';

  @override
  String get deltaUnknown => 'not comparable';

  @override
  String get insightTitle => 'Smart insight';

  @override
  String insightPower(String value, String change) {
    return 'Power $value, $change vs the previous period.';
  }

  @override
  String insightDistance(String value, String change) {
    return 'Distance $value km, $change vs the previous period.';
  }

  @override
  String insightPace(String value, String change) {
    return 'Average pace $value/km, $change vs the previous period.';
  }

  @override
  String insightRace(int days, String name, String pace) {
    return '$days days until $name; target pace $pace/km.';
  }

  @override
  String get insightNoRace =>
      'No upcoming race yet. Add one to connect training with a goal.';

  @override
  String get insightEmpty =>
      'Sync your training data to see this period compared with the last.';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get dataIncomplete => 'Incomplete data';

  @override
  String get calibratedUnits => 'Units are normalized before comparison.';

  @override
  String get weeklyAverage => 'Weekly avg';

  @override
  String get fullyRecovered => 'Fully recovered';

  @override
  String get loadEasy => 'Easy';

  @override
  String get loadModerate => 'Moderate';

  @override
  String get loadHard => 'Hard';

  @override
  String get raceName => 'Race name';

  @override
  String get raceDate => 'Race date';

  @override
  String get raceDistance => 'Distance';

  @override
  String get raceTargetPace => 'Target pace';

  @override
  String get raceNameHint => 'e.g. City Marathon';

  @override
  String get raceDistanceHint => 'e.g. 42.195';

  @override
  String get racePaceHint => 'e.g. 4:30';

  @override
  String get raceNewTitle => 'New race plan';

  @override
  String get raceEditTitle => 'Edit race plan';

  @override
  String get raceSaved => 'Race plan saved';

  @override
  String get raceDeleted => 'Race plan deleted';

  @override
  String get raceDeleteTitle => 'Delete this race plan?';

  @override
  String get raceDeleteBody => 'This cannot be undone.';

  @override
  String get raceEnded => 'Finished';

  @override
  String get raceToday => 'Today';

  @override
  String raceDaysLeft(int days) {
    return '$days days to go';
  }

  @override
  String get raceReview => 'Review';

  @override
  String get raceReviewTitle => 'Race review';

  @override
  String get raceReviewTargetPace => 'Target pace';

  @override
  String get raceReviewActualPace => 'Race-day pace';

  @override
  String get raceReviewActualDistance => 'Race-day distance';

  @override
  String get raceReviewNoRecord => 'No workout found on race day.';

  @override
  String raceReviewFaster(String value) {
    return '${value}s faster than target';
  }

  @override
  String raceReviewSlower(String value) {
    return '${value}s slower than target';
  }

  @override
  String get raceReviewEven => 'Matched the target';

  @override
  String get raceNameInvalid => 'Enter a name of 1–30 characters.';

  @override
  String get raceDateInvalid => 'The date cannot be earlier than today.';

  @override
  String get raceDistanceInvalid => 'Enter a distance between 0.1 and 100 km.';

  @override
  String get racePaceInvalid => 'Use X:XX, for example 4:30.';

  @override
  String accountConnectedAs(String name) {
    return 'Connected as $name';
  }

  @override
  String get accountNeedsReauth => 'Authorization expired — reconnect';

  @override
  String get accountDisconnect => 'Disconnect';

  @override
  String get accountDisconnected => 'Disconnected';

  @override
  String get authStartFailed => 'Could not start authorization. Try again.';

  @override
  String get accountDisconnectTitle => 'Disconnect Zepp account?';

  @override
  String get accountDisconnectBody =>
      'You can no longer sync training data. Existing data stays on this device.';

  @override
  String get authWaiting => 'Waiting for browser authorization…';

  @override
  String get authHint =>
      'Complete authorization in the browser, then return to the app.';

  @override
  String get authOpenFailed =>
      'Could not open the browser. Copy the link and open it manually.';

  @override
  String get authCopyLink => 'Copy link';

  @override
  String get authLinkCopied => 'Link copied';

  @override
  String get authSuccess => 'Account connected';

  @override
  String get authDenied => 'Authorization was denied';

  @override
  String get authExpired => 'Authorization expired. Try again.';

  @override
  String get authFailed => 'Authorization failed. Try again.';
}
