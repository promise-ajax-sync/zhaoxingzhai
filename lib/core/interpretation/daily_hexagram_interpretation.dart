import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/evidence/daily_hexagram_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

/// 每日一卦的本地结构化解读层。
///
/// 它只读取已经确定的 v3 卦盘，不参与起卦、变爻或取用规则计算。
/// 文案规则变化时提升 [version]，历史记录始终展示保存时的内容。
class DailyHexagramInterpretation {
  const DailyHexagramInterpretation({
    required this.id,
    required this.version,
    required this.traditionalOverview,
    required this.situation,
    required this.innerContext,
    required this.trend,
    required this.pace,
    required this.riskReminder,
    required this.questionIntent,
    required this.questionIntentLabel,
    required this.directAnswer,
    required this.evidence,
  });

  static const interpretationId = 'daily-hexagram.local-reading';
  static const interpretationVersion = 2;

  final String id;
  final int version;
  final String traditionalOverview;
  final String situation;
  final String innerContext;
  final String trend;
  final String pace;
  final String riskReminder;
  final String questionIntent;
  final String questionIntentLabel;
  final String directAnswer;
  final DivinationEvidence evidence;

  factory DailyHexagramInterpretation.build(
    DailyHexagramResult result, {
    DivinationQuestion? question,
  }) {
    final actualQuestion =
        question ??
        const DivinationQuestion(
          rawText: '',
          topic: 'general',
          intent: DivinationQuestionIntent.general,
        );
    final movingCount = result.movingLines.length;
    final primary = result.takingRule.primaryTexts.join('；');
    final secondary = result.takingRule.secondaryTexts.isEmpty
        ? ''
        : '辅看${result.takingRule.secondaryTexts.join('；')}。';
    final movingNames = result.movingLines.map((line) => line.name).join('、');

    final trend = movingCount == 0
        ? '六爻皆静，变卦仍为“${result.changed.name}”，当前结构没有明显翻转信号。宜先观察本卦主题如何延续，不必为了求变而另起方向。'
        : '共有$movingCount个动爻（$movingNames），后势转向“${result.changed.name}”。其卦辞为“${result.changed.description}”，可用来观察变化落定后的方向。';

    final pace = switch (movingCount) {
      0 => '节奏以稳定、落实和复核为主。先完成已有安排，再判断是否需要调整。',
      1 || 2 => '变化集中，适合围绕主取爻辞小步处理，并在每一步后核对实际反馈。',
      3 => '当前与后势力量相当，重要决定宜拆成可验证的步骤，同时对照本卦与变卦。',
      4 || 5 => '变化力量较强，优先守住静爻指出的立足点，避免在信息未定时一次投入过多。',
      _ => '整体结构正在转换，宜先保留回旋空间，再依据变卦方向安排下一步。',
    };

    final oldYinCount = result.yaos
        .where((yao) => yao == DailyHexagramYaoType.oldYin)
        .length;
    final oldYangCount = result.yaos
        .where((yao) => yao == DailyHexagramYaoType.oldYang)
        .length;
    final risk = movingCount == 0
        ? '静卦的风险在于把“稳定”误作“不需检查”。仍应核对现实条件，不把卦象当作确定结论。'
        : '本次含$oldYinCount个老阴、$oldYangCount个老阳。动爻越多，变量越多；应避免仅凭单句爻辞作重大决定，并为关键行动保留备选方案。';

    return DailyHexagramInterpretation(
      id: interpretationId,
      version: interpretationVersion,
      traditionalOverview:
          '本卦“${result.original.name}”主当前，互卦“${result.inter.name}”察内在过程，变卦“${result.changed.name}”看后势。${result.takingRule.summary}主取$primary。$secondary',
      situation:
          '本卦“${result.original.name}”，卦辞“${result.original.description}”。当前先围绕主取内容核对事实、责任与边界，再决定是否行动。',
      innerContext:
          '互卦“${result.inter.name}”，卦辞“${result.inter.description}”。它用于观察事情内部如何推进，可检查隐藏条件、沟通方式和尚未成熟的环节。',
      trend: trend,
      pace: pace,
      riskReminder: risk,
      questionIntent: actualQuestion.intent.id,
      questionIntentLabel: actualQuestion.intent.label,
      directAnswer: _directAnswer(actualQuestion.intent, result, pace),
      evidence: DailyHexagramEvidenceBuilder.build(result, actualQuestion),
    );
  }

  static String _directAnswer(
    DivinationQuestionIntent intent,
    DailyHexagramResult result,
    String pace,
  ) {
    final current =
        '本卦${result.original.name}提示：${result.original.description}';
    final future =
        '变卦${result.changed.name}提示后续方向：${result.changed.description}';
    return switch (intent) {
      DivinationQuestionIntent.yesNo =>
        '每日一卦不适合给出绝对的是或否。$current请先核对条件，再用当天的真实反馈决定是否继续。',
      DivinationQuestionIntent.timing => '本卦只能说明今天的行动节奏，不能给出精确日期。$pace',
      DivinationQuestionIntent.location =>
        '每日一卦不足以锁定具体地点或方位。$current可把重点放在今天应如何观察和行动。',
      DivinationQuestionIntent.person =>
        '卦象不能证明他人的真实内心或人物特征。$current建议以对方实际表达和行为为准。',
      DivinationQuestionIntent.cause =>
        '若要寻找今天的阻力或原因，可先从互卦${result.inter.name}所示的内部条件核对：${result.inter.description}',
      DivinationQuestionIntent.trend => '$current$future',
      DivinationQuestionIntent.action => '针对今天怎么做，建议是：$pace',
      DivinationQuestionIntent.risk =>
        '今天应重点避免把卦象当成确定结论；动爻越多，现实变量越需要逐项复核。$pace',
      DivinationQuestionIntent.general => '$current$future$pace',
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'traditionalOverview': traditionalOverview,
    'situation': situation,
    'innerContext': innerContext,
    'trend': trend,
    'pace': pace,
    'riskReminder': riskReminder,
    'questionIntent': questionIntent,
    'questionIntentLabel': questionIntentLabel,
    'directAnswer': directAnswer,
    'evidence': evidence.toJson(),
  };

  static DailyHexagramInterpretation? tryParse(Object? raw) {
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
      text('innerContext'),
      text('trend'),
      text('pace'),
      text('riskReminder'),
    ];
    if (id == null || version == null || fields.any((field) => field == null)) {
      return null;
    }
    return DailyHexagramInterpretation(
      id: id,
      version: version,
      traditionalOverview: fields[0]!,
      situation: fields[1]!,
      innerContext: fields[2]!,
      trend: fields[3]!,
      pace: fields[4]!,
      riskReminder: fields[5]!,
      questionIntent: text('questionIntent') ?? 'general',
      questionIntentLabel: text('questionIntentLabel') ?? '综合分析',
      directAnswer: text('directAnswer') ?? fields[1]!,
      evidence:
          DivinationEvidence.tryParse(map['evidence']) ??
          const DivinationEvidence(
            methodId: 'daily-hexagram',
            version: 0,
            calculationFacts: [],
            supportingEvidence: [],
            counterEvidence: [],
            limitations: [],
            summary: '旧版历史记录未保存结构化证据。',
          ),
    );
  }
}
