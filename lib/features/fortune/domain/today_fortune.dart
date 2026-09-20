import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';

const todayFortuneAlgorithmId = 'today-fortune';
const todayFortuneAlgorithmVersion = 1;

enum FortuneLevel {
  excellent('大吉'),
  good('吉'),
  smallGood('小吉'),
  steady('平'),
  cautious('谨慎');

  const FortuneLevel(this.label);
  final String label;
}

class FortuneDimension {
  const FortuneDimension({
    required this.id,
    required this.label,
    required this.score,
    required this.summary,
  });

  final String id;
  final String label;
  final int score;
  final String summary;
}

class TodayFortune {
  const TodayFortune({
    required this.date,
    required this.dateKey,
    required this.lunarDate,
    required this.dayGanZhi,
    required this.zodiac,
    required this.caseId,
    required this.clashZodiac,
    required this.isClashing,
    required this.level,
    required this.overallScore,
    required this.headline,
    required this.summary,
    required this.luckyColor,
    required this.luckyDirection,
    required this.luckyNumber,
    required this.yi,
    required this.ji,
    required this.dimensions,
    required this.evidence,
    required this.algorithmId,
    required this.algorithmVersion,
  });

  factory TodayFortune.build(DateTime value, {CaseSnapshot? caseSnapshot}) {
    final date = DateTime(value.year, value.month, value.day);
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final zodiac = caseSnapshot == null ? null : _zodiacForCase(caseSnapshot);
    final clashZodiac = lunar.getDayChongShengXiao();
    final isClashing = zodiac != null && zodiac == clashZodiac;
    final dateKey = solar.toYmd();
    final seed = _stableSeed('$dateKey|${zodiac ?? 'general'}|v1');
    final yi = List<String>.unmodifiable(lunar.getDayYi());
    final ji = List<String>.unmodifiable(lunar.getDayJi());
    final base = 58 + seed % 25;
    final yiBoost = yi.length.clamp(0, 8);
    final jiPenalty = (ji.length ~/ 3).clamp(0, 6);
    final overall = (base + yiBoost - jiPenalty - (isClashing ? 12 : 0))
        .clamp(35, 95)
        .toInt();
    final level = _levelFor(overall);
    final colors = ['紫罗兰', '青绿色', '暖黄色', '米白色', '靛蓝色', '朱红色'];
    final directions = ['东方', '东南方', '南方', '西南方', '西方', '西北方', '北方', '东北方'];
    final dimensionSpecs = [
      ('career', '事业', 3, '先处理最明确的一件事，减少来回切换。'),
      ('wealth', '财运', 11, '适合核对预算与账目，不宜因情绪临时加码。'),
      ('relationship', '感情', 19, '把真实想法说清楚，比猜测对方更有效。'),
      ('wellbeing', '身心', 29, '留出休息和活动时间，避免把日程排得过满。'),
      ('action', '行动力', 37, '从小步骤启动，今天更重视持续推进。'),
    ];
    final dimensions = dimensionSpecs
        .map((spec) {
          var score = 48 + _stableSeed('$seed|${spec.$3}') % 43;
          if (isClashing) score -= 7;
          return FortuneDimension(
            id: spec.$1,
            label: spec.$2,
            score: score.clamp(30, 95).toInt(),
            summary: spec.$4,
          );
        })
        .toList(growable: false);
    final focus = dimensions.reduce(
      (left, right) => left.score >= right.score ? left : right,
    );
    final caution = dimensions.reduce(
      (left, right) => left.score <= right.score ? left : right,
    );
    final headline = isClashing
        ? '${level.label} · 今日宜放慢节奏，重要事项多确认一步'
        : '${level.label} · ${focus.label}较顺，${caution.label}注意节奏';
    final summary = isClashing
        ? '今日与你的生肖相冲，传统民俗上更适合复核、整理和稳步推进，避免仓促决定。'
        : '今日整体状态偏${overall >= 70 ? '积极' : '平稳'}，优先把精力放在${focus.label}，同时照顾${caution.label}方面的细节。';
    final evidence = DivinationEvidence(
      methodId: todayFortuneAlgorithmId,
      version: todayFortuneAlgorithmVersion,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'date',
          label: '日期干支',
          detail: '$dateKey · ${lunar.getDayInGanZhiExact()}日',
        ),
        DivinationEvidenceItem(
          id: 'zodiac',
          label: '生肖关系',
          detail: zodiac == null
              ? '未选择角色，使用通用日运'
              : '本人属$zodiac，今日冲$clashZodiac${isClashing ? '，存在相冲' : '，无直接相冲'}',
        ),
      ],
      supportingEvidence: [
        DivinationEvidenceItem(
          id: 'yi',
          label: '今日适合',
          detail: yi.take(6).join('、'),
        ),
      ],
      counterEvidence: [
        DivinationEvidenceItem(
          id: 'ji',
          label: '今日谨慎',
          detail: ji.take(6).join('、'),
        ),
      ],
      limitations: const [
        DivinationEvidenceItem(
          id: 'boundary',
          label: '适用边界',
          detail: '这是基于传统历法与稳定规则生成的日常提示，不预测具体事件，也不替代专业建议。',
        ),
      ],
      summary: '依据当日干支、宜忌、生肖冲合与版本化稳定种子生成。',
    );
    return TodayFortune(
      date: date,
      dateKey: dateKey,
      lunarDate: '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}',
      dayGanZhi: lunar.getDayInGanZhiExact(),
      zodiac: zodiac,
      caseId: caseSnapshot?.caseId,
      clashZodiac: clashZodiac,
      isClashing: isClashing,
      level: level,
      overallScore: overall,
      headline: headline,
      summary: summary,
      luckyColor: colors[seed % colors.length],
      luckyDirection: directions[(seed ~/ 7) % directions.length],
      luckyNumber: seed % 9 + 1,
      yi: yi,
      ji: ji,
      dimensions: List.unmodifiable(dimensions),
      evidence: evidence,
      algorithmId: todayFortuneAlgorithmId,
      algorithmVersion: todayFortuneAlgorithmVersion,
    );
  }

  final DateTime date;
  final String dateKey;
  final String lunarDate;
  final String dayGanZhi;
  final String? zodiac;
  final String? caseId;
  final String clashZodiac;
  final bool isClashing;
  final FortuneLevel level;
  final int overallScore;
  final String headline;
  final String summary;
  final String luckyColor;
  final String luckyDirection;
  final int luckyNumber;
  final List<String> yi;
  final List<String> ji;
  final List<FortuneDimension> dimensions;
  final DivinationEvidence evidence;
  final String algorithmId;
  final int algorithmVersion;

  String get localAnswer =>
      '$headline。$summary '
      '幸运色：$luckyColor；幸运方位：$luckyDirection；幸运数字：$luckyNumber。';
}

FortuneLevel _levelFor(int score) => switch (score) {
  >= 86 => FortuneLevel.excellent,
  >= 76 => FortuneLevel.good,
  >= 66 => FortuneLevel.smallGood,
  >= 52 => FortuneLevel.steady,
  _ => FortuneLevel.cautious,
};

String _zodiacForCase(CaseSnapshot snapshot) {
  final birth = snapshot.birthDateTime;
  if (snapshot.calendarType == CaseCalendarType.lunar) {
    final month = snapshot.isLeapMonth ? -birth.month : birth.month;
    return Lunar.fromYmd(birth.year, month, birth.day).getYearShengXiao();
  }
  return Solar.fromYmd(
    birth.year,
    birth.month,
    birth.day,
  ).getLunar().getYearShengXiao();
}

int _stableSeed(String input) {
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
