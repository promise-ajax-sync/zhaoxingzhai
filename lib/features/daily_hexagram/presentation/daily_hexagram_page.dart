import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/interpretation/daily_hexagram_interpretation.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

class DailyHexagramPage extends StatefulWidget {
  const DailyHexagramPage({
    super.key,
    required this.currentCase,
    this.onResult,
    this.onResultWithQuestion,
    this.routedDraft,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  final CaseSnapshot? Function() currentCase;
  final Future<void> Function(DailyHexagramResult result)? onResult;
  final Future<void> Function(
    DailyHexagramResult result,
    DivinationQuestion question,
  )?
  onResultWithQuestion;
  final ValueListenable<RoutedDivinationDraft?>? routedDraft;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    DailyHexagramResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  @override
  State<DailyHexagramPage> createState() => _DailyHexagramPageState();
}

class _DailyHexagramPageState extends State<DailyHexagramPage> {
  DailyHexagramResult? _result;
  Object? _loadError;
  bool _loading = true;
  bool _manualMode = false;
  final List<List<int>> _manualCoins = List.generate(6, (_) => [3, 2, 2]);
  int _revealedLines = 6;
  int _revealGeneration = 0;
  final TextEditingController _questionController = TextEditingController();
  String _topic = 'general';
  RoutedDivinationDraft? _lastRoutedDraft;
  AiInterpretationResponse? _aiResponse;
  Object? _aiError;
  bool _aiLoading = false;
  int _aiGeneration = 0;

  DivinationQuestion get _question =>
      DivinationQuestion.parse(_questionController.text.trim(), topic: _topic);

  @override
  void initState() {
    super.initState();
    _applyRoutedDraft(widget.routedDraft?.value, notify: false);
    widget.routedDraft?.addListener(_onRoutedDraftChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant DailyHexagramPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routedDraft != widget.routedDraft) {
      oldWidget.routedDraft?.removeListener(_onRoutedDraftChanged);
      widget.routedDraft?.addListener(_onRoutedDraftChanged);
      _applyRoutedDraft(widget.routedDraft?.value);
    }
  }

  @override
  void dispose() {
    widget.routedDraft?.removeListener(_onRoutedDraftChanged);
    _questionController.dispose();
    super.dispose();
  }

  void _onRoutedDraftChanged() => _applyRoutedDraft(widget.routedDraft?.value);

  void _applyRoutedDraft(RoutedDivinationDraft? draft, {bool notify = true}) {
    if (draft == null ||
        draft.tool != DivinationTool.dailyHexagram ||
        identical(draft, _lastRoutedDraft)) {
      return;
    }
    _lastRoutedDraft = draft;
    void apply() {
      _questionController.text = draft.question;
      _topic = DivinationQuestion.inferTopic(draft.question);
      _aiResponse = null;
      _aiError = null;
      _aiLoading = false;
      _aiGeneration++;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

  Future<void> _load() async {
    try {
      await HexagramData.load();
      if (!mounted) return;
      await _acceptResult(
        DailyHexagramEngine.generate(caseKey: widget.currentCase()?.stableHash),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptResult(DailyHexagramResult result) async {
    final generation = ++_revealGeneration;
    if (mounted) {
      setState(() {
        _result = result;
        _loadError = null;
        _loading = false;
        _revealedLines = 0;
        _aiResponse = null;
        _aiError = null;
        _aiLoading = false;
        _aiGeneration++;
      });
    }
    await _persistResult(result);
    for (var count = 1; count <= 6; count++) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted || generation != _revealGeneration) return;
      setState(() => _revealedLines = count);
    }
  }

  Future<void> _persistResult(DailyHexagramResult result) async {
    try {
      if (widget.onResultWithQuestion != null) {
        await widget.onResultWithQuestion!(result, _question);
      } else {
        await widget.onResult?.call(result);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('解读已更新，但历史记录保存失败：$error')));
    }
  }

  Future<void> _refreshQuestionReading() async {
    final result = _result;
    if (result == null) {
      return;
    }
    setState(() {
      _aiResponse = null;
      _aiError = null;
      _aiLoading = false;
      _aiGeneration++;
    });
    await _persistResult(result);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已按当前问题更新解读，卦象保持不变')));
  }

  Future<void> _requestAiReading() async {
    final service = widget.aiService;
    final result = _result;
    final question = _question;
    if (service == null || result == null) {
      return;
    }
    final interpretation = DailyHexagramInterpretation.build(
      result,
      question: question,
    );
    final generation = ++_aiGeneration;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final response = await service.interpret(
        AiInterpretationRequest(
          question: question,
          evidence: interpretation.evidence,
          localAnswer: interpretation.directAnswer,
          methodLabel: '每日一卦',
          answerStyle: widget.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (!mounted || generation != _aiGeneration) {
        return;
      }
      setState(() {
        _aiResponse = response;
        _aiLoading = false;
      });
      await widget.onAiResponse?.call(result, response);
    } catch (error) {
      if (!mounted || generation != _aiGeneration) {
        return;
      }
      setState(() {
        _aiError = error;
        _aiLoading = false;
      });
    }
  }

  Future<void> _submitManual() => _acceptResult(
    DailyHexagramEngine.fromCoinThrows([
      for (final coins in _manualCoins)
        DailyHexagramCoinThrow(
          coins: List<int>.from(coins),
          total: coins.reduce((sum, coin) => sum + coin),
        ),
    ], caseKey: widget.currentCase()?.stableHash),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null || _result == null) {
      return AppPageContainer(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: '每日一卦加载失败',
          subtitle: _loadError.toString(),
        ),
      );
    }

    final result = _result!;
    final selectedCase = widget.currentCase();
    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeading(
            title: '每日一卦',
            subtitle: selectedCase == null
                ? '${result.dateKey} · 通用日卦'
                : '${result.dateKey} · ${selectedCase.displayName}',
          ),
          AppCard(
            child: TextField(
              key: const ValueKey('daily-hexagram-question-input'),
              controller: _questionController,
              onChanged: (value) => setState(() {
                _topic = DivinationQuestion.inferTopic(value);
                _aiResponse = null;
                _aiError = null;
                _aiLoading = false;
                _aiGeneration++;
              }),
              onSubmitted: (_) => _refreshQuestionReading(),
              decoration: InputDecoration(
                labelText: '今日关注的问题',
                hintText: '例如：今天工作上应该注意什么？',
                helperText: '问题用于调整解读重点，不改变当天卦象',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: '按当前问题更新解读',
                  onPressed: _refreshQuestionReading,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('今日自动卦')),
              ButtonSegment(value: true, label: Text('手动录入')),
            ],
            selected: {_manualMode},
            onSelectionChanged: (value) {
              setState(() => _manualMode = value.first);
            },
          ),
          if (_manualMode) ...[
            const SizedBox(height: AppTheme.space4),
            _ManualCoinInput(
              coins: _manualCoins,
              onChanged: (lineIndex, coinIndex, value) {
                setState(() => _manualCoins[lineIndex][coinIndex] = value);
              },
              onSubmit: _submitManual,
            ),
          ],
          const SizedBox(height: AppTheme.space4),
          AnimatedSwitcher(
            duration: AppTheme.motionSlow,
            child: _revealedLines == 6
                ? _HexagramOverview(
                    key: ValueKey(result.generatedAt.microsecondsSinceEpoch),
                    result: result,
                  )
                : Card(
                    key: const ValueKey('casting-progress'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      child: Text(
                        '正在形成卦象 · $_revealedLines / 6',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
          ),
          const AppSectionHeading(title: '六爻记录'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                children: [
                  for (var index = 5; index >= 0; index--)
                    AnimatedSwitcher(
                      duration: AppTheme.motionBase,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: index < _revealedLines
                          ? _YaoRow(
                              key: ValueKey('revealed-$index'),
                              index: index,
                              result: result,
                            )
                          : SizedBox(
                              key: ValueKey('hidden-$index'),
                              height: 35,
                            ),
                    ),
                ],
              ),
            ),
          ),
          const AppSectionHeading(title: '传统取用规则'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    result.takingRule.summary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.space3),
                  for (final text in result.takingRule.primaryTexts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space2),
                      child: Text('主取：$text'),
                    ),
                  for (final text in result.takingRule.secondaryTexts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.space2),
                      child: Text('辅看：$text'),
                    ),
                  if (result.movingLines.isNotEmpty) ...[
                    const Divider(height: AppTheme.space5),
                    Text('全部动爻', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppTheme.space2),
                    for (final line in result.movingLines)
                      Text('${line.name} · ${line.type.label}：${line.text}'),
                  ],
                ],
              ),
            ),
          ),
          if (_revealedLines == 6) ...[
            const AppSectionHeading(title: '分项解读'),
            _InterpretationCard(
              question: _question,
              interpretation: DailyHexagramInterpretation.build(
                result,
                question: _question,
              ),
            ),
            const AppSectionHeading(title: 'AI 深度解读'),
            AiInterpretationCard(
              response: _aiResponse,
              error: _aiError,
              loading: _aiLoading,
              enabled: widget.aiService != null,
              onRequest: _requestAiReading,
              loadingText: '正在结合问题和卦盘生成解读…',
              idleText: _question.rawText.isEmpty
                  ? '未填写具体问题，AI 将依据本卦、动爻、互卦和变卦生成通用解读。'
                  : 'AI 将使用当前问题和已计算的结构化证据生成进一步解读，不会重新起卦。',
              actionKey: const ValueKey('daily-hexagram-ai-reading'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard({
    required this.interpretation,
    required this.question,
  });

  final DailyHexagramInterpretation interpretation;
  final DivinationQuestion question;

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('传统概览', interpretation.traditionalOverview, Icons.menu_book_outlined),
      ('当前处境', interpretation.situation, Icons.center_focus_strong_outlined),
      ('内在条件', interpretation.innerContext, Icons.hub_outlined),
      ('变化趋势', interpretation.trend, Icons.trending_up_outlined),
      ('行动节奏', interpretation.pace, Icons.directions_walk_outlined),
      ('风险提醒', interpretation.riskReminder, Icons.shield_outlined),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (question.rawText.isNotEmpty) ...[
              Text('原问题：${question.rawText}'),
              const Divider(height: AppTheme.space5),
            ],
            Text(
              '问题回应 · ${interpretation.questionIntentLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.space1),
            Text(interpretation.directAnswer),
            const Divider(height: AppTheme.space5),
            for (var index = 0; index < sections.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    sections[index].$3,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sections[index].$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.space1),
                        Text(sections[index].$2),
                      ],
                    ),
                  ),
                ],
              ),
              if (index != sections.length - 1)
                const Divider(height: AppTheme.space5),
            ],
            Text('判断依据', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.space1),
            Text(interpretation.evidence.summary),
            const SizedBox(height: AppTheme.space2),
            for (final item in interpretation.evidence.supportingEvidence)
              Text('• ${item.label}：${item.detail}'),
            const SizedBox(height: AppTheme.space2),
            Text(
              '以上为基于本次卦盘的本地结构化整理，仅供参考，不构成决策建议。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HexagramOverview extends StatelessWidget {
  const _HexagramOverview({super.key, required this.result});

  final DailyHexagramResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space5),
        child: Column(
          children: [
            Text(
              result.original.symbol,
              style: TextStyle(
                fontSize: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '本卦 · ${result.original.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.space2),
            Text(result.original.description),
            const Divider(height: AppTheme.space6),
            Wrap(
              spacing: AppTheme.space6,
              runSpacing: AppTheme.space3,
              alignment: WrapAlignment.center,
              children: [
                _RelatedHexagram(label: '变卦', hexagram: result.changed),
                _RelatedHexagram(label: '互卦', hexagram: result.inter),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedHexagram extends StatelessWidget {
  const _RelatedHexagram({required this.label, required this.hexagram});

  final String label;
  final Hexagram hexagram;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text('${hexagram.symbol} ${hexagram.name}'),
        Text(
          '上${hexagram.upper}下${hexagram.lower}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _YaoRow extends StatelessWidget {
  const _YaoRow({super.key, required this.index, required this.result});

  final int index;
  final DailyHexagramResult result;

  @override
  Widget build(BuildContext context) {
    final yao = result.yaos[index];
    final throwResult = result.coinThrows[index];
    final name = const ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][index];
    final line = yao.isYang ? '━━━━━━' : '━━  ━━';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space1),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text(name)),
          Expanded(
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: yao.isMoving
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 116,
            child: Text(
              '${throwResult.coins.join('+')}=${yao.value} ${yao.label}',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualCoinInput extends StatelessWidget {
  const _ManualCoinInput({
    required this.coins,
    required this.onChanged,
    required this.onSubmit,
  });

  final List<List<int>> coins;
  final void Function(int lineIndex, int coinIndex, int value) onChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('依次录入初爻到上爻。点击每枚铜钱切换 2 / 3，系统自动计算爻值。'),
            const SizedBox(height: AppTheme.space3),
            for (var lineIndex = 0; lineIndex < 6; lineIndex++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
                child: Row(
                  children: [
                    SizedBox(width: 42, child: Text(names[lineIndex])),
                    for (var coinIndex = 0; coinIndex < 3; coinIndex++) ...[
                      _AnimatedCoin(
                        key: ValueKey('daily-coin-$lineIndex-$coinIndex'),
                        value: coins[lineIndex][coinIndex],
                        onTap: () => onChanged(
                          lineIndex,
                          coinIndex,
                          coins[lineIndex][coinIndex] == 2 ? 3 : 2,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space2),
                    ],
                    const Spacer(),
                    Builder(
                      builder: (context) {
                        final total = coins[lineIndex].reduce(
                          (sum, coin) => sum + coin,
                        );
                        final yao = DailyHexagramYaoType.fromValue(total);
                        return Text(
                          '${coins[lineIndex].join('+')}=$total · ${yao.label}',
                          key: ValueKey('daily-line-total-$lineIndex'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.space4),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('完成六爻并生成卦象'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCoin extends StatelessWidget {
  const _AnimatedCoin({super.key, required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '铜钱$value，点击切换',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Container(
            key: ValueKey(value),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value == 3
                  ? AppTheme.gold(context)
                  : AppTheme.accentSoft(context),
              border: Border.all(color: AppTheme.lineStrong(context)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value == 3
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
