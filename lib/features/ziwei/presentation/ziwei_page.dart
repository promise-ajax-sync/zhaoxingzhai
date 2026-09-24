import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/evidence/ziwei_evidence.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

enum _ZiweiDisplayLayer {
  natal('本命'),
  decade('大限'),
  annual('流年');

  const _ZiweiDisplayLayer(this.label);
  final String label;
}

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
  int? _selectedLunarYear;
  _ZiweiDisplayLayer _displayLayer = _ZiweiDisplayLayer.natal;

  Future<ZiweiChartResult>? _resultFuture(CaseSnapshot? subject) {
    if (subject == null) return null;
    final birthLunarYear = _birthLunarYear(subject);
    final selectedYear = _selectedLunarYear ?? _currentLunarYear();
    final targetYear = selectedYear < birthLunarYear
        ? birthLunarYear
        : selectedYear;
    _selectedLunarYear = targetYear;
    final key =
        '${subject.caseId}:${subject.birthDateTime.toIso8601String()}:'
        '${subject.calendarType.name}:${subject.isLeapMonth}:${subject.gender.name}:'
        '$targetYear';
    if (_future == null || key != _caseKey) {
      _caseKey = key;
      _future = ZiweiChartEngine.calculate(
        subject,
        targetLunarYear: targetYear,
      );
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
              const SizedBox(height: AppTheme.space3),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(
                      'ziwei-annual-year-${result.annual.lunarYear}',
                    ),
                    initialValue: result.annual.lunarYear,
                    decoration: const InputDecoration(labelText: '查看流年'),
                    items: [
                      for (
                        var year = result.foundation.lunarYear;
                        year <= result.foundation.lunarYear + 120;
                        year++
                      )
                        DropdownMenuItem(value: year, child: Text('$year 农历年')),
                    ],
                    onChanged: (year) {
                      if (year == null || year == _selectedLunarYear) return;
                      setState(() {
                        _selectedLunarYear = year;
                        _future = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              _layerSelector(),
              const SizedBox(height: AppTheme.space2),
              _layerDescription(result),
              const SizedBox(height: AppTheme.space3),
              _fixedPalaceChart(context, result),
              const SizedBox(height: AppTheme.space4),
              _annualCard(context, result),
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
                '流年按所选农历年计算太岁命宫与四化；流月、流日尚未接入，'
                '不作为现实吉凶保证。',
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
    final overlay = _layerOverlay(result, palace);
    final highlighted = _isLayerHighlighted(result, palace);
    return Semantics(
      key: ValueKey('ziwei-palace-${position.branch}'),
      container: true,
      label: _palaceSemanticLabel(result, palace),
      selected: highlighted,
      child: Card(
        color: highlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space2),
          child: SizedBox(
            height: 184,
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
                if (overlay != null) ...[
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    overlay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
      ),
    );
  }

  Widget _layerSelector() => Wrap(
    key: const ValueKey('ziwei-layer-selector'),
    spacing: AppTheme.space2,
    children: [
      for (final layer in _ZiweiDisplayLayer.values)
        Semantics(
          button: true,
          selected: _displayLayer == layer,
          label: '显示${layer.label}层',
          child: ChoiceChip(
            key: ValueKey('ziwei-layer-${layer.name}'),
            label: Text(layer.label),
            selected: _displayLayer == layer,
            onSelected: (_) => setState(() => _displayLayer = layer),
          ),
        ),
    ],
  );

  Widget _layerDescription(ZiweiChartResult result) {
    final annual = result.annual;
    final description = switch (_displayLayer) {
      _ZiweiDisplayLayer.natal => '本命层：高亮命宫，星曜、亮度和生年四化均来自出生盘。',
      _ZiweiDisplayLayer.decade =>
        annual.activeDecade == null
            ? '大限层：当前虚岁尚在童限，暂无大限宫位。'
            : '大限层：高亮${annual.activeDecade!.palace.name}，显示当前限宫四化。',
      _ZiweiDisplayLayer.annual =>
        '流年层：高亮${annual.yearStem}${annual.yearBranch}年太岁命宫，标记流年十二宫与四化。',
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        description,
        key: const ValueKey('ziwei-layer-description'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _fixedPalaceChart(BuildContext context, ZiweiChartResult result) {
    const gridIndexes = [9, 8, 7, 6, 10, -1, -2, 5, 11, -3, -4, 4, 0, 1, 2, 3];
    final byIndex = {
      for (final palace in result.palaces) palace.position.index: palace,
    };
    return Card(
      key: const ValueKey('ziwei-fixed-palace-chart'),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2),
        child: Semantics(
          container: true,
          label: '紫微十二宫固定方位盘，可横向滚动查看完整盘面',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 960,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridIndexes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, gridIndex) {
                  final palaceIndex = gridIndexes[gridIndex];
                  if (palaceIndex >= 0) {
                    return _palaceCard(context, result, byIndex[palaceIndex]!);
                  }
                  return _chartCenterCell(context, result, palaceIndex);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartCenterCell(
    BuildContext context,
    ZiweiChartResult result,
    int slot,
  ) {
    final annual = result.annual;
    final active = annual.activeDecade;
    final (title, content) = switch (slot) {
      -1 => ('角色', result.foundation.subject.displayName),
      -2 => (
        '本命',
        '${result.yearStem}${result.yearBranch} · ${result.foundation.fiveElementBureau}',
      ),
      -3 => (
        '大限',
        active == null
            ? '童限或未确定'
            : '${active.startNominalAge}—${active.endNominalAge}岁 ${active.palace.name}',
      ),
      _ => (
        '流年',
        '${annual.lunarYear} ${annual.yearStem}${annual.yearBranch} · 虚岁${annual.nominalAge}',
      ),
    };
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.space2),
            Text(content, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  bool _isLayerHighlighted(ZiweiChartResult result, ZiweiChartPalace palace) =>
      switch (_displayLayer) {
        _ZiweiDisplayLayer.natal => palace.position.isLife,
        _ZiweiDisplayLayer.decade =>
          result.annual.activeDecade?.palace.index == palace.position.index,
        _ZiweiDisplayLayer.annual =>
          result.annual.lifePalace.index == palace.position.index,
      };

  String? _layerOverlay(ZiweiChartResult result, ZiweiChartPalace palace) {
    switch (_displayLayer) {
      case _ZiweiDisplayLayer.natal:
        return palace.position.isLife ? '本命命宫' : null;
      case _ZiweiDisplayLayer.decade:
        final active = result.annual.activeDecade;
        if (active == null || active.palace.index != palace.position.index) {
          return null;
        }
        final transformations = result.decadeTransformations
            .singleWhere((item) => item.limit.order == active.order)
            .placements
            .map((item) => '${item.starName}化${item.mutagen}')
            .join('、');
        return '当前大限 · $transformations';
      case _ZiweiDisplayLayer.annual:
        final annualPalace = result.annual.palaces.singleWhere(
          (item) => item.position.index == palace.position.index,
        );
        final transformations = result.annual.transformations
            .where((item) => item.destination.index == palace.position.index)
            .map((item) => '${item.starName}化${item.mutagen}')
            .join('、');
        return transformations.isEmpty
            ? '流年${annualPalace.name}'
            : '流年${annualPalace.name} · $transformations';
    }
  }

  String _palaceSemanticLabel(
    ZiweiChartResult result,
    ZiweiChartPalace palace,
  ) {
    final position = palace.position;
    final stars = palace.stars.isEmpty
        ? '无基础星曜'
        : palace.stars
              .map((star) {
                final brightness = star.brightness == null
                    ? ''
                    : '${star.brightness}地';
                final mutagen = star.mutagen == null ? '' : '化${star.mutagen}';
                return '${star.name}$brightness$mutagen';
              })
              .join('，');
    final overlay = _layerOverlay(result, palace);
    return '${position.name}，${position.ganzhi}，'
        '${position.isLife ? '本命命宫，' : ''}'
        '${position.isBody ? '身宫，' : ''}'
        '${overlay == null ? '' : '$overlay，'}'
        '$stars';
  }

  String _decadeMutagens(ZiweiChartResult result, int order) {
    final transformation = result.decadeTransformations.singleWhere(
      (e) => e.limit.order == order,
    );
    return transformation.placements
        .map((e) => '${e.starName}化${e.mutagen}入${e.destination.name}')
        .join('、');
  }

  Widget _annualCard(BuildContext context, ZiweiChartResult result) {
    final annual = result.annual;
    final active = annual.activeDecade;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('流年', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.space2),
            Text(
              '${annual.lunarYear} 农历年 · ${annual.yearStem}${annual.yearBranch} · '
              '虚岁 ${annual.nominalAge} · 流年命宫${annual.lifePalace.name}'
              '（${annual.lifePalace.branch}）',
            ),
            Text(
              active == null
                  ? '当前处于童限或大限未确定'
                  : '当前大限：${active.startNominalAge}—${active.endNominalAge}岁 '
                        '${active.palace.name}（${active.palace.branch}）',
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              '流年四化：${annual.transformations.map((e) => '${e.starName}化${e.mutagen}入${e.destination.name}').join('、')}',
            ),
            const SizedBox(height: AppTheme.space2),
            Wrap(
              spacing: AppTheme.space3,
              runSpacing: AppTheme.space2,
              children: [
                for (final palace in annual.palaces)
                  Text(
                    '${palace.name}→${palace.position.name}（${palace.position.branch}）',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static int _currentLunarYear() {
    final now = DateTime.now();
    return Solar.fromYmd(now.year, now.month, now.day).getLunar().getYear();
  }

  static int _birthLunarYear(CaseSnapshot subject) {
    final value = subject.birthDateTime;
    if (subject.calendarType == CaseCalendarType.lunar) return value.year;
    return Solar.fromYmd(
      value.year,
      value.month,
      value.day,
    ).getLunar().getYear();
  }
}
