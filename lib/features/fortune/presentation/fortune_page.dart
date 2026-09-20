import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/fortune/domain/today_fortune.dart';

class FortunePage extends StatefulWidget {
  const FortunePage({
    super.key,
    this.initialDate,
    this.currentCase,
    this.aiService,
    this.answerStyle,
    this.onResult,
    this.onAiResponse,
  });

  final DateTime? initialDate;
  final CaseSnapshot? Function()? currentCase;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(TodayFortune result, CaseSnapshot? currentCase)?
  onResult;
  final Future<void> Function(
    TodayFortune result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  @override
  State<FortunePage> createState() => _FortunePageState();
}

class _FortunePageState extends State<FortunePage> {
  late DateTime _date;
  AiInterpretationResponse? _aiResponse;
  Object? _aiError;
  bool _aiLoading = false;
  int _aiGeneration = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
  }

  TodayFortune get _fortune =>
      TodayFortune.build(_date, caseSnapshot: widget.currentCase?.call());

  Future<void> _saveCurrent() async {
    await widget.onResult?.call(_fortune, widget.currentCase?.call());
    if (mounted) {
      setState(() => _saved = true);
    }
  }

  void _selectDate(DateTime value) {
    final candidate = DateTime(value.year, value.month, value.day);
    if (candidate.isBefore(DateTime(1900)) ||
        candidate.isAfter(DateTime(2100, 12, 31))) {
      return;
    }
    setState(() {
      _date = candidate;
      _aiResponse = null;
      _aiError = null;
      _aiLoading = false;
      _aiGeneration++;
      _saved = false;
    });
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      helpText: '选择日运日期',
    );
    if (value != null && mounted) {
      _selectDate(value);
    }
  }

  Future<void> _requestAiReading() async {
    final service = widget.aiService;
    if (service == null) {
      return;
    }
    final fortune = _fortune;
    final generation = ++_aiGeneration;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      if (!_saved) {
        await _saveCurrent();
      }
      final response = await service.interpret(
        AiInterpretationRequest(
          question: DivinationQuestion.parse('', topic: 'fortune'),
          evidence: fortune.evidence,
          localAnswer: fortune.localAnswer,
          methodLabel: '今日运势',
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
      await widget.onAiResponse?.call(fortune, response);
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

  @override
  Widget build(BuildContext context) {
    final fortune = _fortune;
    final currentCase = widget.currentCase?.call();
    final colors = Theme.of(context).colorScheme;
    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeading(
            title: '今日运势',
            subtitle: currentCase == null
                ? '${fortune.dateKey} · 通用日运'
                : '${fortune.dateKey} · ${currentCase.displayName} · 属${fortune.zodiac}',
            trailing: TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('选择日期'),
            ),
          ),
          _DateNavigator(
            fortune: fortune,
            onPrevious: () =>
                _selectDate(_date.subtract(const Duration(days: 1))),
            onToday: () => _selectDate(DateTime.now()),
            onNext: () => _selectDate(_date.add(const Duration(days: 1))),
            onSave: _saveCurrent,
            saved: _saved,
          ),
          const SizedBox(height: AppTheme.space4),
          _OverviewCard(fortune: fortune),
          const SizedBox(height: AppTheme.space4),
          _DimensionGrid(dimensions: fortune.dimensions),
          const SizedBox(height: AppTheme.space4),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _KeywordCard(
                  title: '今日适合',
                  icon: Icons.check_circle_outline,
                  color: colors.primary,
                  items: fortune.yi.take(10).toList(growable: false),
                ),
                _KeywordCard(
                  title: '今日谨慎',
                  icon: Icons.info_outline,
                  color: colors.error,
                  items: fortune.ji.take(10).toList(growable: false),
                ),
              ];
              if (constraints.maxWidth >= 720) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(width: double.infinity, child: cards[0]),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: cards[1]),
                ],
              );
            },
          ),
          const AppSectionHeading(title: '小兆深度解读'),
          AiInterpretationCard(
            response: _aiResponse,
            loading: _aiLoading,
            error: _aiError,
            onRequest: _requestAiReading,
            loadingText: '小兆正在结合今日历法与生肖关系整理建议…',
            idleText: '基础运势已在本地生成。需要时可让小兆进一步整理成更自然的白话建议。',
            disabledText: '基础运势已在本地生成；当前未配置 AI 服务，其他内容仍可正常使用。',
            actionKey: const ValueKey('fortune-ai-reading'),
            enabled: widget.aiService != null,
          ),
          const SizedBox(height: AppTheme.space4),
          AppCard(
            color: colors.surfaceContainerLow,
            child: Text(
              '算法 ${fortune.algorithmId} v${fortune.algorithmVersion}。'
              '本页依据传统历法、当日宜忌和生肖关系生成稳定的日常提示，'
              '仅供文化娱乐与自我整理，不预测具体事件，也不构成医疗、法律或财务建议。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.fortune,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
    required this.onSave,
    required this.saved,
  });

  final TodayFortune fortune;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;
  final Future<void> Function() onSave;
  final bool saved;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        IconButton(
          key: const ValueKey('fortune-previous-day'),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                fortune.dateKey,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text('${fortune.lunarDate} · ${fortune.dayGanZhi}日'),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton(onPressed: onToday, child: const Text('回到今天')),
                  FilledButton.tonalIcon(
                    key: const ValueKey('fortune-save'),
                    onPressed: saved ? null : onSave,
                    icon: Icon(
                      saved ? Icons.check : Icons.bookmark_add_outlined,
                    ),
                    label: Text(saved ? '已保存' : '保存日运'),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('fortune-next-day'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.fortune});
  final TodayFortune fortune;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.primaryContainer.withValues(alpha: 0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${fortune.overallScore}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fortune.headline,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(fortune.summary),
                    if (fortune.isClashing) ...[
                      const SizedBox(height: 8),
                      Text(
                        '生肖提示：今日冲${fortune.clashZodiac}，与你所选角色生肖相冲。',
                        style: TextStyle(color: colors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FortuneChip(
                icon: Icons.palette_outlined,
                text: fortune.luckyColor,
              ),
              _FortuneChip(
                icon: Icons.explore_outlined,
                text: fortune.luckyDirection,
              ),
              _FortuneChip(
                icon: Icons.filter_9_plus_outlined,
                text: '幸运数字 ${fortune.luckyNumber}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FortuneChip extends StatelessWidget {
  const _FortuneChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 16), label: Text(text));
}

class _DimensionGrid extends StatelessWidget {
  const _DimensionGrid({required this.dimensions});
  final List<FortuneDimension> dimensions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 5
          : constraints.maxWidth >= 560
          ? 3
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in dimensions)
            SizedBox(
              width: width,
              child: _DimensionCard(item: item),
            ),
        ],
      );
    },
  );
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.item});
  final FortuneDimension item;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('${item.score}'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: item.score / 100),
        const SizedBox(height: 10),
        Text(item.summary, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _KeywordCard extends StatelessWidget {
  const _KeywordCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final item in items) Chip(label: Text(item))],
        ),
      ],
    ),
  );
}
