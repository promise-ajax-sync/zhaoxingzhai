import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/evidence/xiaoliuren_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

class XiaoliurenInterpretation {
  const XiaoliurenInterpretation({
    required this.id,
    required this.version,
    required this.overview,
    required this.background,
    required this.process,
    required this.outcome,
    required this.action,
    required this.riskReminder,
    required this.questionIntent,
    required this.questionIntentLabel,
    required this.directAnswer,
    required this.evidence,
  });

  static const interpretationId = 'xiaoliuren.local-reading';
  static const interpretationVersion = 2;

  final String id;
  final int version;
  final String overview;
  final String background;
  final String process;
  final String outcome;
  final String action;
  final String riskReminder;
  final String questionIntent;
  final String questionIntentLabel;
  final String directAnswer;
  final DivinationEvidence evidence;

  factory XiaoliurenInterpretation.build(
    XiaoliurenData result, {
    DivinationQuestion? question,
  }) {
    final actualQuestion =
        question ??
        const DivinationQuestion(
          rawText: '',
          topic: 'general',
          intent: DivinationQuestionIntent.general,
        );
    final hour = _palace(result.sequence['hour']!.name);
    return XiaoliurenInterpretation(
      id: interpretationId,
      version: interpretationVersion,
      overview:
          '本次依次落在月宫${result.sequence['month']!.name}、日宫${result.sequence['day']!.name}、'
          '时宫${result.sequence['hour']!.name}。月宫、日宫是顺数轨迹，只有时宫作为本次主证。',
      background:
          '月宫${result.sequence['month']!.name}是按农历月份确定的起算位置，不解释为现实背景或事情起因。',
      process: '日宫${result.sequence['day']!.name}是从月宫继续顺数所得的中间位置，不解释为现实过程或日运。',
      outcome: '此刻落点为“${result.sequence['hour']!.name}”：${hour.meaning}',
      action: hour.action,
      riskReminder: '${hour.risk}六宫用于整理当下节奏，不代表现实事件必然发生，重要决定仍需核对实际信息。',
      questionIntent: actualQuestion.intent.id,
      questionIntentLabel: actualQuestion.intent.label,
      directAnswer: _directAnswer(
        actualQuestion.intent,
        result.primary.name,
        hour,
      ),
      evidence: XiaoliurenEvidenceBuilder.build(result, actualQuestion),
    );
  }

  static String _directAnswer(
    DivinationQuestionIntent intent,
    String palace,
    ({String meaning, String action, String risk}) reading,
  ) {
    final favorable = {'大安', '速喜', '小吉'}.contains(palace);
    return switch (intent) {
      DivinationQuestionIntent.yesNo =>
        favorable
            ? '就“是否”而言，$palace偏向有条件地可行，但仍需满足现实条件，不能理解为必然成功。${reading.action}'
            : '就“是否”而言，$palace提示目前不宜直接作肯定判断，先处理阻力或等待条件变清楚。${reading.action}',
      DivinationQuestionIntent.timing => switch (palace) {
        '速喜' => '时间节奏偏快，近期出现反馈的可能性较高，但不提供固定日期。',
        '大安' => '时间节奏稳定，适合按既定安排推进，不必催促。',
        '留连' => '时间节奏偏慢，容易反复或延期，先预留缓冲。',
        '赤口' => '先等待争议或沟通摩擦缓和，再选择时机。',
        '小吉' => '会以小步推进的方式逐渐明朗，适合边做边确认。',
        _ => '当前条件尚未成形，暂时无法给出可靠应期，宜稍后复核现实进展。',
      },
      DivinationQuestionIntent.cause =>
        '从时宫$palace看，当前主要阻力或推动力可概括为：${reading.meaning}${reading.risk}',
      DivinationQuestionIntent.action => '针对“怎么做”，当前最合适的行动是：${reading.action}',
      DivinationQuestionIntent.risk => '当前需要优先防范的是：${reading.risk}',
      DivinationQuestionIntent.trend =>
        '短期趋势落在$palace：${reading.meaning}建议用后续真实反馈验证，而不是一次性下结论。',
      DivinationQuestionIntent.location =>
        '小六壬此次结果不足以可靠锁定具体地点或方位；能确认的只是当前节奏落在$palace。${reading.action}',
      DivinationQuestionIntent.person =>
        '小六壬不能证明某个人的真实内心或具体特征；只能把当前互动节奏概括为$palace。${reading.meaning}',
      DivinationQuestionIntent.general =>
        '本次时宫为$palace，当前判断是：${reading.meaning}${reading.action}',
    };
  }

  static ({String meaning, String action, String risk}) _palace(String name) =>
      switch (name) {
        '大安' => (
          meaning: '局面相对稳定，适合把已有安排落实清楚。',
          action: '保持稳定节奏，先完成手头事项，再逐步扩大行动范围。',
          risk: '稳定不等于没有变化，仍要定期检查条件是否已经改变。',
        ),
        '留连' => (
          meaning: '进展容易反复或延迟，需要更多耐心和确认。',
          action: '放慢节奏，补齐信息、责任人和时间节点，不急于得到即时结论。',
          risk: '拖延可能来自条件不清，也可能来自回避决定，需要区分两者。',
        ),
        '速喜' => (
          meaning: '反馈和机会可能来得较快，适合及时响应。',
          action: '提前准备下一步，在出现明确反馈时迅速落实，但保留基本复核。',
          risk: '速度快不等于质量可靠，不要省略关键检查。',
        ),
        '赤口' => (
          meaning: '沟通摩擦和观点冲突较突出，表达方式会影响结果。',
          action: '减少情绪化表达，重要内容留下记录，并先确认彼此理解是否一致。',
          risk: '最需要防范的是误解升级和冲动回应。',
        ),
        '小吉' => (
          meaning: '局面适合合作与小步推进，逐渐积累有利条件。',
          action: '从容易达成共识的小事项开始，用实际成果建立后续合作。',
          risk: '小有进展时不要过早扩大承诺或忽略细节。',
        ),
        '空亡' => (
          meaning: '当前信息、资源或落地条件可能不足，结果尚不明确。',
          action: '先暂停重大承诺，确认关键事实是否存在，再决定继续、调整或退出。',
          risk: '主要风险是依据想象填补信息空白，或为尚未落实的条件投入过多。',
        ),
        _ => throw StateError('无法解释小六壬宫位：$name'),
      };

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'overview': overview,
    'background': background,
    'process': process,
    'outcome': outcome,
    'action': action,
    'riskReminder': riskReminder,
    'questionIntent': questionIntent,
    'questionIntentLabel': questionIntentLabel,
    'directAnswer': directAnswer,
    'evidence': evidence.toJson(),
  };
}
