import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';

class DailyHexagramPage extends StatefulWidget {
  const DailyHexagramPage({
    super.key,
    required this.currentCase,
    this.onResult,
  });

  final CaseSnapshot? Function() currentCase;
  final Future<void> Function(DailyHexagramResult result)? onResult;

  @override
  State<DailyHexagramPage> createState() => _DailyHexagramPageState();
}

class _DailyHexagramPageState extends State<DailyHexagramPage> {
  DailyHexagramResult? _result;
  Object? _loadError;
  bool _loading = true;
  bool _manualMode = false;
  final List<int> _manualValues = List.filled(6, 7);

  @override
  void initState() {
    super.initState();
    _load();
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
    if (mounted) {
      setState(() {
        _result = result;
        _loadError = null;
        _loading = false;
      });
    }
    await widget.onResult?.call(result);
  }

  Future<void> _submitManual() => _acceptResult(
    DailyHexagramEngine.fromYaoValues(
      _manualValues,
      caseKey: widget.currentCase()?.stableHash,
    ),
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
            _ManualYaoInput(
              values: _manualValues,
              onChanged: (index, value) {
                setState(() => _manualValues[index] = value);
              },
              onSubmit: _submitManual,
            ),
          ],
          const SizedBox(height: AppTheme.space4),
          _HexagramOverview(result: result),
          const AppSectionHeading(title: '六爻记录'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                children: [
                  for (var index = 5; index >= 0; index--)
                    _YaoRow(index: index, result: result),
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
        ],
      ),
    );
  }
}

class _HexagramOverview extends StatelessWidget {
  const _HexagramOverview({required this.result});

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
  const _YaoRow({required this.index, required this.result});

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

class _ManualYaoInput extends StatelessWidget {
  const _ManualYaoInput({
    required this.values,
    required this.onChanged,
    required this.onSubmit,
  });

  final List<int> values;
  final void Function(int index, int value) onChanged;
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
            const Text('依次录入初爻到上爻的三钱合计。'),
            const SizedBox(height: AppTheme.space3),
            Wrap(
              spacing: AppTheme.space3,
              runSpacing: AppTheme.space3,
              children: [
                for (var index = 0; index < 6; index++)
                  SizedBox(
                    width: 145,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('daily-yao-$index'),
                      initialValue: values[index],
                      decoration: InputDecoration(labelText: names[index]),
                      items: [
                        for (final yao in DailyHexagramYaoType.values)
                          DropdownMenuItem(
                            value: yao.value,
                            child: Text('${yao.value} · ${yao.label}'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) onChanged(index, value);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成手动卦'),
            ),
          ],
        ),
      ),
    );
  }
}
