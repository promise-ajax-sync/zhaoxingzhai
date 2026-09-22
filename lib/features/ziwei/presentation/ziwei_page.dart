import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/evidence/ziwei_evidence.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

class ZiweiPage extends StatefulWidget {
  const ZiweiPage({
    super.key,
    required this.currentCase,
    this.onResult,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  final CaseSnapshot? Function() currentCase;
  final Future<void> Function(ZiweiChartResult result)? onResult;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    ZiweiChartResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  @override
  State<ZiweiPage> createState() => _ZiweiPageState();
}

class _ZiweiPageState extends State<ZiweiPage> {
  Future<ZiweiChartResult>? _future;
  String? _caseKey;
  AiInterpretationResponse? _response;
  Object? _aiError;
  bool _aiLoading = false;

  Future<ZiweiChartResult>? _resultFuture(CaseSnapshot? subject) {
    if (subject == null) return null;
    final key =
        '${subject.caseId}:${subject.birthDateTime.toIso8601String()}:'
        '${subject.calendarType.name}:${subject.isLeapMonth}:${subject.gender.name}';
    if (_future == null || key != _caseKey) {
      _caseKey = key;
      _future = ZiweiChartEngine.calculate(subject);
      _response = null;
      _aiError = null;
    }
    return _future;
  }

  Future<void> _interpret(ZiweiChartResult result) async {
    final service = widget.aiService;
    if (service == null) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      const question = DivinationQuestion(
        rawText: '',
        topic: 'general',
        intent: DivinationQuestionIntent.general,
      );
      final response = await service.interpret(
        AiInterpretationRequest(
          question: question,
          evidence: ZiweiEvidenceBuilder.build(result, question),
          localAnswer:
              '命宫在${result.foundation.lifeBranch}，身宫在${result.foundation.bodyBranch}，为${result.foundation.fiveElementBureau}。',
          methodLabel: '紫微斗数',
          answerStyle: widget.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (!mounted) return;
      setState(() {
        _response = response;
        _aiLoading = false;
      });
      await widget.onAiResponse?.call(result, response);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aiError = error;
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.currentCase();
    final future = _resultFuture(subject);
    if (future == null) {
      return const Center(child: Text('请先在角色页面选择一个有出生时间的角色。'));
    }
    return FutureBuilder<ZiweiChartResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('紫微排盘失败：${snapshot.error}'));
        }
        final result = snapshot.data;
        if (result == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _content(context, result);
      },
    );
  }

  Widget _content(BuildContext context, ZiweiChartResult result) {
    final subject = result.foundation.subject;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('紫微斗数', style: Theme.of(context).textTheme.headlineMedium),
              Text(
                '${subject.displayName} · ${result.yearStem}${result.yearBranch}年 · '
                '命宫${result.foundation.lifeBranch} · 身宫${result.foundation.bodyBranch} · '
                '${result.foundation.fiveElementBureau}',
              ),
              const SizedBox(height: AppTheme.space4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 900
                      ? (constraints.maxWidth - 3 * AppTheme.space3) / 4
                      : constraints.maxWidth >= 600
                      ? (constraints.maxWidth - AppTheme.space3) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppTheme.space3,
                    runSpacing: AppTheme.space3,
                    children: [
                      for (final palace in result.palaces)
                        SizedBox(
                          width: width,
                          child: _palaceCard(context, result, palace),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTheme.space4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('大限', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.space2),
                      if (result.limits.decades.isEmpty)
                        const Text('角色性别未指定，无法确定大限顺逆。')
                      else
                        Wrap(
                          spacing: AppTheme.space4,
                          runSpacing: AppTheme.space2,
                          children: [
                            for (final limit in result.limits.decades)
                              SizedBox(
                                width: 310,
                                child: Text(
                                  '${limit.startNominalAge}—${limit.endNominalAge}岁 '
                                  '${limit.palace.name}（${limit.palace.branch}） · '
                                  '${_decadeMutagens(result, limit.order)}',
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              const Text(
                '当前版本展示确定性命身宫、28 星、生年四化和大限宫位。'
                '全书系七档亮度表覆盖 20 星，未收录星曜不混补；'
                '流年流月尚未接入，不作为现实吉凶保证。',
              ),
              const SizedBox(height: AppTheme.space3),
              FilledButton.icon(
                onPressed: widget.onResult == null
                    ? null
                    : () => widget.onResult!(result),
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存紫微记录'),
              ),
              const SizedBox(height: AppTheme.space3),
              AiInterpretationCard(
                response: _response,
                loading: _aiLoading,
                error: _aiError,
                onRequest: () => _interpret(result),
                loadingText: '正在生成紫微解读…',
                idleText: '生成 AI 紫微解读',
                actionKey: const ValueKey('ziwei-ai-reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _palaceCard(
    BuildContext context,
    ZiweiChartResult result,
    ZiweiChartPalace palace,
  ) {
    final position = palace.position;
    final relations = result.relations.singleWhere(
      (e) => e.source.index == position.index,
    );
    final markers = [
      if (position.isLife) '命',
      if (position.isBody) '身',
    ].join('·');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space3),
        child: SizedBox(
          height: 178,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${position.name} · ${position.ganzhi}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (markers.isNotEmpty) Chip(label: Text(markers)),
                ],
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                '三方 ${relations.trines.map((e) => e.name).join('·')} · '
                '对宫 ${relations.opposite.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space2),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppTheme.space2,
                    runSpacing: AppTheme.space2,
                    children: [
                      if (palace.stars.isEmpty) const Text('暂无基础星曜'),
                      for (final star in palace.stars)
                        Text(
                          star.mutagen == null
                              ? '${star.name}${star.brightness == null ? '' : '（${star.brightness}）'}'
                              : '${star.name}${star.brightness == null ? '' : '（${star.brightness}）'}化${star.mutagen}',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _decadeMutagens(ZiweiChartResult result, int order) {
    final transformation = result.decadeTransformations.singleWhere(
      (e) => e.limit.order == order,
    );
    return transformation.placements
        .map((e) => '${e.starName}化${e.mutagen}入${e.destination.name}')
        .join('、');
  }
}
