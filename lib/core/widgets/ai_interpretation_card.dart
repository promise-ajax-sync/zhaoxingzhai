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
                onPressed: onRequest,
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
