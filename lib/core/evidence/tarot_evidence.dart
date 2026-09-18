import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class TarotEvidenceBuilder {
  static const evidenceVersion = 1;

  static DivinationEvidence build(
    TarotDrawResult result,
    DivinationQuestion question,
  ) {
    final calculations = result.cards
        .map(
          (card) => DivinationEvidenceItem(
            id: 'card-${card.position}',
            label: card.position,
            detail:
                '${card.name}${card.orientation}：${card.keywords.join('、')}',
          ),
        )
        .toList(growable: false);
    final supporting = [
      DivinationEvidenceItem(
        id: 'question-intent',
        label: '问题焦点',
        detail: '原问题按“${question.intent.label}”处理，优先从牌位和重复主题中寻找对应线索。',
      ),
      DivinationEvidenceItem(
        id: 'evidence-summary',
        label: '牌面证据汇总',
        detail: result.evidenceAnalysis.summaryFact.promptText,
      ),
    ];
    final counter = [
      ...result.evidenceAnalysis.counterEvidenceFacts.map(
        (fact) => DivinationEvidenceItem(
          id: fact.key,
          label: '逆位约束',
          detail: fact.promptText,
        ),
      ),
      const DivinationEvidenceItem(
        id: 'mind-reading-boundary',
        label: '不能读取真实内心',
        detail: '牌面只能帮助整理关系视角，不能证明他人的真实意图或未表达想法。',
      ),
    ];
    final limitations = [
      ...result.evidenceAnalysis.methodology.asMap().entries.map(
        (entry) => DivinationEvidenceItem(
          id: 'method-${entry.key + 1}',
          label: '方法限制',
          detail: entry.value,
        ),
      ),
      const DivinationEvidenceItem(
        id: 'professional-boundary',
        label: '专业边界',
        detail: '塔罗解释不得替代医疗、法律、财务或其他专业判断。',
      ),
    ];
    return DivinationEvidence(
      methodId: 'tarot',
      version: evidenceVersion,
      calculationFacts: calculations,
      supportingEvidence: supporting,
      counterEvidence: counter,
      limitations: limitations,
      summary:
          '以${result.spreadName}的${result.cards.length}张牌、牌位、正逆位及问题焦点“${question.intent.label}”为依据。',
    );
  }
}
