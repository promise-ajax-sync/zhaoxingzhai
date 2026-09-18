import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class XiaoliurenEvidenceBuilder {
  static const evidenceVersion = 1;

  static DivinationEvidence build(
    XiaoliurenData result,
    DivinationQuestion question,
  ) {
    final hourPalace = result.sequence['hour']!;
    return DivinationEvidence(
      methodId: 'xiaoliuren',
      version: evidenceVersion,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'calendar-input',
          label: '起课时间',
          detail:
              '农历${result.isLeapMonth ? '闰' : ''}${result.lunarMonth}月'
              '${result.lunarDay}日，${result.hourLabel}，采用${result.ruleLabel}。',
        ),
        DivinationEvidenceItem(
          id: 'palace-sequence',
          label: '顺数轨迹',
          detail:
              '月宫${result.sequence['month']!.name}、日宫${result.sequence['day']!.name}、'
              '时宫${hourPalace.name}；只有时宫作为本次主证。',
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'question-intent',
          label: '问题焦点',
          detail: '原问题按“${question.intent.label}”处理，回答只提取与该问法有关的宫义。',
        ),
        DivinationEvidenceItem(
          id: 'primary-palace',
          label: '时宫主证',
          detail: '${hourPalace.name}：${hourPalace.verse}',
        ),
      ],
      counterEvidence: const [
        DivinationEvidenceItem(
          id: 'non-deterministic',
          label: '反向约束',
          detail: '吉宫不保证事情一定成功，凶宫也不表示事情必然失败，现实条件仍可能改变结果。',
        ),
        DivinationEvidenceItem(
          id: 'trace-boundary',
          label: '轨迹边界',
          detail: '月宫和日宫只是顺数的中间位置，不能当作现实起因、发展过程或月日运势。',
        ),
      ],
      limitations: const [
        DivinationEvidenceItem(
          id: 'prediction-boundary',
          label: '预测边界',
          detail: '六宫用于整理短期趋势和行动节奏，不能证明具体事件、方位、人物想法或应期。',
        ),
        DivinationEvidenceItem(
          id: 'professional-boundary',
          label: '专业边界',
          detail: '解读不得替代医疗、法律、财务或其他专业判断。',
        ),
      ],
      summary: '以${result.ruleLabel}的时间起课结果、时宫${hourPalace.name}和问题焦点“${question.intent.label}”为依据。',
    );
  }
}
