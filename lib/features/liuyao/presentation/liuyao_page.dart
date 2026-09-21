import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/engine/liuyao/liuyao_divination.dart';
import 'package:zhaoxingzhai/core/evidence/liuyao_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

class LiuyaoPage extends StatefulWidget {
  const LiuyaoPage({
    super.key,
    this.onResult,
    this.routedDraft,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  final Future<void> Function(LiuyaoResult result)? onResult;
  final ValueListenable<RoutedDivinationDraft?>? routedDraft;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    LiuyaoResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  @override
  State<LiuyaoPage> createState() => _LiuyaoPageState();
}

class _LiuyaoPageState extends State<LiuyaoPage> {
  final _questionController = TextEditingController();
  final _values = List<int>.filled(6, 7);
  LiuyaoResult? _result;
  LiuyaoRelation? _focusRelation;
  bool _saving = false;
  bool _aiLoading = false;
  Object? _aiError;
  AiInterpretationResponse? _aiResponse;

  @override
  void initState() {
    super.initState();
    widget.routedDraft?.addListener(_applyRoutedDraft);
    _applyRoutedDraft();
  }

  void _applyRoutedDraft() {
    final draft = widget.routedDraft?.value;
    if (draft == null || draft.tool != DivinationTool.liuyao) {
      return;
    }
    _questionController.text = draft.question;
  }

  @override
  void dispose() {
    widget.routedDraft?.removeListener(_applyRoutedDraft);
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _create({required bool manual}) async {
    setState(() => _saving = true);
    try {
      final result = manual
          ? LiuyaoEngine.fromYaoValues(
              _values,
              question: _questionController.text,
              focusRelation: _focusRelation,
            )
          : LiuyaoEngine.generate(
              question: _questionController.text,
              focusRelation: _focusRelation,
            );
      await widget.onResult?.call(result);
      if (mounted) {
        setState(() {
          _result = result;
          _aiResponse = null;
          _aiError = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _requestAiReading() async {
    final service = widget.aiService;
    final result = _result;
    if (service == null || result == null) {
      return;
    }
    final question = DivinationQuestion.parse(result.question);
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final response = await service.interpret(
        AiInterpretationRequest(
          question: question,
          evidence: LiuyaoEvidenceBuilder.build(result, question),
          localAnswer:
              '${result.base.original.name}变${result.base.changed.name}，'
              '${result.base.original.palace}宫${result.palaceStage}，'
              '世爻在${result.shiPosition}爻，应爻在${result.yingPosition}爻。',
          methodLabel: '六爻排盘',
          answerStyle: widget.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _aiResponse = response;
        _aiLoading = false;
      });
      await widget.onAiResponse?.call(result, response);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _aiError = error;
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppTheme.space4),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('六爻排盘', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppTheme.space2),
            const Text('采用三枚铜钱法，排出本卦、变卦、互卦、错卦、综卦，并计算纳甲、六亲、六神、世应与旬空。'),
            const SizedBox(height: AppTheme.space4),
            TextField(
              controller: _questionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '占问（可选）',
                hintText: '一次只问一件具体事情',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            DropdownButtonFormField<LiuyaoRelation?>(
              initialValue: _focusRelation,
              decoration: const InputDecoration(
                labelText: '用神/观察重点（可选）',
                helperText: '不确定时保持“不指定”，不要仅凭关键词武断取用。',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<LiuyaoRelation?>(
                  value: null,
                  child: Text('不指定'),
                ),
                for (final relation in LiuyaoRelation.values)
                  DropdownMenuItem<LiuyaoRelation?>(
                    value: relation,
                    child: Text(relation.label),
                  ),
              ],
              onChanged: (value) => setState(() => _focusRelation = value),
            ),
            const SizedBox(height: AppTheme.space4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '手动录入',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.space2),
                    const Text('按初爻到上爻选择：6 老阴、7 少阳、8 少阴、9 老阳。'),
                    const SizedBox(height: AppTheme.space3),
                    for (var index = 0; index < 6; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(_lineName(index + 1)),
                            ),
                            Expanded(
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment(value: 6, label: Text('6 老阴')),
                                  ButtonSegment(value: 7, label: Text('7 少阳')),
                                  ButtonSegment(value: 8, label: Text('8 少阴')),
                                  ButtonSegment(value: 9, label: Text('9 老阳')),
                                ],
                                selected: {_values[index]},
                                onSelectionChanged: (value) => setState(
                                  () => _values[index] = value.single,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppTheme.space2),
                    Wrap(
                      spacing: AppTheme.space3,
                      runSpacing: AppTheme.space2,
                      children: [
                        FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _create(manual: true),
                          icon: const Icon(Icons.table_chart_outlined),
                          label: const Text('按录入值排盘'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _create(manual: false),
                          icon: const Icon(Icons.casino_outlined),
                          label: const Text('自动摇卦'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: AppTheme.space4),
              _ResultView(result: _result!),
              const SizedBox(height: AppTheme.space4),
              AiInterpretationCard(
                response: _aiResponse,
                loading: _aiLoading,
                error: _aiError,
                enabled: widget.aiService != null,
                onRequest: _requestAiReading,
                loadingText: '正在结合纳甲、世应、六亲和动爻生成解读…',
                idleText: 'AI 将读取已经计算完成的结构化卦盘，不会重新起卦。',
                actionKey: const ValueKey('liuyao-ai-reading'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  static String _lineName(int position) =>
      const ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][position - 1];
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final LiuyaoResult result;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${result.base.original.symbol} ${result.base.original.name} → ${result.base.changed.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '${result.base.original.palace}宫${result.palaceElement} · ${result.palaceStage} · '
            '${result.calendar.solarTermMonthGanzhi}月 ${result.calendar.dayGanzhi}日 '
            '${result.calendar.hourGanzhi}时 · 旬空${result.voidBranches.join('')}',
          ),
          if (result.focusRelation != null)
            Text('本次观察重点：${result.focusRelation!.label}'),
          const Divider(height: AppTheme.space5),
          for (final line in result.lines.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
              child: Row(
                children: [
                  SizedBox(width: 42, child: Text(line.spirit)),
                  SizedBox(width: 44, child: Text(line.relation.label)),
                  SizedBox(
                    width: 62,
                    child: Text('${line.ganZhi}${line.element}'),
                  ),
                  Expanded(child: _YaoBar(line: line)),
                  SizedBox(
                    width: 92,
                    child: Text(
                      [
                        if (line.isShi) '世',
                        if (line.isYing) '应',
                        if (line.isVoid) '空',
                        if (line.yao.isMoving) '动',
                      ].join(' · '),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: AppTheme.space5),
          Text(
            '互卦：${result.base.inter.name} · 错卦：${result.opposite.name} · 综卦：${result.reversed.name}',
          ),
          const SizedBox(height: AppTheme.space2),
          Text(result.base.takingRule.summary),
          const SizedBox(height: AppTheme.space3),
          const Text('说明：排盘结果用于传统文化研究与个人反思，不替代医疗、法律、投资等专业意见。'),
        ],
      ),
    ),
  );
}

class _YaoBar extends StatelessWidget {
  const _YaoBar({required this.line});

  final LiuyaoLine line;

  @override
  Widget build(BuildContext context) {
    final color = line.yao.isMoving
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: line.yao.isYang
          ? [Container(width: 86, height: 8, color: color)]
          : [
              Container(width: 38, height: 8, color: color),
              const SizedBox(width: 10),
              Container(width: 38, height: 8, color: color),
            ],
    );
  }
}
