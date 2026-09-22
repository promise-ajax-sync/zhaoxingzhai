import 'package:zhaoxingzhai/core/engine/bazi/bazi_divination.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class BaziEvidenceBuilder {
  static DivinationEvidence build(
    BaziResult result,
    DivinationQuestion question,
  ) {
    return DivinationEvidence(
      methodId: 'bazi',
      version: result.algorithm.version,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'pillars',
          label: '四柱',
          detail: result.pillars.map((p) => '${p.name}${p.ganzhi}').join('、'),
        ),
        DivinationEvidenceItem(
          id: 'day-master',
          label: '日主',
          detail: result.dayMaster,
        ),
        DivinationEvidenceItem(
          id: 'luck',
          label: '大运',
          detail: '${result.forwardLuck ? '顺排' : '逆排'}，起运${result.luckStart}',
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'hidden-stems',
          label: '藏干',
          detail: result.pillars
              .map((p) => '${p.name}${p.hiddenStems.join('、')}')
              .join('；'),
        ),
        DivinationEvidenceItem(
          id: 'elements',
          label: '五行统计',
          detail: result.elementCounts.entries
              .map((e) => '${e.key.label}${e.value}')
              .join('、'),
        ),
        DivinationEvidenceItem(
          id: 'palaces',
          label: '辅助信息',
          detail:
              '胎元${result.taiYuan}、命宫${result.mingGong}、身宫${result.shenGong}',
        ),
      ],
      counterEvidence: const [],
      limitations: [
        const DivinationEvidenceItem(
          id: 'scope',
          label: '解释边界',
          detail: '八字用于传统文化研究，不作为医疗、法律、财务或人生决定的确定性依据。',
        ),
        if (result.usedTrueSolarTime)
          DivinationEvidenceItem(
            id: 'solar-time',
            label: '时间修正',
            detail:
                '已使用真太阳时修正${result.trueSolarCorrectionMinutes?.toStringAsFixed(1)}分钟。',
          ),
      ],
      summary:
          '问题：${question.rawText.isEmpty ? '综合解读' : question.rawText}；基于已计算的八字证据解释，不重新排盘。',
    );
  }
}
