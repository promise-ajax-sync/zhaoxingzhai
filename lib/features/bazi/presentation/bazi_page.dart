import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/engine/bazi/bazi_divination.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

class BaziPage extends StatelessWidget {
  const BaziPage({super.key, required this.currentCase, this.onResult});

  final CaseSnapshot? Function() currentCase;
  final Future<void> Function(BaziResult result)? onResult;

  @override
  Widget build(BuildContext context) {
    final subject = currentCase();
    if (subject == null) {
      return const Center(child: Text('请先在角色页面选择一个有出生时间的角色。'));
    }
    final result = BaziEngine.calculate(subject);
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
                '${subject.displayName} · ${_dateTime(result.inputCivilTime)}',
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
                onPressed: onResult == null ? null : () => onResult!(result),
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存八字记录'),
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
