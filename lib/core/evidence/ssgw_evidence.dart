import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class SsgwEvidenceBuilder {
  static const evidenceVersion = 1;

  static DivinationEvidence build(
    SsgwResult result,
    DivinationQuestion question, {
    required String selectedDetailLabel,
    required String selectedDetail,
  }) {
    return DivinationEvidence(
      methodId: 'ssgw',
      version: evidenceVersion,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'sign',
          label: '签号与签题',
          detail: '第${result.sign.number}签 · ${result.sign.title}',
        ),
        DivinationEvidenceItem(
          id: 'poem',
          label: '签诗原文',
          detail: result.sign.poem.replaceAll('\n', '；'),
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'question-intent',
          label: '问题焦点',
          detail: '原问题按“${question.intent.label}”处理，事项分类为 ${question.topic}。',
        ),
        DivinationEvidenceItem(
          id: 'selected-detail',
          label: selectedDetailLabel,
          detail: selectedDetail,
        ),
      ],
      counterEvidence: const [
        DivinationEvidenceItem(
          id: 'non-deterministic',
          label: '反向约束',
          detail: '吉签不保证现实一定成功，警示签也不表示事情必然失败；当事人的选择与外部条件仍会改变结果。',
        ),
      ],
      limitations: const [
        DivinationEvidenceItem(
          id: 'fact-boundary',
          label: '事实边界',
          detail: '签诗属于传统文化解释材料，不能证明他人内心、具体地点、固定日期或现实事件。',
        ),
        DivinationEvidenceItem(
          id: 'professional-boundary',
          label: '专业边界',
          detail: '签文解读不得替代医疗、法律、财务或其他专业判断。',
        ),
      ],
      summary:
          '以第${result.sign.number}签、签诗原文和与问题最相关的“$selectedDetailLabel”字段为依据。',
    );
  }
}
