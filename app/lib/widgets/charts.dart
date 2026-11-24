import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/data/format.dart';

/// 折线图和柱状图共用的一个点。
class ChartPoint {
  const ChartPoint({required this.date, required this.value, this.color});

  final DateTime date;
  final double value;
  final Color? color;
}

/// 轻量折线图：网格、面积渐变、最后一个数据点、首尾日期。
/// 传入 [previousPoints] 时会把上期序列画成一条较淡的对照线。
class TrendLineChart extends StatefulWidget {
  const TrendLineChart({
    required this.points,
    this.previousPoints,
    this.height = 132,
    this.color,
    this.previousColor,
    this.valueFormatter,
    super.key,
  });

  final List<ChartPoint> points;
  final List<ChartPoint>? previousPoints;
  final double height;
  final Color? color;
  final Color? previousColor;
  final String Function(double value)? valueFormatter;

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant TrendLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points.length != widget.points.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return SizedBox(height: widget.height);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: scheme.onSurfaceVariant,
        ) ??
        const TextStyle(fontSize: 10);
    final lineColor = widget.color ?? scheme.primary;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _select(details.localPosition.dx),
        child: CustomPaint(
          painter: _LinePainter(
            points: widget.points,
            previousPoints: widget.previousPoints ?? const [],
            lineColor: lineColor,
            previousColor:
                widget.previousColor ?? lineColor.withValues(alpha: .45),
            gridColor: scheme.outlineVariant.withValues(alpha: .35),
            labelStyle: labelStyle,
            valueFormatter: widget.valueFormatter ?? _compact,
            selectedIndex: _selected,
          ),
        ),
      ),
    );
  }

  void _select(double dx) {
    final count = widget.points.length;
    if (count == 0) return;
    const left = 4.0;
    const right = 4.0;
    final width = context.size?.width ?? 0;
    final chartWidth = math.max(width - left - right, 1.0);
    final raw = count <= 1
        ? 0
        : ((dx - left) / chartWidth * (count - 1)).round();
    final index = raw < 0
        ? 0
        : raw >= count
        ? count - 1
        : raw;
    setState(() => _selected = _selected == index ? null : index);
  }
}

/// 轻量柱状图，支持逐根指定颜色（负荷按强度分档）。
class TrendBarChart extends StatefulWidget {
  const TrendBarChart({
    required this.points,
    this.height = 132,
    this.color,
    this.valueFormatter,
    super.key,
  });

  final List<ChartPoint> points;
  final double height;
  final Color? color;
  final String Function(double value)? valueFormatter;

  @override
  State<TrendBarChart> createState() => _TrendBarChartState();
}

class _TrendBarChartState extends State<TrendBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant TrendBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points.length != widget.points.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return SizedBox(height: widget.height);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: scheme.onSurfaceVariant,
        ) ??
        const TextStyle(fontSize: 10);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _select(details.localPosition.dx),
        child: CustomPaint(
          painter: _BarPainter(
            points: widget.points,
            barColor: widget.color ?? scheme.secondary,
            gridColor: scheme.outlineVariant.withValues(alpha: .35),
            labelStyle: labelStyle,
            valueFormatter: widget.valueFormatter ?? _compact,
            selectedIndex: _selected,
          ),
        ),
      ),
    );
  }

  void _select(double dx) {
    final count = widget.points.length;
    if (count == 0) return;
    const left = 4.0;
    const right = 4.0;
    final width = context.size?.width ?? 0;
    final slotWidth = math.max(width - left - right, 1.0) / count;
    final raw = ((dx - left) / slotWidth).floor();
    final index = raw < 0
        ? 0
        : raw >= count
        ? count - 1
        : raw;
    setState(() => _selected = _selected == index ? null : index);
  }
}

/// 恢复状态环形图。`ratio` 为 0–1；没有数据时画一圈底色。
class RecoveryRing extends StatelessWidget {
  const RecoveryRing({
    required this.ratio,
    required this.centerLabel,
    this.caption,
    this.size = 124,
    super.key,
  });

