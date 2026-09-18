import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class MeihuaEvidenceBuilder {
  static const evidenceVersion = 1;

  static DivinationEvidence build(
    MeihuaResult result,
    DivinationQuestion question,
  ) {
    final calculation = [
      DivinationEvidenceItem(
        id: 'hexagrams',
        label: '主互变卦',
        detail:
            '本卦${result.original.name}、互卦${result.inter.name}、变卦${result.changed.name}',
      ),
      DivinationEvidenceItem(
        id: 'moving-line',
        label: '动爻',
        detail: '${result.movingYaoName}：${result.movingYaoCi}',
      ),
      DivinationEvidenceItem(
        id: 'ti-yong',
        label: '体用',
        detail:
            '体卦${result.tiGua.name}${result.tiGua.element}、用卦${result.yongGua.name}${result.yongGua.element}，关系为${result.tiYongRelation}',
      ),
    ];
    final supporting = [
      DivinationEvidenceItem(
        id: 'question-intent',
        label: '问题焦点',
        detail: '原问题按“${question.intent.label}”处理，回答只优先覆盖这一焦点',
      ),
      DivinationEvidenceItem(
        id: 'current-state',
        label: '当前状态',
        detail: result.original.description,
      ),
      DivinationEvidenceItem(
        id: 'transition',
        label: '变化线索',
        detail: result.changed.description,
      ),
    ];
    final counter = [
      const DivinationEvidenceItem(
        id: 'no-single-factor',
        label: '非单因结论',
        detail: '同一卦象可对应多种现实表现，不能脱离用户处境只按一个象意下结论。',
      ),
      if (question.intent == DivinationQuestionIntent.location)
        const DivinationEvidenceItem(
          id: 'direction-not-address',
          label: '方位不是地址',
          detail: '八卦方位只能提供观察方向和场景类型，不能推出唯一城市、单位或具体地址。',
        ),
    ];
    final limitations = [
      const DivinationEvidenceItem(
        id: 'traditional-model',
        label: '传统模型限制',
        detail: '梅花易数属于传统解释模型，输出用于整理思路和观察变量，不是可验证的确定预测。',
      ),
      const DivinationEvidenceItem(
        id: 'professional-boundary',
        label: '专业边界',
        detail: '不得替代医疗、法律、财务或其他专业判断。',
      ),
    ];
    return DivinationEvidence(
      methodId: 'meihua',
      version: evidenceVersion,
      calculationFacts: calculation,
      supportingEvidence: supporting,
      counterEvidence: counter,
      limitations: limitations,
      summary:
          '以${result.original.name}、${result.movingYaoName}、${result.tiYongRelation}及问题焦点“${question.intent.label}”为主要依据。',
    );
  }
}
