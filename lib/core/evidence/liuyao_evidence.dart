import 'package:zhaoxingzhai/core/engine/liuyao/liuyao_divination.dart';
import 'package:zhaoxingzhai/core/engine/liuyao/liuyao_analysis.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class LiuyaoEvidenceBuilder {
  static DivinationEvidence build(
    LiuyaoResult result,
    DivinationQuestion question,
  ) {
    final moving = result.lines.where((line) => line.yao.isMoving).toList();
    final advanced = LiuyaoAdvancedAnalyzer.build(result);
    return DivinationEvidence(
      methodId: 'liuyao',
      version: 1,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'hexagrams',
          label: '卦象结构',
          detail:
              '本卦${result.base.original.name}，变卦${result.base.changed.name}，'
              '互卦${result.base.inter.name}，错卦${result.opposite.name}，综卦${result.reversed.name}。',
        ),
        DivinationEvidenceItem(
          id: 'advanced-relations',
          label: '旺衰冲合',
          detail: [
            ...advanced.lineAnalyses.map(
              (item) => '${item.position}爻${item.tags.join('、')}',
            ),
            ...advanced.threeHarmony,
          ].join('；'),
        ),
        DivinationEvidenceItem(
          id: 'palace',
          label: '八宫世应',
          detail:
              '${result.base.original.palace}宫${result.palaceElement}，${result.palaceStage}，'
              '世爻在${result.shiPosition}爻，应爻在${result.yingPosition}爻。',
        ),
        DivinationEvidenceItem(
          id: 'calendar',
          label: '月日与旬空',
          detail:
              '${result.calendar.solarTermMonthGanzhi}月${result.calendar.dayGanzhi}日，'
              '${result.calendar.hourGanzhi}时，旬空${result.voidBranches.join('')}。',
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'moving-lines',
          label: '动爻',
          detail: moving.isEmpty
              ? '六爻皆静，以本卦和世应关系为主要观察框架。'
              : moving
                    .map(
                      (line) =>
                          '${line.position}爻${line.relation.label}${line.ganZhi}${line.element}发动',
                    )
                    .join('；'),
        ),
        DivinationEvidenceItem(
          id: 'question',
          label: '问题焦点',
          detail: [
            question.rawText.isEmpty
                ? '未限定具体问题，仅作通用卦盘说明。'
                : '原问题按“${question.intent.label}”处理：${question.rawText}',
            if (result.focusRelation != null)
              '用户明确选择${result.focusRelation!.label}为观察重点。',
          ].join(''),
        ),
      ],
      counterEvidence: const [
        DivinationEvidenceItem(
          id: 'use-god',
          label: '用神限制',
          detail: '自动解读尚未替用户武断指定唯一用神；同一卦盘会因问题主体和事项不同而改变取用重点。',
        ),
      ],
      limitations: const [
        DivinationEvidenceItem(
          id: 'traditional-model',
          label: '传统模型边界',
          detail: '纳甲、六亲、六神和旺衰属于传统解释体系，不是可验证的确定预测。',
        ),
        DivinationEvidenceItem(
          id: 'professional-boundary',
          label: '专业边界',
          detail: '不得用排盘结果替代医疗、法律、投资、安全等专业判断。',
        ),
      ],
      summary:
          '依据${result.base.original.name}之${result.palaceStage}、世应、纳甲六亲、'
          '${moving.length}个动爻及${result.calendar.dayGanzhi}日旬空整理。',
    );
  }
}
