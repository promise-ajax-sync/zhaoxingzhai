import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

abstract final class DailyHexagramEvidenceBuilder {
  static const evidenceVersion = 1;

  static DivinationEvidence build(
    DailyHexagramResult result,
    DivinationQuestion question,
  ) {
    final movingNames = result.movingLines.isEmpty
        ? '无动爻'
        : result.movingLines.map((line) => line.name).join('、');
    return DivinationEvidence(
      methodId: 'daily-hexagram',
      version: evidenceVersion,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'original',
          label: '本卦',
          detail:
              '${result.original.symbol} ${result.original.name}：${result.original.description}',
        ),
        DivinationEvidenceItem(
          id: 'moving-lines',
          label: '动爻与取用',
          detail: '$movingNames；${result.takingRule.summary}',
        ),
        DivinationEvidenceItem(
          id: 'related',
          label: '互卦与变卦',
          detail: '互卦${result.inter.name}，变卦${result.changed.name}。',
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'question-intent',
          label: '问题焦点',
          detail: '原问题按“${question.intent.label}”处理，事项分类为 ${question.topic}。',
        ),
        DivinationEvidenceItem(
          id: 'primary-texts',
          label: '主取内容',
          detail: result.takingRule.primaryTexts.join('；'),
        ),
      ],
      counterEvidence: const [
        DivinationEvidenceItem(
          id: 'non-deterministic',
          label: '反向约束',
          detail: '卦象呈现的是当日观察框架，不保证具体事情必然发生，也不能取代新的现实信息。',
        ),
      ],
      limitations: const [
        DivinationEvidenceItem(
          id: 'scope-boundary',
          label: '范围边界',
          detail: '每日一卦适合整理当天的整体状态，不擅长证明他人内心、精确地点或固定应期。',
        ),
        DivinationEvidenceItem(
          id: 'professional-boundary',
          label: '专业边界',
          detail: '卦象解读不得替代医疗、法律、财务或其他专业判断。',
        ),
      ],
      summary:
          '以本卦${result.original.name}、${result.movingLines.length}个动爻、互卦${result.inter.name}和变卦${result.changed.name}为依据。',
    );
  }
}
