import 'package:material_ui/material_ui.dart';
import 'package:pacebridge/l10n/app_localizations.dart';

enum DeltaTone { positive, negative, neutral }

/// 「较上期」小胶囊：变好是绿，变差是红，持平或无数据是灰。
class DeltaChip extends StatelessWidget {
  const DeltaChip({required this.label, required this.tone, super.key});

  final String label;
  final DeltaTone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = switch (tone) {
      DeltaTone.positive =>
        brightness == Brightness.dark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF15803D),
      DeltaTone.negative =>
        brightness == Brightness.dark
            ? const Color(0xFFF87171)
            : const Color(0xFFB91C1C),
      DeltaTone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 指标标题旁的问号：点开显示定义和计算口径。
class MetricInfoButton extends StatelessWidget {
  const MetricInfoButton({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.help_outline, size: 18),
      tooltip: l10n.metricInfoAction,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 图表位置的空状态，高度和真实图表一致，切换周期时页面不跳。
class ChartEmpty extends StatelessWidget {
  const ChartEmpty({this.height = 132, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          l10n.metricNoData,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
