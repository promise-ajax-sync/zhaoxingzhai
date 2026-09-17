/// 塔罗占卜结果展示
library;

import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';

class TarotResultDisplay extends StatelessWidget {
  final TarotDrawResult result;

  const TarotResultDisplay({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 牌阵信息
        AppCard(
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.spreadName,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      '抽取时间: ${_formatTime(result.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space3,
                  vertical: AppTheme.space2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(
                  '${result.cards.length}张',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.space5),

        // 牌面展示
        const AppSectionHeading(title: '牌面解读'),
        ...result.cards.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: _TarotCardItem(card: card, index: index),
          );
        }),

        const SizedBox(height: AppTheme.space5),

        // 证据分析
        const AppSectionHeading(title: '证据分析'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 牌阵覆盖状态
              _buildAnalysisItem(
                context,
                icon: Icons.check_circle_outline,
                title: '牌阵状态',
                content: result.evidenceAnalysis.spreadCoverageFact.status,
                status:
                    result.evidenceAnalysis.spreadCoverageFact.status == '完整'
                    ? AnalysisStatus.success
                    : AnalysisStatus.warning,
              ),

              const Divider(height: AppTheme.space5),

              // 证据汇总
              _buildAnalysisItem(
                context,
                icon: Icons.summarize,
                title: '证据汇总',
                content: result.evidenceAnalysis.summaryFact.promptText,
                status: AnalysisStatus.neutral,
              ),

              // 逆位反证
              if (result.evidenceAnalysis.counterEvidenceFacts.isNotEmpty) ...[
                const Divider(height: AppTheme.space5),
                _buildAnalysisItem(
                  context,
                  icon: Icons.warning_amber,
                  title: '逆位约束',
                  content:
                      result.evidenceAnalysis.counterSummaryFact.promptText,
                  status: AnalysisStatus.caution,
                ),
              ],

              // 方法论
              const Divider(height: AppTheme.space5),
              _buildMethodology(context, result.evidenceAnalysis.methodology),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.space7),
      ],
    );
  }

  Widget _buildAnalysisItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required AnalysisStatus status,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: _getStatusColor(context, status)),
            const SizedBox(width: AppTheme.space2),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        Text(content, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMethodology(BuildContext context, List<String> methodology) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.space2),
            Text('方法论', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        ...methodology.map(
          (method) => Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.space5,
              top: AppTheme.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: Theme.of(context).textTheme.bodySmall),
                Expanded(
                  child: Text(
                    method,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.success:
        return Colors.green;
      case AnalysisStatus.caution:
        return Colors.orange;
      case AnalysisStatus.warning:
        return Colors.red;
      case AnalysisStatus.neutral:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

enum AnalysisStatus { success, caution, warning, neutral }

class _TarotCardItem extends StatelessWidget {
  final TarotCardEvidence card;
  final int index;

  const _TarotCardItem({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final isReversed = card.orientation == '逆位';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              // 序号
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.space3),

              // 牌位
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.position,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      card.name,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),

              // 正逆位标识
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space2,
                  vertical: AppTheme.space1,
                ),
                decoration: BoxDecoration(
                  color: isReversed
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  border: Border.all(
                    color: isReversed ? Colors.orange : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReversed ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 14,
                      color: isReversed ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: AppTheme.space1),
                    Text(
                      card.orientation,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isReversed ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space3),

          // 关键词
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: card.keywords.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space2,
                  vertical: AppTheme.space1,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  keyword,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.space3),

          // 元素和原型
          Row(
            children: [
              Expanded(
                child: _buildAttribute(
                  context,
                  icon: Icons.whatshot,
                  label: '元素',
                  value: card.element,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: _buildAttribute(
                  context,
                  icon: Icons.category,
                  label: '原型',
                  value: card.archetype,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttribute(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: AppTheme.space1),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: AppTheme.space1),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
