import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/evidence/ssgw_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

class SsgwInterpretation {
  const SsgwInterpretation({
    required this.id,
    required this.version,
    required this.overview,
    required this.situation,
    required this.action,
    required this.riskReminder,
    required this.questionIntent,
    required this.questionIntentLabel,
    required this.directAnswer,
    required this.evidence,
  });

  static const interpretationId = 'ssgw.local-reading';
  static const interpretationVersion = 2;

  final String id;
  final int version;
  final String overview;
  final String situation;
  final String action;
  final String riskReminder;
  final String questionIntent;
  final String questionIntentLabel;
  final String directAnswer;
  final DivinationEvidence evidence;

  factory SsgwInterpretation.build(
    SsgwResult result, {
    DivinationQuestion? question,
  }) {
    final actualQuestion = question ??
        const DivinationQuestion(
          rawText: '',
          topic: 'general',
          intent: DivinationQuestionIntent.general,
        );
    final details = result.sign.details;
    String first(List<String> keys, String fallback) {
      for (final key in keys) {
        final value = details[key];
        if (value != null && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return fallback;
    }

    final selected = _selectDetail(details, actualQuestion);

    return SsgwInterpretation(
      id: interpretationId,
      version: interpretationVersion,
      overview: first(const [
        '核心寓意',
        '此签核心',
        '解签总论',
      ], '本签主题为“${result.sign.title}”，可结合签诗与所问事项核对。'),
      situation: first(const [
        '解签总论',
        '提醒',
      ], '签诗为“${result.sign.poem.replaceAll('\n', '；')}”。先从其中反复出现的意象观察当前处境。'),
      action: first(const [
        '行动建议',
        '事业',
        '事业/求职',
      ], '先把所问事项拆成可执行步骤，并根据现实反馈逐步调整。'),
      riskReminder:
          '${first(const ['风险提醒', '提醒'], '不要只依据吉凶标签作重大决定，应同时核对现实条件。')}签文仅供文化参考，不替代专业判断。',
      questionIntent: actualQuestion.intent.id,
      questionIntentLabel: actualQuestion.intent.label,
      directAnswer: _directAnswer(actualQuestion, selected.$1, selected.$2),
      evidence: SsgwEvidenceBuilder.build(
        result,
        actualQuestion,
        selectedDetailLabel: selected.$1,
        selectedDetail: selected.$2,
      ),
    );
  }

  static (String, String) _selectDetail(
    Map<String, String> details,
    DivinationQuestion question,
  ) {
    final preferredKeys = switch (question.topic) {
      'relationship' => const ['感情', '婚姻', '姻缘', '感情/婚姻'],
      'career' => const ['事业', '事业/求职', '求职', '工作'],
      'wealth' => const ['财运', '求财', '经营'],
      'health' => const ['健康', '疾病', '病情'],
      'study' => const ['学业', '考试', '功名'],
      _ => switch (question.intent) {
          DivinationQuestionIntent.action => const ['行动建议', '建议'],
          DivinationQuestionIntent.risk => const ['风险提醒', '提醒'],
          DivinationQuestionIntent.timing => const ['时机', '应期', '时间'],
          _ => const ['核心寓意', '此签核心', '解签总论'],
        },
    };
    for (final preferred in preferredKeys) {
      for (final entry in details.entries) {
        if ((entry.key == preferred || entry.key.contains(preferred)) &&
            entry.value.trim().isNotEmpty) {
          return (entry.key, entry.value.trim());
        }
      }
    }
    final fallback = details.entries.firstWhere(
      (entry) => entry.value.trim().isNotEmpty,
      orElse: () => const MapEntry('签诗', '请结合签诗和现实情况审慎判断。'),
    );
    return (fallback.key, fallback.value.trim());
  }

  static String _directAnswer(
    DivinationQuestion question,
    String label,
    String detail,
  ) => switch (question.intent) {
    DivinationQuestionIntent.yesNo =>
      '对于“是否”问题，本签不宜简化成绝对的是或否。与问题最相关的“$label”提示是：$detail请把它作为条件判断，并用现实进展验证。',
    DivinationQuestionIntent.timing =>
      '对于时间问题，本签只能提示时机状态，不能给出确定日期。“$label”显示：$detail',
    DivinationQuestionIntent.location =>
      '本签不足以可靠锁定具体地点或方位；与当前问题最接近的“$label”内容是：$detail',
    DivinationQuestionIntent.person =>
      '签文不能证明他人的真实内心或人物特征；可用于观察关系处境的“$label”内容是：$detail',
    DivinationQuestionIntent.cause =>
      '对于原因或阻力，可优先核对“$label”所说的现实条件：$detail',
    DivinationQuestionIntent.trend =>
      '当前发展趋势可从“$label”理解为：$detail后续仍应根据真实反馈调整判断。',
    DivinationQuestionIntent.action =>
      '针对“下一步怎么做”，本签中最相关的“$label”建议是：$detail',
    DivinationQuestionIntent.risk =>
      '当前应优先留意“$label”中的提醒：$detail',
    DivinationQuestionIntent.general =>
      '结合所问事项，本签中最相关的“$label”内容是：$detail',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'overview': overview,
    'situation': situation,
    'action': action,
    'riskReminder': riskReminder,
    'questionIntent': questionIntent,
    'questionIntentLabel': questionIntentLabel,
    'directAnswer': directAnswer,
    'evidence': evidence.toJson(),
  };
}
