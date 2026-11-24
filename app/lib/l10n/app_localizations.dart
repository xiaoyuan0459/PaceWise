import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Run AI'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get navCompare;

  /// No description provided for @navRaces.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get navRaces;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @noTrainingData.
  ///
  /// In en, this message translates to:
  /// **'No training data yet'**
  String get noTrainingData;

  /// No description provided for @connectZepp.
  ///
  /// In en, this message translates to:
  /// **'Connect Zepp'**
  String get connectZepp;

  /// No description provided for @currentPower.
  ///
  /// In en, this message translates to:
  /// **'Current power'**
  String get currentPower;

  /// No description provided for @distance30d.
  ///
  /// In en, this message translates to:
  /// **'30-day distance'**
  String get distance30d;

  /// No description provided for @averagePace.
  ///
  /// In en, this message translates to:
  /// **'Average pace'**
  String get averagePace;

  /// No description provided for @metricNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get metricNoData;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device'**
  String get localOnly;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @window30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get window30;

  /// No description provided for @window90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get window90;

  /// No description provided for @window180.
  ///
  /// In en, this message translates to:
  /// **'180 days'**
  String get window180;

  /// No description provided for @analysisReady.
  ///
  /// In en, this message translates to:
  /// **'Analysis engine ready'**
  String get analysisReady;

  /// No description provided for @waitingForBridge.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the Flutter–Rust bridge'**
  String get waitingForBridge;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncDone;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @syncWindow90.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get syncWindow90;

  /// No description provided for @settingsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsDataDir.
  ///
  /// In en, this message translates to:
  /// **'Data folder'**
  String get settingsDataDir;

  /// No description provided for @settingsAppData.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get settingsAppData;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @raceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No race plans yet'**
  String get raceEmpty;

  /// No description provided for @raceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add race'**
  String get raceAdd;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @vsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs previous'**
  String get vsPrevious;

  /// No description provided for @powerTrend.
  ///
  /// In en, this message translates to:
  /// **'Power trend'**
  String get powerTrend;

  /// No description provided for @viewComparison.
  ///
  /// In en, this message translates to:
  /// **'View comparison'**
  String get viewComparison;

  /// No description provided for @recentTraining.
  ///
  /// In en, this message translates to:
  /// **'Recent training'**
  String get recentTraining;

  /// No description provided for @recentTrainingNote.
  ///
  /// In en, this message translates to:
  /// **'Latest synced workouts'**
  String get recentTrainingNote;

  /// No description provided for @workoutTypeRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get workoutTypeRun;

  /// No description provided for @workoutTypeTrailRun.
  ///
  /// In en, this message translates to:
  /// **'Trail run'**
  String get workoutTypeTrailRun;

  /// No description provided for @workoutTypeTreadmill.
  ///
  /// In en, this message translates to:
  /// **'Treadmill'**
  String get workoutTypeTreadmill;

  /// No description provided for @workoutTypeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get workoutTypeWalk;

  /// No description provided for @workoutTypeRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get workoutTypeRide;

  /// No description provided for @workoutTypeSwim.
  ///
  /// In en, this message translates to:
  /// **'Swim'**
  String get workoutTypeSwim;

  /// No description provided for @workoutTypeStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get workoutTypeStrength;

  /// No description provided for @workoutTypeHike.
  ///
  /// In en, this message translates to:
  /// **'Hike'**
  String get workoutTypeHike;

  /// No description provided for @workoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} workouts'**
  String workoutsCount(int count);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Training data is stored locally. Watch data is read from the official Zepp API only when you tap sync — never in the background, and raw health data is never uploaded.'**
  String get privacyBody;

  /// No description provided for @privacyOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get privacyOk;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// No description provided for @privacySectionBody.
  ///
  /// In en, this message translates to:
  /// **'Training data stays on this device. Sync reads incremental data from the official Zepp API only when you start it; nothing is uploaded in the background.'**
  String get privacySectionBody;

  /// No description provided for @syncNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Connect your Zepp account before syncing'**
  String get syncNotAuthorized;

  /// No description provided for @syncWindowFirst.
  ///
  /// In en, this message translates to:
  /// **'First sync: last 365 days'**
  String get syncWindowFirst;

  /// No description provided for @syncWindowLater.
  ///
  /// In en, this message translates to:
  /// **'Sync last 180 days'**
  String get syncWindowLater;

  /// No description provided for @syncWindow180Short.
  ///
  /// In en, this message translates to:
  /// **'Last 180 days'**
  String get syncWindow180Short;

  /// No description provided for @lastSyncAt.
  ///
  /// In en, this message translates to:
  /// **'Last sync {time}'**
  String lastSyncAt(String time);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get neverSynced;

  /// No description provided for @metricPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get metricPower;

  /// No description provided for @metricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get metricDistance;

  /// No description provided for @metricPace.
  ///
  /// In en, this message translates to:
  /// **'Average pace'**
  String get metricPace;

  /// No description provided for @metricLoad.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get metricLoad;

  /// No description provided for @metricRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get metricRecovery;

  /// No description provided for @metricPowerInfo.
  ///
  /// In en, this message translates to:
  /// **'Instant power estimated from pace and grade. Higher means more output per unit time.'**
  String get metricPowerInfo;

  /// No description provided for @metricDistanceInfo.
  ///
  /// In en, this message translates to:
  /// **'Total running distance (road, trail and treadmill) in the selected window.'**
  String get metricDistanceInfo;

  /// No description provided for @metricPaceInfo.
  ///
  /// In en, this message translates to:
  /// **'Distance-weighted average pace from moving time. Lower is better.'**
  String get metricPaceInfo;

  /// No description provided for @metricLoadInfo.
  ///
  /// In en, this message translates to:
  /// **'TRIMP accumulated from heart rate and duration; the weekly average is mapped to 0–1000.'**
  String get metricLoadInfo;

  /// No description provided for @metricRecoveryInfo.
  ///
  /// In en, this message translates to:
  /// **'Share of days with a fully recovered score in the selected window.'**
  String get metricRecoveryInfo;

  /// No description provided for @metricInfoAction.
  ///
  /// In en, this message translates to:
  /// **'Metric details'**
  String get metricInfoAction;

  /// No description provided for @thisPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get thisPeriod;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get previousPeriod;

  /// No description provided for @deltaUp.
  ///
  /// In en, this message translates to:
  /// **'up {value}'**
  String deltaUp(String value);

  /// No description provided for @deltaDown.
  ///
  /// In en, this message translates to:
  /// **'down {value}'**
  String deltaDown(String value);

  /// No description provided for @deltaMore.
  ///
  /// In en, this message translates to:
  /// **'{value} more'**
  String deltaMore(String value);

  /// No description provided for @deltaLess.
  ///
  /// In en, this message translates to:
  /// **'{value} less'**
  String deltaLess(String value);

  /// No description provided for @deltaFaster.
  ///
  /// In en, this message translates to:
  /// **'{value}s faster'**
  String deltaFaster(String value);

  /// No description provided for @deltaSlower.
  ///
  /// In en, this message translates to:
  /// **'{value}s slower'**
  String deltaSlower(String value);

  /// No description provided for @deltaFlat.
  ///
  /// In en, this message translates to:
  /// **'flat'**
  String get deltaFlat;

  /// No description provided for @deltaUnknown.
  ///
  /// In en, this message translates to:
  /// **'not comparable'**
  String get deltaUnknown;

  /// No description provided for @insightTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart insight'**
  String get insightTitle;

  /// No description provided for @insightPower.
  ///
  /// In en, this message translates to:
  /// **'Power {value}, {change} vs the previous period.'**
  String insightPower(String value, String change);

  /// No description provided for @insightDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance {value} km, {change} vs the previous period.'**
  String insightDistance(String value, String change);

  /// No description provided for @insightPace.
  ///
  /// In en, this message translates to:
  /// **'Average pace {value}/km, {change} vs the previous period.'**
  String insightPace(String value, String change);

  /// No description provided for @insightRace.
  ///
  /// In en, this message translates to:
  /// **'{days} days until {name}; target pace {pace}/km.'**
  String insightRace(int days, String name, String pace);

  /// No description provided for @insightNoRace.
  ///
  /// In en, this message translates to:
  /// **'No upcoming race yet. Add one to connect training with a goal.'**
  String get insightNoRace;

  /// No description provided for @insightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Sync your training data to see this period compared with the last.'**
  String get insightEmpty;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @dataIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete data'**
  String get dataIncomplete;

  /// No description provided for @calibratedUnits.
  ///
  /// In en, this message translates to:
  /// **'Units are normalized before comparison.'**
  String get calibratedUnits;

  /// No description provided for @weeklyAverage.
  ///
  /// In en, this message translates to:
  /// **'Weekly avg'**
  String get weeklyAverage;

  /// No description provided for @fullyRecovered.
  ///
  /// In en, this message translates to:
  /// **'Fully recovered'**
  String get fullyRecovered;

  /// No description provided for @loadEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get loadEasy;

  /// No description provided for @loadModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get loadModerate;

  /// No description provided for @loadHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get loadHard;

  /// No description provided for @raceName.
  ///
  /// In en, this message translates to:
  /// **'Race name'**
  String get raceName;

  /// No description provided for @raceDate.
  ///
  /// In en, this message translates to:
  /// **'Race date'**
  String get raceDate;

  /// No description provided for @raceDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get raceDistance;

  /// No description provided for @raceTargetPace.
  ///
  /// In en, this message translates to:
  /// **'Target pace'**
  String get raceTargetPace;

  /// No description provided for @raceNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. City Marathon'**
  String get raceNameHint;

  /// No description provided for @raceDistanceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 42.195'**
  String get raceDistanceHint;

  /// No description provided for @racePaceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4:30'**
  String get racePaceHint;

  /// No description provided for @raceNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New race plan'**
  String get raceNewTitle;

  /// No description provided for @raceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit race plan'**
  String get raceEditTitle;

  /// No description provided for @raceSaved.
  ///
  /// In en, this message translates to:
  /// **'Race plan saved'**
  String get raceSaved;

  /// No description provided for @raceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Race plan deleted'**
  String get raceDeleted;

  /// No description provided for @raceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this race plan?'**
  String get raceDeleteTitle;

  /// No description provided for @raceDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get raceDeleteBody;

  /// No description provided for @raceEnded.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get raceEnded;

  /// No description provided for @raceToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get raceToday;

  /// No description provided for @raceDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days to go'**
  String raceDaysLeft(int days);

  /// No description provided for @raceReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get raceReview;

  /// No description provided for @raceReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Race review'**
  String get raceReviewTitle;

  /// No description provided for @raceReviewTargetPace.
  ///
  /// In en, this message translates to:
  /// **'Target pace'**
  String get raceReviewTargetPace;

  /// No description provided for @raceReviewActualPace.
  ///
  /// In en, this message translates to:
  /// **'Race-day pace'**
  String get raceReviewActualPace;

  /// No description provided for @raceReviewActualDistance.
  ///
  /// In en, this message translates to:
  /// **'Race-day distance'**
  String get raceReviewActualDistance;

  /// No description provided for @raceReviewNoRecord.
  ///
  /// In en, this message translates to:
  /// **'No workout found on race day.'**
  String get raceReviewNoRecord;

  /// No description provided for @raceReviewFaster.
  ///
  /// In en, this message translates to:
  /// **'{value}s faster than target'**
  String raceReviewFaster(String value);

  /// No description provided for @raceReviewSlower.
  ///
  /// In en, this message translates to:
  /// **'{value}s slower than target'**
  String raceReviewSlower(String value);

  /// No description provided for @raceReviewEven.
  ///
  /// In en, this message translates to:
  /// **'Matched the target'**
  String get raceReviewEven;

  /// No description provided for @raceNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name of 1–30 characters.'**
  String get raceNameInvalid;

  /// No description provided for @raceDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'The date cannot be earlier than today.'**
  String get raceDateInvalid;

  /// No description provided for @raceDistanceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a distance between 0.1 and 100 km.'**
  String get raceDistanceInvalid;

  /// No description provided for @racePaceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use X:XX, for example 4:30.'**
  String get racePaceInvalid;

  /// No description provided for @accountConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {name}'**
  String accountConnectedAs(String name);

  /// No description provided for @accountNeedsReauth.
  ///
  /// In en, this message translates to:
  /// **'Authorization expired — reconnect'**
  String get accountNeedsReauth;

  /// No description provided for @accountDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get accountDisconnect;

  /// No description provided for @accountDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get accountDisconnected;

  /// No description provided for @authStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start authorization. Try again.'**
  String get authStartFailed;

  /// No description provided for @accountDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Zepp account?'**
  String get accountDisconnectTitle;

  /// No description provided for @accountDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'You can no longer sync training data. Existing data stays on this device.'**
  String get accountDisconnectBody;

  /// No description provided for @authWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for browser authorization…'**
  String get authWaiting;

  /// No description provided for @authHint.
  ///
  /// In en, this message translates to:
  /// **'Complete authorization in the browser, then return to the app.'**
  String get authHint;

  /// No description provided for @authOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser. Copy the link and open it manually.'**
  String get authOpenFailed;

  /// No description provided for @authCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get authCopyLink;

  /// No description provided for @authLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get authLinkCopied;

  /// No description provided for @authSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get authSuccess;

  /// No description provided for @authDenied.
  ///
  /// In en, this message translates to:
  /// **'Authorization was denied'**
  String get authDenied;

  /// No description provided for @authExpired.
  ///
  /// In en, this message translates to:
  /// **'Authorization expired. Try again.'**
  String get authExpired;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authorization failed. Try again.'**
  String get authFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
