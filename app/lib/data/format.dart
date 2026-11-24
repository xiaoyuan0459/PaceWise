// 界面里反复用到的数值格式：配速、距离、百分比和日期。
//
// 这些格式不依赖语言，单位统一用 km、/km；需要翻译的只有字段名和说明。

/// 配速（秒/公里）→ `分:秒`。没有数据或非法值返回 `--`。
String formatPace(num? secondsPerKm) {
  if (secondsPerKm == null || !secondsPerKm.isFinite || secondsPerKm <= 0) {
    return '--';
  }
  final total = secondsPerKm.round();
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// 米 → 公里，保留一位小数。
String formatKilometers(num? meters, {int digits = 1}) {
  if (meters == null || !meters.isFinite) return '--';
  return (meters / 1000).toStringAsFixed(digits);
}

/// 赛事距离：最多三位小数，去掉末尾的 0（42.195 不会显示成 42.20）。
String formatRaceDistance(num? kilometers) {
  if (kilometers == null || !kilometers.isFinite) return '--';
  if (kilometers == kilometers.roundToDouble()) {
    return kilometers.round().toString();
  }
  return kilometers
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// 带一位小数的普通数值。
String formatDecimal(num? value, {int digits = 1}) {
  if (value == null || !value.isFinite) return '--';
  return value.toStringAsFixed(digits);
}

/// 0–1 的比例 → 百分比整数。
String formatPercent(num? ratio) {
  if (ratio == null || !ratio.isFinite) return '--';
  return '${(ratio * 100).round()}%';
}

/// 解析 `X:XX` 配速，返回秒/公里；格式不对或超出合理范围返回 null。
int? parsePace(String raw) {
  final match = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(raw.trim());
  if (match == null) return null;
  final seconds = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  if (seconds < 60 || seconds > 3600) return null;
  return seconds;
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// `YYYY-MM-DD`，和内核里保存的日期口径一致。
String formatIsoDate(DateTime value) {
  final date = dateOnly(value);
  return '${date.year}-${_two(date.month)}-${_two(date.day)}';
}

/// 图表轴上用的短日期 `M/d`。
String formatShortDate(DateTime value) => '${value.month}/${value.day}';

/// 训练记录的日期与开始时间 `M/d HH:mm`（本机时区）。
String formatShortDateTime(DateTime value) =>
    '${formatShortDate(value)} ${_two(value.hour)}:${_two(value.minute)}';

/// 运动时长（秒）→ `h:mm:ss`，不足一小时显示 `m:ss`。
String formatDuration(num? seconds) {
  if (seconds == null || !seconds.isFinite || seconds <= 0) return '--';
  final total = seconds.round();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final secs = total % 60;
  if (hours > 0) return '$hours:${_two(minutes)}:${_two(secs)}';
  return '$minutes:${_two(secs)}';
}

/// 最近同步时间 `MM-dd HH:mm`。
String formatSyncTime(DateTime value) =>
    '${_two(value.month)}-${_two(value.day)} ${_two(value.hour)}:${_two(value.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');
