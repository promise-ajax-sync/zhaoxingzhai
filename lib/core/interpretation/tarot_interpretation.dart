import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';
import 'package:zhaoxingzhai/core/evidence/tarot_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

class TarotInterpretation {
  const TarotInterpretation({
    required this.id,
    required this.version,
    required this.overview,
    required this.cardReadings,
    required this.action,
    required this.riskReminder,
    required this.questionIntent,
    required this.questionIntentLabel,
    required this.directAnswer,
    required this.evidence,
  });

  static const interpretationId = 'tarot.local-reading';
  static const interpretationVersion = 2;

  final String id;
  final int version;
  final String overview;
  final List<String> cardReadings;
  final String action;
  final String riskReminder;
  final String questionIntent;
  final String questionIntentLabel;
  final String directAnswer;
  final DivinationEvidence evidence;

  factory TarotInterpretation.build(
    TarotDrawResult result, {
    DivinationQuestion? question,
  }) {
    final resolvedQuestion = question ?? DivinationQuestion.parse('');
    final reversed = result.cards
        .where((card) => card.orientation == '逆位')
        .length;
    final readings = result.cards
        .map(
          (card) =>
              '${card.position}的“${card.name}”为${card.orientation}，'
              '可从${card.keywords.join('、')}这些主题检查当前情况。'
              '${card.orientation == '逆位' ? '相关主题可能表现为受阻、过度、内化或方向偏离，需结合事实判断。' : '相关主题当前较直接，但仍需结合牌位和现实条件理解。'}',
        )
        .toList(growable: false);
    final evidence = TarotEvidenceBuilder.build(result, resolvedQuestion);
    final themes = result.cards
        .expand((card) => card.keywords)
        .toSet()
        .take(4)
        .join('、');
    final answer = switch (resolvedQuestion.intent) {
      DivinationQuestionIntent.person =>
        '人物线索集中在$themes这些主题，但应通过真实行为验证，不能只凭牌面定义一个人。',
      DivinationQuestionIntent.cause =>
        '阻力可优先从各牌位中的逆位、重复关键词和前后位置差异检查，当前突出主题为$themes。',
      DivinationQuestionIntent.trend =>
        '牌阵呈现的是从${result.cards.first.name}到${result.cards.last.name}的主题变化，重点观察$themes如何在现实中发展。',
      DivinationQuestionIntent.action => '下一步围绕$themes选择一个可验证的小行动，并根据对方真实反馈调整。',
      DivinationQuestionIntent.risk => '主要风险来自逆位约束、主观投射和把单张牌绝对化，应同时检查现实反证。',
      DivinationQuestionIntent.yesNo =>
        '塔罗更适合呈现条件和过程，不宜只给机械的是或否；当前应结合$themes判断哪些条件尚未满足。',
      DivinationQuestionIntent.location =>
        '当前牌面主要描述关系与情境主题，不能可靠推出具体地点；可以把$themes作为可能场景的观察线索。',
      DivinationQuestionIntent.timing =>
        '当前牌阵没有提供可验证的确定日期，只能根据牌位推进顺序观察$themes何时出现现实信号。',
      DivinationQuestionIntent.general => '当前牌阵最集中的主题是$themes，应结合各牌位逐项核对现实情况。',
    };
    return TarotInterpretation(
      id: interpretationId,
      version: interpretationVersion,
      overview:
          '“${result.spreadName}”共${result.cards.length}张牌，其中$reversed张逆位。'
          '以下只整理牌位、关键词和正逆位带来的观察角度，不把牌面当作唯一未来。',
      cardReadings: readings,
      action: '先找出多张牌共同出现的主题，再选择一个可验证的小行动；行动后根据真实反馈调整，不因单张牌一次性下结论。',
      riskReminder: '塔罗适合帮助梳理感受与选项，不应用来断定他人真实意图、疾病、法律结果、财务收益或必然事件。',
      questionIntent: resolvedQuestion.intent.id,
      questionIntentLabel: resolvedQuestion.intent.label,
      directAnswer: answer,
      evidence: evidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'overview': overview,
    'cardReadings': cardReadings,
    'action': action,
    'riskReminder': riskReminder,
    'questionIntent': questionIntent,
    'questionIntentLabel': questionIntentLabel,
    'directAnswer': directAnswer,
    'evidence': evidence.toJson(),
  };
}
