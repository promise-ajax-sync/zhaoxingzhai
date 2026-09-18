import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/evidence/meihua_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

/// 梅花易数本地现代白话解释层。
///
/// 只读取已经完成的卦盘，不参与起卦、互卦、变卦或体用计算。
/// 文案规则变化时提升 [interpretationVersion]，历史始终保存当时版本。
class MeihuaInterpretation {
  const MeihuaInterpretation({
    required this.id,
    required this.version,
    required this.traditionalOverview,
    required this.situation,
    required this.process,
    required this.trend,
    required this.action,
    required this.riskReminder,
    required this.topic,
    required this.topicLabel,
    required this.topicGuidance,
    required this.questionIntent,
    required this.questionIntentLabel,
    required this.directAnswer,
    required this.evidenceSummary,
    required this.evidence,
  });

  static const interpretationId = 'meihua.local-reading';
  static const interpretationVersion = 4;

  final String id;
  final int version;
  final String traditionalOverview;
  final String situation;
  final String process;
  final String trend;
  final String action;
  final String riskReminder;
  final String topic;
  final String topicLabel;
  final String topicGuidance;
  final String questionIntent;
  final String questionIntentLabel;
  final String directAnswer;
  final String evidenceSummary;
  final DivinationEvidence evidence;

  factory MeihuaInterpretation.build(
    MeihuaResult result, {
    String topic = 'general',
    DivinationQuestion? question,
  }) {
    final relationReading = switch (result.tiYongRelation) {
      '比和' => (
        situation: '主体与外部条件处在相近的节奏，暂时没有明显的一方压倒另一方。',
        action: '先把目标、责任和执行顺序说清楚，再通过实际进展判断是否继续投入。',
        risk: '条件相近不等于自然顺利，若双方都等待对方行动，事情仍可能停滞。',
      ),
      '用生体' => (
        situation: '外部条件对主体形成支持，较容易获得资源、信息或他人的配合。',
        action: '可以接住已有支持，但仍要确认支持是否稳定、具体条件是否真正落实。',
        risk: '不要把暂时的帮助理解成必然结果，关键承诺仍需用行动和时间验证。',
      ),
      '体生用' => (
        situation: '主体正在向外部事务投入精力、时间或资源，推进过程会产生一定消耗。',
        action: '先设定投入上限和阶段目标，小步验证回报，再决定是否继续加码。',
        risk: '主要风险是投入超过承受范围，或因为已经付出而不愿及时调整方向。',
      ),
      '用克体' => (
        situation: '外部条件对主体形成约束或压力，当前推进阻力相对明显。',
        action: '优先识别真正的限制条件，降低正面硬碰的成本，并为计划保留替代路径。',
        risk: '在条件尚未改善时强行推进，可能放大时间、资源或沟通成本。',
      ),
      '体克用' => (
        situation: '主体对外部事务具有一定主动权，但需要持续投入才能保持控制。',
        action: '可以主动推进，同时把范围、节奏和退出条件控制在自己能够承担的程度。',
        risk: '有主动权不代表没有代价，过度控制或推进过快仍可能造成反弹。',
      ),
      _ => throw StateError('不支持的梅花体用关系：${result.tiYongRelation}'),
    };

    final topicReading = _topicReading(topic, result.tiYongRelation);
    final resolvedQuestion =
        question ?? DivinationQuestion.parse('', topic: topic);
    final focused = _focusedReading(result, resolvedQuestion);
    final evidence = MeihuaEvidenceBuilder.build(result, resolvedQuestion);
    return MeihuaInterpretation(
      id: interpretationId,
      version: interpretationVersion,
      traditionalOverview:
          '本卦“${result.original.name}”看当前，互卦“${result.inter.name}”看内部过程，'
          '变卦“${result.changed.name}”看后续转向。${result.movingYaoName}发动，'
          '体卦为${result.tiGua.name}${result.tiGua.element}，用卦为${result.yongGua.name}${result.yongGua.element}，'
          '体用关系为“${result.tiYongRelation}”。',
      situation:
          '${relationReading.situation}本卦“${result.original.name}”的卦辞为“${result.original.description}”，'
          '可先把它作为当前局面的主题，再与现实事实逐项核对。',
      process:
          '互卦“${result.inter.name}”反映事情内部的推进过程，卦辞为“${result.inter.description}”。'
          '重点检查中间环节、沟通方式和尚未显现的条件，不只看表面结果。',
      trend:
          '${result.movingYaoName}爻辞为“${result.movingYaoCi}”。变化后转为“${result.changed.name}”，'
          '其卦辞为“${result.changed.description}”。这表示后续观察重点发生转移，但不是对具体事件的必然预言。',
      action: relationReading.action,
      riskReminder:
          '${relationReading.risk}卦象适合用来整理变量和行动节奏，不应替代医疗、法律、财务或其他专业判断。',
      topic: topicReading.topic,
      topicLabel: topicReading.label,
      topicGuidance: topicReading.guidance,
      questionIntent: resolvedQuestion.intent.id,
      questionIntentLabel: resolvedQuestion.intent.label,
      directAnswer: focused.answer,
      evidenceSummary: '${focused.evidence}${evidence.summary}',
      evidence: evidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'traditionalOverview': traditionalOverview,
    'situation': situation,
    'process': process,
    'trend': trend,
    'action': action,
    'riskReminder': riskReminder,
    'topic': topic,
    'topicLabel': topicLabel,
    'topicGuidance': topicGuidance,
    'questionIntent': questionIntent,
    'questionIntentLabel': questionIntentLabel,
    'directAnswer': directAnswer,
    'evidenceSummary': evidenceSummary,
    'evidence': evidence.toJson(),
  };

  static MeihuaInterpretation? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    String? text(String key) => map[key] is String ? map[key] as String : null;
    final id = text('id');
    final version = (map['version'] as num?)?.toInt();
    final fields = [
      text('traditionalOverview'),
      text('situation'),
      text('process'),
      text('trend'),
      text('action'),
      text('riskReminder'),
    ];
    if (id == null || version == null || fields.any((value) => value == null)) {
      return null;
    }
    return MeihuaInterpretation(
      id: id,
      version: version,
      traditionalOverview: fields[0]!,
      situation: fields[1]!,
      process: fields[2]!,
      trend: fields[3]!,
      action: fields[4]!,
      riskReminder: fields[5]!,
      topic: text('topic') ?? 'general',
      topicLabel: text('topicLabel') ?? '综合事项',
      topicGuidance: text('topicGuidance') ?? '结合保存时的占问背景与现实进展综合判断。',
      questionIntent: text('questionIntent') ?? 'general',
      questionIntentLabel: text('questionIntentLabel') ?? '综合分析',
      directAnswer: text('directAnswer') ?? '请结合卦象与现实情况综合判断。',
      evidenceSummary: text('evidenceSummary') ?? '旧版记录未保存问题意图证据。',
      evidence:
          DivinationEvidence.tryParse(map['evidence']) ??
          const DivinationEvidence(
            methodId: 'meihua',
            version: 0,
            calculationFacts: [],
            supportingEvidence: [],
            counterEvidence: [],
            limitations: [],
            summary: '旧版记录未保存结构化证据。',
          ),
    );
  }

