// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '智跑 AI';

  @override
  String get navOverview => '概览';

  @override
  String get navCompare => '对比';

  @override
  String get navRaces => '赛事';

  @override
  String get navSettings => '设置';

  @override
  String get noTrainingData => '还没有训练数据';

  @override
  String get connectZepp => '连接 Zepp';

  @override
  String get currentPower => '当前跑力';

  @override
  String get distance30d => '近 30 天跑量';

  @override
  String get averagePace => '平均配速';

  @override
  String get metricNoData => '暂无数据';

  @override
  String get comingSoon => '即将上线';

  @override
  String get localOnly => '数据只保存在本机';

  @override
  String get version => '版本';

  @override
  String get window30 => '30 天';

  @override
  String get window90 => '90 天';

  @override
  String get window180 => '180 天';

  @override
  String get analysisReady => '分析模块已就绪';

  @override
  String get waitingForBridge => '等待 Flutter 与 Rust 桥接';

  @override
  String get settingsAccount => '账号';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncing => '正在同步…';

  @override
  String get syncDone => '同步完成';

  @override
  String get syncFailed => '同步失败';

  @override
  String get syncWindow90 => '最近 90 天';

  @override
  String get settingsNotConnected => '未连接';

  @override
  String get settingsData => '数据';

  @override
  String get settingsDataDir => '数据目录';

  @override
  String get settingsAppData => '应用数据';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsAbout => '关于';

  @override
  String get raceEmpty => '还没有赛事计划';

  @override
  String get raceAdd => '新增赛事';
}
