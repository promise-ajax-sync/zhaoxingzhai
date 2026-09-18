import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';
import 'package:zhaoxingzhai/core/interpretation/xiaoliuren_interpretation.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

/// 结果展示区域
class ResultDisplaySection extends StatelessWidget {
  final XiaoliurenData result;
  final VoidCallback onReset;
  final DivinationQuestion? question;

  const ResultDisplaySection({
    super.key,
    required this.result,
    required this.onReset,
    this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 主断区域
        _buildMainResult(context),
        const SizedBox(height: 20),

        // 三宫展示
        _buildThreePalaces(context),
        const SizedBox(height: 20),

        // 计算过程
        _buildCalculationProcess(context),
        const SizedBox(height: 20),

        _buildModernReading(context),
        const SizedBox(height: 32),

        // 重新占卜按钮
        _buildResetButton(context),
      ],
    );
  }

  Widget _buildModernReading(BuildContext context) {
    final reading = XiaoliurenInterpretation.build(result, question: question);
    final sections = [
      ('问题回应 · ${reading.questionIntentLabel}', reading.directAnswer),
      ('整体说明', reading.overview),
      ('月宫轨迹', reading.background),
      ('日宫轨迹', reading.process),
      ('当前落点', reading.outcome),
      ('行动建议', reading.action),
      ('风险提醒', reading.riskReminder),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('现代白话解读', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (question != null && question!.rawText.isNotEmpty) ...[
            Text('原问题：${question!.rawText}'),
            const Divider(height: 24),
          ],
          for (var index = 0; index < sections.length; index++) ...[
            Text(
              sections[index].$1,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(sections[index].$2),
            if (index != sections.length - 1) const Divider(height: 24),
          ],
          const Divider(height: 24),
          Text('判断依据', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(reading.evidence.summary),
          const SizedBox(height: 8),
          for (final item in reading.evidence.supportingEvidence)
            Text('• ${item.label}：${item.detail}'),
          const SizedBox(height: 8),
          Text(
            reading.evidence.limitations.map((item) => item.detail).join('；'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMainResult(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentSoft(context),
            theme.cardTheme.color ?? theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '卦象',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.primary.name,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            result.primary.verse,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 15,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThreePalaces(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '三宫推演',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPalaceCard(
                  context,
                  '月宫',
                  result.sequence['month']!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPalaceCard(context, '日宫', result.sequence['day']!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPalaceCard(
                  context,
                  '时宫',
                  result.sequence['hour']!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPalaceCard(
    BuildContext context,
    String label,
    XiaoliurenPalaceDetail palace,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.labelSmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            palace.name,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationProcess(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '推演过程',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProcessStep(context, '农历月', result.lunarMonth.toString()),
          _buildProcessStep(context, '农历日', result.lunarDay.toString()),
          _buildProcessStep(context, '时辰', result.hourLabel),
          Divider(color: theme.dividerColor, thickness: 1, height: 24),
          _buildProcessStep(
            context,
            '月宫',
            result.sequence['month']!.name,
            isHighlight: true,
          ),
          _buildProcessStep(
            context,
            '日宫',
            result.sequence['day']!.name,
            isHighlight: true,
          ),
          _buildProcessStep(
            context,
            '时宫',
            result.sequence['hour']!.name,
            isHighlight: true,
          ),
          const SizedBox(height: 8),
          Text(
            '起课规则：${result.rule == XiaoliurenRule.common ? "通行掌诀" : "多能鄙事"}',
            style: TextStyle(
              color: theme.textTheme.labelSmall?.color,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontSize: isHighlight ? 18 : 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onReset,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: const Text(
        '重新占卜',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