  static ({String topic, String label, String guidance}) _topicReading(
    String topic,
    String relation,
  ) {
    final pressure = relation == '用克体';
    final support = relation == '用生体';
    return switch (topic) {
      'career' => (
        topic: topic,
        label: '事业工作',
        guidance: pressure
            ? '先处理制度、资源或协作阻力，暂缓扩大职责范围；把下一步拆成可验证的小目标。'
            : support
            ? '外部条件较有帮助，可以主动争取资源、明确责任和交付节点。'
            : '重点核对职责边界、执行节奏和实际成果，不只依据口头承诺。',
      ),
      'relationship' => (
        topic: topic,
        label: '感情关系',
        guidance: pressure
            ? '先降低对抗，确认彼此真实需求和边界；不宜用一次情绪反应判断整段关系。'
            : support
            ? '关系中存在回应和支持，可以通过具体沟通确认双方期待。'
            : '观察言行是否一致，给沟通留出时间，同时保留自己的边界。',
      ),
      'wealth' => (
        topic: topic,
        label: '财运经营',
        guidance: pressure
            ? '优先控制损失、现金流和不可逆承诺，不在压力下追加高风险投入。'
            : support
            ? '资源条件相对有利，但仍要核实成本、期限和退出条件。'
            : '以可承受的小额验证为先，记录真实收益和成本后再决定是否加码。',
      ),
      'health' => (
        topic: topic,
        label: '健康状态',
        guidance: '把卦象只作为生活节奏提醒，关注休息、压力和持续症状；身体不适应以正规医疗评估为准。',
      ),
      'study' => (
        topic: topic,
        label: '学业考试',
        guidance: pressure
            ? '先定位薄弱环节和时间压力，减少无效重复，按优先级逐项补强。'
            : '建立复习节奏和反馈点，用练习结果检验掌握程度，而不是只看投入时长。',
      ),
      _ => (
        topic: 'general',
        label: '综合事项',
        guidance: '先把目标、限制条件和可验证的下一步写清楚，再依据现实反馈调整判断。',
      ),
    };
  }

