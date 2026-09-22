import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/engine/bazi/bazi_divination.dart';
import 'package:zhaoxingzhai/core/evidence/bazi_evidence.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

class BaziPage extends StatelessWidget {
  const BaziPage({
    super.key,
    required this.currentCase,
    this.onResult,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  final CaseSnapshot? Function() currentCase;
  final Future<void> Function(BaziResult result)? onResult;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    BaziResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  @override
  Widget build(BuildContext context) {
    final subject = currentCase();
    if (subject == null) {
      return const Center(child: Text('请先在角色页面选择一个有出生时间的角色。'));
    }
    final result = BaziEngine.calculate(subject);
    return _BaziContent(result: result, page: this);
  }
}

class _BaziContent extends StatefulWidget {
  const _BaziContent({required this.result, required this.page});
  final BaziResult result;
  final BaziPage page;
  @override
  State<_BaziContent> createState() => _BaziContentState();
}

class _BaziContentState extends State<_BaziContent> {
  AiInterpretationResponse? _response;
  Object? _error;
  bool _loading = false;

  Future<void> _interpret() async {
    final service = widget.page.aiService;
    if (service == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final question = const DivinationQuestion(
        rawText: '',
        topic: 'general',
        intent: DivinationQuestionIntent.general,
      );
      final response = await service.interpret(
        AiInterpretationRequest(
          question: question,
          evidence: BaziEvidenceBuilder.build(widget.result, question),
          localAnswer:
              '日主${widget.result.dayMaster}，四柱为${widget.result.pillars.map((p) => p.ganzhi).join('、')}。',
          methodLabel: '四柱八字',
          answerStyle: widget.page.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (!mounted) return;
      setState(() {
        _response = response;
        _loading = false;
      });
      await widget.page.onAiResponse?.call(widget.result, response);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('四柱八字', style: Theme.of(context).textTheme.headlineMedium),
              Text(
                '${result.subject.displayName} · ${_dateTime(result.inputCivilTime)}',
              ),
              if (result.usedLunarConversion) ...[
                Text('农历已换算为公历：${_dateTime(result.solarCivilTime)}'),
              ],
              if (result.usedTrueSolarTime) ...[
                Text(
                  '真太阳时：${_dateTime(result.calculationTime)}（修正 ${result.trueSolarCorrectionMinutes!.toStringAsFixed(1)} 分钟）',
                ),
              ],
              const SizedBox(height: AppTheme.space4),
              _section(
                context,
                '命盘',
                Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: AppTheme.space4,
                  runSpacing: AppTheme.space4,
                  children: [
                    for (final pillar in result.pillars)
                      SizedBox(
                        width: 150,
                        child: Column(
                          children: [
                            Text(pillar.name),
                            Text(
                              pillar.ganzhi,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text('${pillar.stemTenGod} · ${pillar.wuxing}'),
                            Text('藏干：${pillar.hiddenStems.join('、')}'),
                            Text('藏干十神：${pillar.hiddenTenGods.join('、')}'),
                            Text('${pillar.nayin} · ${pillar.lifeStage}'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              _section(
                context,
                '命局摘要',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('日主：${result.dayMaster}'),
                    Text(
                      '胎元：${result.taiYuan} · 命宫：${result.mingGong} · 身宫：${result.shenGong}',
                    ),
                    Text(
                      '大运：${result.forwardLuck ? '顺排' : '逆排'} · 起运 ${result.luckStart}',
                    ),
                    const SizedBox(height: AppTheme.space2),
                    Wrap(
                      spacing: AppTheme.space3,
                      children: [
                        for (final e in result.elementCounts.entries)
                          Text('${e.key.label}：${e.value}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              _section(
                context,
                '大运',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final cycle in result.luckCycles)
                      Text(
                        '${cycle.startAge}—${cycle.endAge}岁（${cycle.startYear}—${cycle.endYear}）：${cycle.ganzhi}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              const Text('说明：排盘采用确定性历法规则，用于传统文化研究和自我观察，不替代医疗、法律、财务或其他专业判断。'),
              const SizedBox(height: AppTheme.space3),
              FilledButton.icon(
                onPressed: widget.page.onResult == null
                    ? null
                    : () => widget.page.onResult!(result),
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存八字记录'),
              ),
              const SizedBox(height: AppTheme.space3),
              OutlinedButton.icon(
                onPressed: _loading ? null : _interpret,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(_loading ? '正在生成八字解读…' : '生成 AI 八字解读'),
              ),
              if (_error != null) Text('解读失败：$_error'),
              AiInterpretationCard(
                response: _response,
                loading: _loading,
                error: _error,
                onRequest: _interpret,
                loadingText: '正在生成八字解读…',
                idleText: '生成 AI 八字解读',
                actionKey: const ValueKey('bazi-ai-reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _section(BuildContext context, String title, Widget child) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppTheme.space3),
              child,
            ],
          ),
        ),
      );

  static String _dateTime(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
