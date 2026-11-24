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

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get last30Days => '最近 30 天';

  @override
  String get vsPrevious => '较上期';

  @override
  String get powerTrend => '跑力趋势';

  @override
  String get viewComparison => '查看对比';

  @override
  String get recentTraining => '最近训练';

  @override
  String get recentTrainingNote => '最近已同步的训练';

  @override
  String get workoutTypeRun => '跑步';

  @override
  String get workoutTypeTrailRun => '越野跑';

  @override
  String get workoutTypeTreadmill => '跑步机';

  @override
  String get workoutTypeWalk => '步行';

  @override
  String get workoutTypeRide => '骑行';

  @override
  String get workoutTypeSwim => '游泳';

  @override
  String get workoutTypeStrength => '力量训练';

  @override
  String get workoutTypeHike => '徒步';

  @override
  String workoutsCount(int count) {
    return '$count 次训练';
  }

  @override
  String get privacyTitle => '数据只保存在本机';

  @override
  String get privacyBody =>
      '训练数据保存在你的设备上。只有你主动点同步时，应用才从 Zepp 官方接口读取增量数据，不会在后台采集，也不会上传原始健康数据。';

  @override
  String get privacyOk => '知道了';

  @override
  String get privacySectionTitle => '隐私';

  @override
  String get privacySectionBody =>
      '训练数据保存在本机。只有你主动同步时，应用才从 Zepp 官方接口读取增量数据，不会在后台上传。';

  @override
  String get syncNotAuthorized => '连接 Zepp 账号后才能同步';

  @override
  String get syncWindowFirst => '首次同步最近 365 天';

  @override
  String get syncWindowLater => '同步最近 180 天';

  @override
  String get syncWindow180Short => '最近 180 天';

  @override
  String lastSyncAt(String time) {
    return '上次同步：$time';
  }

  @override
  String get neverSynced => '还没有同步过';

  @override
  String get metricPower => '跑力';

  @override
  String get metricDistance => '累计跑量';

  @override
  String get metricPace => '平均配速';

  @override
  String get metricLoad => '训练负荷';

  @override
  String get metricRecovery => '恢复状态';

  @override
  String get metricPowerInfo => '根据配速与坡度估算的即时跑力，越高表示单位时间输出能力越强。';

  @override
  String get metricDistanceInfo => '所选周期内跑步（含越野、跑步机）的距离总和。';

  @override
  String get metricPaceInfo => '按运动时间与距离计算的加权平均配速，越低越好。';

  @override
  String get metricLoadInfo => '由心率与运动时长计算的 TRIMP 累加，周均映射到 0–1000 分。';

  @override
  String get metricRecoveryInfo => '所选周期内当天恢复分达到充分恢复的占比。';

  @override
  String get metricInfoAction => '指标说明';

  @override
  String get thisPeriod => '本期';

  @override
  String get previousPeriod => '上期';

  @override
  String deltaUp(String value) {
    return '提升 $value';
  }

  @override
  String deltaDown(String value) {
    return '下降 $value';
  }

  @override
  String deltaMore(String value) {
    return '多 $value';
  }

  @override
  String deltaLess(String value) {
    return '少 $value';
  }

  @override
  String deltaFaster(String value) {
    return '快 $value 秒';
  }

  @override
  String deltaSlower(String value) {
    return '慢 $value 秒';
  }

  @override
  String get deltaFlat => '持平';

  @override
  String get deltaUnknown => '暂无可比数据';

  @override
  String get insightTitle => '智能解读';

  @override
  String insightPower(String value, String change) {
    return '跑力 $value，较上期$change。';
  }

  @override
  String insightDistance(String value, String change) {
    return '跑量 $value km，较上期$change。';
  }

  @override
  String insightPace(String value, String change) {
    return '平均配速 $value/km，较上期$change。';
  }

  @override
  String insightRace(int days, String name, String pace) {
    return '距离「$name」还有 $days 天，目标配速 $pace/km。';
  }

  @override
  String get insightNoRace => '还没有未完成的赛事计划；添加赛事后，这里会给出备赛建议。';

  @override
  String get insightEmpty => '同步训练数据后，这里会给出本期与上期的对比解读。';

  @override
  String get expand => '展开';

  @override
  String get collapse => '收起';

  @override
  String get dataIncomplete => '数据不完整';

  @override
  String get calibratedUnits => '不同来源的数据已统一单位后再对比。';

  @override
  String get weeklyAverage => '周均';

  @override
  String get fullyRecovered => '充分恢复';

  @override
  String get loadEasy => '轻松';

  @override
  String get loadModerate => '适中';

  @override
  String get loadHard => '困难';

  @override
  String get raceName => '赛事名称';

  @override
  String get raceDate => '赛事日期';

  @override
  String get raceDistance => '赛事距离';

  @override
  String get raceTargetPace => '目标配速';

  @override
  String get raceNameHint => '例如：城市马拉松';

  @override
  String get raceDistanceHint => '例如：42.195';

  @override
  String get racePaceHint => '例如：4:30';

  @override
  String get raceNewTitle => '新增赛事计划';

  @override
  String get raceEditTitle => '编辑赛事计划';

  @override
  String get raceSaved => '赛事计划已保存';

  @override
  String get raceDeleted => '赛事计划已删除';

  @override
  String get raceDeleteTitle => '删除这个赛事计划？';

  @override
  String get raceDeleteBody => '删除后不可恢复。';

  @override
  String get raceEnded => '已结束';

  @override
  String get raceToday => '今天';

  @override
  String raceDaysLeft(int days) {
    return '还有 $days 天';
  }

  @override
  String get raceReview => '复盘';

  @override
  String get raceReviewTitle => '赛事复盘';

  @override
  String get raceReviewTargetPace => '目标配速';

  @override
  String get raceReviewActualPace => '比赛日配速';

  @override
  String get raceReviewActualDistance => '比赛日距离';

  @override
  String get raceReviewNoRecord => '没有找到比赛当天的训练记录。';

  @override
  String raceReviewFaster(String value) {
    return '比目标快 $value 秒';
  }

  @override
  String raceReviewSlower(String value) {
    return '比目标慢 $value 秒';
  }

  @override
  String get raceReviewEven => '与目标持平';

  @override
  String get raceNameInvalid => '请填写 1-30 字的赛事名称。';

  @override
  String get raceDateInvalid => '赛事日期不能早于今天。';

  @override
  String get raceDistanceInvalid => '距离需在 0.1-100 km 之间。';

  @override
  String get racePaceInvalid => '配速格式应为 X:XX，如 4:30。';

  @override
  String accountConnectedAs(String name) {
    return '已连接：$name';
  }

  @override
  String get accountNeedsReauth => '授权已过期，请重新连接';

  @override
  String get accountDisconnect => '断开连接';

  @override
  String get accountDisconnected => '已断开连接';

  @override
  String get authStartFailed => '无法开始授权，请重试。';

  @override
  String get accountDisconnectTitle => '断开 Zepp 账号？';

  @override
  String get accountDisconnectBody => '断开后将无法同步训练数据，已有数据仍保存在本机。';

  @override
  String get authWaiting => '等待浏览器授权…';

  @override
  String get authHint => '已在浏览器打开授权页，完成后回到应用即可。';

  @override
  String get authOpenFailed => '无法打开浏览器，请复制链接手动打开。';

  @override
  String get authCopyLink => '复制链接';

  @override
  String get authLinkCopied => '链接已复制';

  @override
  String get authSuccess => '账号已连接';

  @override
  String get authDenied => '授权被拒绝';

  @override
  String get authExpired => '授权已过期，请重试';

  @override
  String get authFailed => '授权失败，请重试';
}
