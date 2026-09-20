import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';
import 'package:zhaoxingzhai/features/compatibility/domain/compatibility_result.dart';

class CompatibilityPage extends StatefulWidget {
  const CompatibilityPage({
    super.key,
    required this.repository,
    this.aiService,
    this.answerStyle,
    this.onResult,
    this.onAiResponse,
    this.onOpenCases,
  });

  final CaseRepository repository;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(CompatibilityResult result)? onResult;
  final Future<void> Function(
    CompatibilityResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;
  final VoidCallback? onOpenCases;

  @override
  State<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends State<CompatibilityPage> {
  String? _firstId;
  String? _secondId;
  CompatibilityRelation _relation = CompatibilityRelation.romance;
  CompatibilityResult? _result;
  AiInterpretationResponse? _aiResponse;
  Object? _aiError;
  bool _aiLoading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_repositoryChanged);
    widget.repository.ensureLoaded().then((_) {
      if (mounted) _repositoryChanged();
    });
  }

  @override
  void didUpdateWidget(covariant CompatibilityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_repositoryChanged);
      widget.repository.addListener(_repositoryChanged);
      _repositoryChanged();
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_repositoryChanged);
    super.dispose();
  }

  void _repositoryChanged() {
    final cases = widget.repository.cases;
    setState(() {
      if (!cases.any((item) => item.id == _firstId)) {
        _firstId = cases.isEmpty ? null : cases.first.id;
      }
      if (!cases.any((item) => item.id == _secondId) || _secondId == _firstId) {
        final alternatives = cases.where((item) => item.id != _firstId);
        _secondId = alternatives.isEmpty ? null : alternatives.first.id;
      }
      _result = null;
      _resetAi();
    });
  }

  void _resetAi() {
    _aiResponse = null;
    _aiError = null;
    _aiLoading = false;
    _generation++;
  }

  Future<void> _calculate() async {
    final first = widget.repository.findById(_firstId ?? '');
    final second = widget.repository.findById(_secondId ?? '');
    if (first == null || second == null || first.id == second.id) return;
    final result = CompatibilityResult.build(
      first: first.toSnapshot(),
      second: second.toSnapshot(),
      relation: _relation,
    );
    setState(() {
      _result = result;
      _resetAi();
    });
    await widget.onResult?.call(result);
  }

  Future<void> _requestAi() async {
    final service = widget.aiService;
    final result = _result;
    if (service == null || result == null) return;
    final generation = ++_generation;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final response = await service.interpret(
        AiInterpretationRequest(
          question: DivinationQuestion.parse('', topic: 'relationship'),
          evidence: result.evidence,
          localAnswer: result.localAnswer,
          methodLabel: '合盘',
          answerStyle: widget.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _aiResponse = response;
        _aiLoading = false;
      });
      await widget.onAiResponse?.call(result, response);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _aiError = error;
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = widget.repository.cases;
    if (!widget.repository.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeading(
            title: '基础关系合盘',
            subtitle: '选择两个角色，从传统生肖、五行与生活节奏角度整理关系中的优势和磨合重点',
          ),
          if (cases.length < 2)
            AppEmptyState(
              icon: Icons.people_outline,
              title: '至少需要两个角色',
              subtitle: '合盘必须比较两个不同角色，请先在角色页补充双方资料。',
              action: FilledButton.icon(
                onPressed: widget.onOpenCases,
                icon: const Icon(Icons.add),
                label: const Text('前往角色页'),
              ),
            )
          else ...[
            _SelectorCard(
              cases: cases,
              firstId: _firstId,
              secondId: _secondId,
              relation: _relation,
              onFirstChanged: (value) => setState(() {
                _firstId = value;
                if (_secondId == value) {
                  _secondId = cases.where((item) => item.id != value).first.id;
                }
                _result = null;
                _resetAi();
              }),
              onSecondChanged: (value) => setState(() {
                _secondId = value;
                _result = null;
                _resetAi();
              }),
              onRelationChanged: (value) => setState(() {
                _relation = value;
                _result = null;
                _resetAi();
              }),
              onCalculate: _calculate,
            ),
            if (_result case final result?) ...[
              const SizedBox(height: AppTheme.space4),
              _ResultOverview(result: result),
              const SizedBox(height: AppTheme.space4),
              _ResultSections(result: result),
              const AppSectionHeading(title: '小兆深度解读'),
              AiInterpretationCard(
                response: _aiResponse,
                loading: _aiLoading,
                error: _aiError,
                onRequest: _requestAi,
                loadingText: '小兆正在整理双方关系中的优势、摩擦与现实建议…',
                idleText: '本地合盘已经完成。需要时可让小兆用更自然的白话进一步梳理。',
                disabledText: '本地合盘已经完成；当前未配置 AI 服务，其他内容仍可正常使用。',
                actionKey: const ValueKey('compatibility-ai-reading'),
                enabled: widget.aiService != null,
              ),
            ],
          ],
          const SizedBox(height: AppTheme.space4),
          AppCard(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const Text(
              '当前为基础关系合盘，仅使用生肖、年干五行与出生季节进行传统文化视角的关系整理。'
              '协调指数不是成功率，也不能证明感情结果、合作成败或他人的真实想法。'
              '重要关系决策仍应依据现实沟通、行为、责任与边界。',
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.cases,
    required this.firstId,
    required this.secondId,
    required this.relation,
    required this.onFirstChanged,
    required this.onSecondChanged,
    required this.onRelationChanged,
    required this.onCalculate,
  });

  final List<CaseProfile> cases;
  final String? firstId;
  final String? secondId;
  final CompatibilityRelation relation;
  final ValueChanged<String> onFirstChanged;
  final ValueChanged<String> onSecondChanged;
  final ValueChanged<CompatibilityRelation> onRelationChanged;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                key: const ValueKey('compatibility-first-case'),
                initialValue: firstId,
                decoration: const InputDecoration(labelText: '角色一'),
                items: [
                  for (final item in cases)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (value) {
                  if (value != null) onFirstChanged(value);
                },
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                key: ValueKey('compatibility-second-case-$firstId'),
                initialValue: secondId,
                decoration: const InputDecoration(labelText: '角色二'),
                items: [
                  for (final item in cases.where((item) => item.id != firstId))
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: (value) {
                  if (value != null) onSecondChanged(value);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<CompatibilityRelation>(
                key: const ValueKey('compatibility-relation'),
                initialValue: relation,
                decoration: const InputDecoration(labelText: '关系类型'),
                items: [
                  for (final item in CompatibilityRelation.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: (value) {
                  if (value != null) onRelationChanged(value);
                },
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('compatibility-calculate'),
              onPressed: secondId == null ? null : onCalculate,
              icon: const Icon(Icons.favorite_border),
              label: const Text('开始合盘'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ResultOverview extends StatelessWidget {
  const _ResultOverview({required this.result});
  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) => AppCard(
    color: Theme.of(context).colorScheme.primaryContainer
        .withValues(alpha: 0.4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 38,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${result.score}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('协调指数', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.headline,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(result.overview),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      '${result.first.displayName} · 属${result.firstZodiac} · ${result.firstElement}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${result.second.displayName} · 属${result.secondZodiac} · ${result.secondElement}',
                    ),
                  ),
                  Chip(label: Text(result.relation.label)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultSections extends StatelessWidget {
  const _ResultSections({required this.result});
  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ListCard(
        title: '相处优势',
        icon: Icons.favorite_border,
        items: result.strengths,
      ),
      const SizedBox(height: 12),
      _ListCard(
        title: '磨合重点',
        icon: Icons.sync_problem_outlined,
        items: result.frictions,
      ),
      const SizedBox(height: 12),
      _ListCard(
        title: '现实建议',
        icon: Icons.task_alt_outlined,
        items: result.actions,
        numbered: true,
      ),
    ],
  );
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.icon,
    required this.items,
    this.numbered = false,
  });
  final String title;
  final IconData icon;
  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${numbered ? '${entry.$1 + 1}.' : '•'} ${entry.$2}'),
          ),
      ],
    ),
  );
}
