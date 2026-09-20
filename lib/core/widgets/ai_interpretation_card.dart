import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

class AiInterpretationCard extends StatelessWidget {
  const AiInterpretationCard({
    super.key,
    required this.response,
    required this.loading,
    required this.error,
    required this.onRequest,
    required this.loadingText,
    required this.idleText,
    required this.actionKey,
    this.enabled = true,
    this.disabledText = '请先填写希望重点回应的问题。',
  });

  final AiInterpretationResponse? response;
  final bool loading;
  final Object? error;
  final Future<void> Function() onRequest;
  final String loadingText;
  final String idleText;
  final Key actionKey;
  final bool enabled;
  final String disabledText;

  @override
  Widget build(BuildContext context) {
    final current = response;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppTheme.space3),
              Text(loadingText),
            ] else if (current != null) ...[
              Row(
                children: [
                  Icon(
                    current.usedFallback
                        ? Icons.offline_bolt_outlined
                        : Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Expanded(
                    child: Text(
                      current.usedFallback
                          ? '基础解读（智能服务暂不可用）'
                          : '远程 AI · ${current.modelId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space3),
              if (current.reading case final reading?)
                _StructuredReadingView(reading: reading)
              else
                SelectableText(current.content),
              if (current.fallbackReason?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppTheme.space3),
                Text(
                  '智能深度解读暂未完成：${current.fallbackReason}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppTheme.space3),
              Text(
                '提示词 v${current.promptVersion} · 证据 ${current.evidenceMethodId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space3),
              OutlinedButton.icon(
                key: actionKey,
                onPressed: enabled ? onRequest : null,
                icon: const Icon(Icons.refresh),
                label: const Text('重新生成'),
              ),
            ] else ...[
              Text(enabled ? idleText : disabledText),
              if (error != null) ...[
                const SizedBox(height: AppTheme.space2),
                Text(
                  '生成失败：$error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppTheme.space3),
              FilledButton.icon(
                key: actionKey,
                onPressed: enabled ? onRequest : null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(error == null ? '生成 AI 深度解读' : '重新尝试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StructuredReadingView extends StatelessWidget {
  const _StructuredReadingView({required this.reading});

  final AiStructuredReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.space3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('一句话结论', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppTheme.space2),
              SelectableText(
                reading.headline,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        _section(context, '通俗解释', [reading.plainLanguage]),
        if (reading.evidence.isNotEmpty) ...[
          _title(context, '为什么这样判断'),
          ...reading.evidence.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space2),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppTheme.space1),
                    SelectableText(item.explanation),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (reading.risks.isNotEmpty) _section(context, '需要注意', reading.risks),
        if (reading.actions.isNotEmpty)
          _section(context, '建议怎么做', reading.actions, numbered: true),
        if (reading.boundary.isNotEmpty)
          _section(context, '适用边界', [reading.boundary]),
        if (reading.closing.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space3),
          Text(
            reading.closing,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _title(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(
      top: AppTheme.space4,
      bottom: AppTheme.space2,
    ),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _section(
    BuildContext context,
    String title,
    List<String> items, {
    bool numbered = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(context, title),
      ...items.indexed.map(
        (entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space2),
          child: SelectableText(
            items.length == 1
                ? entry.$2
                : '${numbered ? '${entry.$1 + 1}.' : '•'} ${entry.$2}',
          ),
        ),
      ),
    ],
  );
}