  final double? ratio;
  final String centerLabel;
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = (ratio ?? 0).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: ratio == null ? 0 : value,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _compact(double value) {
  if (!value.isFinite) return '--';
  if (value.abs() >= 100) return value.round().toString();
  if (value.abs() >= 10) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.previousPoints,
    required this.lineColor,
    required this.previousColor,
    required this.gridColor,
    required this.labelStyle,
    required this.valueFormatter,
    this.selectedIndex,
  });

  final List<ChartPoint> points;
  final List<ChartPoint> previousPoints;
  final Color lineColor;
  final Color previousColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final String Function(double value) valueFormatter;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 4.0;
    const right = 4.0;
    const top = 12.0;
    const bottom = 18.0;
    final chartWidth = math.max(size.width - left - right, 1.0);
    final chartHeight = math.max(size.height - top - bottom, 1.0);

    var minValue = points.first.value;
    var maxValue = points.first.value;
    for (final point in [...points, ...previousPoints]) {
      minValue = math.min(minValue, point.value);
      maxValue = math.max(maxValue, point.value);
    }
    if ((maxValue - minValue).abs() < 0.0001) {
      final padding = math.max(maxValue.abs() * .1, 1.0);
      minValue -= padding;
      maxValue += padding;
    }
    final range = maxValue - minValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = top + chartHeight * index / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    double xAt(int index, int count) => count <= 1
        ? left + chartWidth / 2
        : left + chartWidth * index / (count - 1);
    double yAt(double value) => top + (maxValue - value) / range * chartHeight;

    if (previousPoints.length > 1) {
      final previousLine = Path();
      for (var index = 0; index < previousPoints.length; index++) {
        final offset = Offset(
          xAt(index, previousPoints.length),
          yAt(previousPoints[index].value),
        );
        if (index == 0) {
          previousLine.moveTo(offset.dx, offset.dy);
        } else {
          previousLine.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(
        previousLine,
        Paint()
          ..color = previousColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final line = Path();
    for (var index = 0; index < points.length; index++) {
      final offset = Offset(
        xAt(index, points.length),
        yAt(points[index].value),
      );
      if (index == 0) {
        line.moveTo(offset.dx, offset.dy);
      } else {
        line.lineTo(offset.dx, offset.dy);
      }
    }

    final fill = Path.from(line)
      ..lineTo(xAt(points.length - 1, points.length), top + chartHeight)
      ..lineTo(xAt(0, points.length), top + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: .28),
          lineColor.withValues(alpha: .02),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(fill, fillPaint);

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastPoint = Offset(
      xAt(points.length - 1, points.length),
      yAt(points.last.value),
    );
    canvas.drawCircle(
      lastPoint,
      5,
      Paint()..color = lineColor.withValues(alpha: .18),
    );
    canvas.drawCircle(lastPoint, 3, Paint()..color = lineColor);

    final selected = selectedIndex;
    final hasSelection =
        selected != null && selected >= 0 && selected < points.length;
    if (!hasSelection) {
      _drawText(canvas, valueFormatter(maxValue), Offset(left, 0), labelStyle);
      _drawText(
        canvas,
        valueFormatter(minValue),
        Offset(left, top + chartHeight - 11),
        labelStyle,
      );
    }
    _drawText(
      canvas,
      formatShortDate(points.first.date),
      Offset(left, size.height - 14),
      labelStyle,
    );
    _drawText(
      canvas,
      formatShortDate(points.last.date),
      Offset(left + chartWidth, size.height - 14),
      labelStyle,
      alignRight: true,
    );

    if (selected != null && selected >= 0 && selected < points.length) {
      final point = points[selected];
      final x = xAt(selected, points.length);
      final y = yAt(point.value);
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + chartHeight),
        Paint()
          ..color = lineColor.withValues(alpha: .35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = lineColor.withValues(alpha: .2),
      );
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = lineColor);
      _drawBubble(
        canvas,
        size,
        x,
        '${formatShortDate(point.date)} · ${valueFormatter(point.value)}',
        labelStyle,
        lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.previousPoints != previousPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.previousColor != previousColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.points,
    required this.barColor,
    required this.gridColor,
    required this.labelStyle,
    required this.valueFormatter,
    this.selectedIndex,
  });

  final List<ChartPoint> points;
  final Color barColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final String Function(double value) valueFormatter;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 4.0;
    const right = 4.0;
    const top = 12.0;
    const bottom = 18.0;
    final chartWidth = math.max(size.width - left - right, 1.0);
    final chartHeight = math.max(size.height - top - bottom, 1.0);
    final maxValue = points.fold<double>(
      0,
      (current, point) => math.max(current, point.value),
    );
    if (maxValue <= 0) {
      _drawText(canvas, '--', Offset(left, top + chartHeight / 2), labelStyle);
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = top + chartHeight * index / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    final slotWidth = chartWidth / points.length;
    final barWidth = (slotWidth * .62).clamp(2.0, 20.0);
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (point.value <= 0) continue;
      final height = math.max(point.value / maxValue * chartHeight, 1.5);
      final centerX = left + slotWidth * (index + .5);
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        top + chartHeight - height,
        barWidth,
        height,
      );
      final paint = Paint()..color = point.color ?? barColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(math.min(3, barWidth / 2)),
          topRight: Radius.circular(math.min(3, barWidth / 2)),
        ),
        paint,
      );
    }

    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(left + chartWidth, top + chartHeight),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );
    _drawText(
      canvas,
      formatShortDate(points.first.date),
      Offset(left, size.height - 14),
      labelStyle,
    );
    _drawText(
      canvas,
      formatShortDate(points.last.date),
      Offset(left + chartWidth, size.height - 14),
      labelStyle,
      alignRight: true,
    );

    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final point = points[selected];
      final centerX = left + slotWidth * (selected + .5);
      canvas.drawLine(
        Offset(centerX, top),
        Offset(centerX, top + chartHeight),
        Paint()
          ..color = barColor.withValues(alpha: .35)
          ..strokeWidth = 1,
      );
      _drawBubble(
        canvas,
        size,
        centerX,
        '${formatShortDate(point.date)} · ${valueFormatter(point.value)}',
        labelStyle,
        point.color ?? barColor,
      );
    } else {
      _drawText(canvas, valueFormatter(maxValue), Offset(left, 0), labelStyle);
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

void _drawBubble(
  Canvas canvas,
  Size size,
  double centerX,
  String text,
  TextStyle style,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final dx = (centerX - painter.width / 2)
      .clamp(0.0, math.max(size.width - painter.width, 0.0))
      .toDouble();
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(dx - 5, 0, painter.width + 10, painter.height + 2),
    const Radius.circular(4),
  );
  canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: .1));
  painter.paint(canvas, Offset(dx, 1));
}

void _drawText(
  Canvas canvas,
  String text,
  Offset offset,
  TextStyle style, {
  bool alignRight = false,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final dx = alignRight ? offset.dx - painter.width : offset.dx;
  painter.paint(canvas, Offset(math.max(dx, 0), offset.dy));
}