  static ({String answer, String evidence}) _focusedReading(
    MeihuaResult result,
    DivinationQuestion question,
  ) {
    final relation = result.tiYongRelation;
    final favorable =
        relation == '用生体' || relation == '体克用' || relation == '比和';
    final direction = _trigramDirection(result.yongGua.name);
    final scene = _trigramScene(result.yongGua.name);
    final pace = result.movingYaoIndex <= 2
        ? '变化较早，可先观察近期出现的信号'
        : result.movingYaoIndex <= 4
        ? '需要经过一段推进过程，不宜只看眼前一次反馈'
        : '变化偏后，宜先积累条件，再等待更明确的节点';
    final evidence =
        '依据用卦${result.yongGua.name}（${result.yongGua.element}）、体用关系“$relation”、'
        '${result.movingYaoName}以及本卦${result.original.name}综合整理。';

    final answer = switch (question.intent) {
      DivinationQuestionIntent.location =>
        '地点上优先留意$direction方向，以及$scene一类场景。这里表示传统卦象对应的观察线索，不是唯一或确定地址。',
      DivinationQuestionIntent.timing => '$pace。应期只能作为观察窗口，不能当作确定日期。',
      DivinationQuestionIntent.person =>
        '人物线索更接近“${result.yongGua.nature}”的气质，并带有${result.yongGua.element}的象意；应以真实交往中的行为一致性验证。',
      DivinationQuestionIntent.cause =>
        relation == '用克体'
            ? '当前主要阻力更偏向外部条件、他人要求或现实限制，需要先确认真正卡点。'
            : relation == '体生用'
            ? '主要问题可能是自身投入和消耗偏多，应检查付出是否获得有效反馈。'
            : '原因不宜归结为单一因素，重点检查双方节奏、信息和中间执行环节。',
      DivinationQuestionIntent.trend =>
        '事情会从${result.original.name}所代表的当前局面，经${result.inter.name}的内部过程，转向${result.changed.name}的后续主题；$pace。',
      DivinationQuestionIntent.action =>
        '$pace。下一步应围绕“${result.tiYongRelation}”调整投入与边界，并选择一个可以验证的小行动。',
      DivinationQuestionIntent.risk =>
        relation == '用克体'
            ? '首要风险是外部压力和限制被低估，不宜在条件不清楚时强行推进。'
            : '主要风险是把卦象提示当成确定结论，应持续核对现实证据和成本。',
      DivinationQuestionIntent.yesNo =>
        favorable
            ? '当前条件偏向可以继续尝试，但属于“有条件可行”，仍需用后续事实验证。'
            : '当前条件偏谨慎，不适合直接视为肯定结果，宜先解决阻力再决定。',
      DivinationQuestionIntent.general =>
        '当前重点是${result.tiYongRelation}所反映的主客关系。$pace，并结合现实反馈逐步调整。',
    };
    return (answer: answer, evidence: evidence);
  }

  static String _trigramDirection(String trigram) =>
      const {
        '乾': '西北',
        '兑': '西',
        '离': '南',
        '震': '东',
        '巽': '东南',
        '坎': '北',
        '艮': '东北',
        '坤': '西南',
      }[trigram] ??
      '与当前生活轨迹相关的';

  static String _trigramScene(String trigram) =>
      const {
        '乾': '机构、管理、交通或较正式',
        '兑': '交流、娱乐、餐饮或朋友聚会',
        '离': '文化、展示、网络、影像或明亮',
        '震': '出行、运动、新项目或人员流动',
        '巽': '学习、商务、传播、旅行或线上沟通',
        '坎': '夜间、临水、交通、技术或流动性较强',
        '艮': '学校、培训、山地、建筑或相对安静',
        '坤': '社区、家宅、土地、服务或熟人介绍',
      }[trigram] ??
      '日常活动';
}
