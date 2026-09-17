/// 小六壬核心算法
///
/// 完整移植自 mingyu-core/src/divination/algorithms/xiaoliuren.ts
library;

import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';

import '../../calendar/date_utils.dart';
import '../../shared/result.dart';
import 'rules.dart';

/// 小六壬起课方法
enum XiaoliurenMethod {
  time, // 时间起课
}

const _chinaTimeOffset = Duration(hours: 8);

/// 小六壬统一使用的四柱干支信息。
class XiaoliurenGanzhi {
  final String year;
  final String month;
  final String day;
  final String hour;

  const XiaoliurenGanzhi({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'day': day,
    'hour': hour,
  };
}

/// 小六壬宫位详情
class XiaoliurenPalaceDetail {
  final String name;
  final int index;
  final String verse;

  const XiaoliurenPalaceDetail({
    required this.name,
    required this.index,
    required this.verse,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'index': index,
    'verse': verse,
  };
}

/// 小六壬计算过程
class XiaoliurenCalculation {
  final int lunarMonth;
  final int lunarDay;
  final int hourNumber;
  final int monthSeed;
  final int daySeed;
  final int hourSeed;
  final int monthPalaceIndex;
  final int dayPalaceIndex;
  final int hourPalaceIndex;
  final String dayBoundary;
  final String leapMonthRule;
  final int timezoneOffsetMinutes;

  const XiaoliurenCalculation({
    required this.lunarMonth,
    required this.lunarDay,
    required this.hourNumber,
    required this.monthSeed,
    required this.daySeed,
    required this.hourSeed,
    required this.monthPalaceIndex,
    required this.dayPalaceIndex,
    required this.hourPalaceIndex,
    required this.dayBoundary,
    required this.leapMonthRule,
    required this.timezoneOffsetMinutes,
  });

  Map<String, dynamic> toJson() => {
    'lunarMonth': lunarMonth,
    'lunarDay': lunarDay,
    'hourNumber': hourNumber,
    'monthSeed': monthSeed,
    'daySeed': daySeed,
    'hourSeed': hourSeed,
    'monthPalaceIndex': monthPalaceIndex,
    'dayPalaceIndex': dayPalaceIndex,
    'hourPalaceIndex': hourPalaceIndex,
    'dayBoundary': dayBoundary,
    'leapMonthRule': leapMonthRule,
    'timezoneOffsetMinutes': timezoneOffsetMinutes,
  };
}

/// 小六壬结构化证据。月宫和日宫仅作为计算轨迹，时宫才是主证。
class XiaoliurenEvidenceAnalysis {
  final String status;
  final List<Map<String, dynamic>> calculationSteps;
  final List<Map<String, dynamic>> palaceFacts;
  final List<String> limitations;
  final String promptText;
  final List<String> interpretationOrder;

  const XiaoliurenEvidenceAnalysis({
    required this.status,
    required this.calculationSteps,
    required this.palaceFacts,
    required this.limitations,
    required this.promptText,
    required this.interpretationOrder,
  });

  Map<String, dynamic> toJson() => {
    'key': 'xiaoliuren:evidence',
    'status': status,
    'calculationSteps': calculationSteps,
    'palaceFacts': palaceFacts,
    'primaryFact': palaceFacts.last,
    'limitations': limitations,
    'promptText': promptText,
    'interpretationOrder': interpretationOrder,
  };
}

/// 小六壬结果数据
class XiaoliurenData {
  final ResultMeta meta;
  final XiaoliurenRule rule;
  final String ruleLabel;
  final XiaoliurenMethod method;
  final String methodLabel;
  final DateTime timestamp;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final int hourIndex;
  final String hourLabel;
  final XiaoliurenGanzhi ganzhi;
  final XiaoliurenCalculation calculation;
  final Map<String, XiaoliurenPalaceDetail> sequence;
  final List<XiaoliurenPalaceDetail> palaceOrder;
  final XiaoliurenPalaceDetail primary;
  final XiaoliurenEvidenceAnalysis evidenceAnalysis;

  const XiaoliurenData({
    required this.meta,
    required this.rule,
    required this.ruleLabel,
    required this.method,
    required this.methodLabel,
    required this.timestamp,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    required this.hourIndex,
    required this.hourLabel,
    required this.ganzhi,
    required this.calculation,
    required this.sequence,
    required this.palaceOrder,
    required this.primary,
    required this.evidenceAnalysis,
  });

  Map<String, dynamic> toJson() => {
    'meta': meta.toJson(),
    'rule': rule.name,
    'ruleLabel': ruleLabel,
    'method': method.name,
    'methodLabel': methodLabel,
    'timestamp': timestamp.toIso8601String(),
    'lunarMonth': lunarMonth,
    'lunarDay': lunarDay,
    'isLeapMonth': isLeapMonth,
    'hourIndex': hourIndex,
    'hourLabel': hourLabel,
    'ganzhi': ganzhi.toJson(),
    'calculation': calculation.toJson(),
    'sequence': sequence.map((key, value) => MapEntry(key, value.toJson())),
    'palaceOrder': palaceOrder.map((p) => p.toJson()).toList(),
    'primary': primary.toJson(),
    'evidenceAnalysis': evidenceAnalysis.toJson(),
  };
}

({DateTime instant, DateTime civil}) _resolveChinaTime(DateTime? customDate) {
  if (customDate == null) {
    final instant = DateTime.now().toUtc();
    return (instant: instant, civil: instant.add(_chinaTimeOffset));
  }

  if (customDate.isUtc) {
    return (instant: customDate, civil: customDate.add(_chinaTimeOffset));
  }

  // Flutter 的日期时间选择器返回本地 DateTime。这里把其中的墙上时间字段
  // 明确解释为东八区民用时间，避免设备时区改变同一输入的排盘结果。
  final civil = DateTime.utc(
    customDate.year,
    customDate.month,
    customDate.day,
    customDate.hour,
    customDate.minute,
    customDate.second,
    customDate.millisecond,
    customDate.microsecond,
  );
  return (instant: civil.subtract(_chinaTimeOffset), civil: civil);
}

/// 六宫数据
const _xiaoliurenPalaces = [
  XiaoliurenPalaceDetail(
    name: '大安',
    index: 0,
    verse: '大安事事昌，求财在坤方，失物去不远，宅舍保安康，行人身未动，病者主无妨，将军回田野，仔细更推详。',
  ),
  XiaoliurenPalaceDetail(
    name: '留连',
    index: 1,
    verse: '留连事难成，求谋日未明，官事凡宜缓，去者未回程，失物南方见，急讨方心称，更须防口舌，人口且平平。',
  ),
  XiaoliurenPalaceDetail(
    name: '速喜',
    index: 2,
    verse: '速喜喜来临，求财向南行，失物申午未，逢人路上寻，官事有福德，病者无祸侵，田宅六畜吉，行人有信音。',
  ),
  XiaoliurenPalaceDetail(
    name: '赤口',
    index: 3,
    verse: '赤口主口舌，官非切宜防，失物急去寻，行人有惊慌，六畜多作怪，病者出西方，更须防咀咒，恐怕染瘟皇。',
  ),
  XiaoliurenPalaceDetail(
    name: '小吉',
    index: 4,
    verse: '小吉最吉昌，路上好商量，阴人来报喜，失物在坤方，行人立便至，交关甚是强，凡事皆和合，病者叩穷苍。',
  ),
  XiaoliurenPalaceDetail(
    name: '空亡',
    index: 5,
    verse: '空亡事不祥，阴人多乖张，求财无利益，行人有灾殃，失物寻不见，官事有刑伤，病人逢暗鬼，祈解保安康。',
  ),
];

/// 根据索引获取宫位
XiaoliurenPalaceDetail _palaceAt(int index, XiaoliurenRule rule) {
  final normalizedIndex = ((index % 6) + 6) % 6;
  final palace = _xiaoliurenPalaces[normalizedIndex];

  // 如果是《多能鄙事》规则，使用对应的歌诀
  if (rule == XiaoliurenRule.duoneng) {
    return XiaoliurenPalaceDetail(
      name: palace.name,
      index: palace.index,
      verse: duonengXiaoliurenVerses[palace.index],
    );
  }

  return palace;
}

/// 验证六宫数据
void _assertReferenceData() {
  const expected = ['大安', '留连', '速喜', '赤口', '小吉', '空亡'];

  if (_xiaoliurenPalaces.length != 6) {
    throw StateError('小六壬六宫数量必须是 6 个');
  }

  for (int i = 0; i < 6; i++) {
    final palace = _xiaoliurenPalaces[i];
    if (palace.index != i ||
        palace.name != expected[i] ||
        palace.verse.isEmpty) {
      throw StateError('小六壬六宫顺序或歌诀资料不完整。');
    }
  }
}

XiaoliurenEvidenceAnalysis _buildEvidence({
  required XiaoliurenRuleDetail rule,
  required int lunarMonth,
  required int lunarDay,
  required bool isLeapMonth,
  required int hourNumber,
  required String hourLabel,
  required int monthPalaceIndex,
  required int dayPalaceIndex,
  required int hourPalaceIndex,
  required Map<String, XiaoliurenPalaceDetail> sequence,
}) {
  final steps = <Map<String, dynamic>>[
    {
      'key': 'xiaoliuren:calculation:month',
      'stage': '定月宫',
      'status': '已计算',
      'formula':
          '正月从大安起：($lunarMonth-1) mod 6=$monthPalaceIndex，落${sequence['month']!.name}',
      'dependsOnStepKeys': <String>[],
      'limitation': '月宫只确定日数起点，不是现实起因。',
    },
    {
      'key': 'xiaoliuren:calculation:day',
      'stage': '定日宫',
      'status': '已计算',
      'formula':
          '${rule.dayStartOffset > 0 ? '月宫下一宫起初一' : '月上起初一'}：'
          '($lunarMonth+$lunarDay-${2 - rule.dayStartOffset}) mod 6=$dayPalaceIndex，落${sequence['day']!.name}',
      'dependsOnStepKeys': ['xiaoliuren:calculation:month'],
      'limitation': '日宫只确定时辰起点，不是现实过程。',
    },
    {
      'key': 'xiaoliuren:calculation:hour',
      'stage': '定时宫',
      'status': '已计算',
      'formula':
          '日上起子时：($lunarMonth+$lunarDay+$hourNumber-${3 - rule.dayStartOffset}) '
          'mod 6=$hourPalaceIndex，落${sequence['hour']!.name}',
      'dependsOnStepKeys': ['xiaoliuren:calculation:day'],
      'limitation': '时宫是本次占得宫，但宫名和歌诀不等于现实必然结果。',
    },
  ];
  final palaceFacts = <Map<String, dynamic>>[
    {
      'key': 'xiaoliuren:palace:month',
      'role': '月宫',
      'level': '计算轨迹',
      'palace': sequence['month']!.toJson(),
      'limitation': '不得解释成事情起因或月运。',
    },
    {
      'key': 'xiaoliuren:palace:day',
      'role': '日宫',
      'level': '计算轨迹',
      'palace': sequence['day']!.toJson(),
      'limitation': '不得解释成事情过程或日运。',
    },
    {
      'key': 'xiaoliuren:palace:hour',
      'role': '时宫',
      'level': '主证',
      'palace': sequence['hour']!.toJson(),
      'limitation': '歌诀是传统分类文本，不是现实事实或确定预测。',
    },
  ];
  const limitations = <String>[
    '月宫和日宫只是顺数中间位置，只有时宫是本次占得宫。',
    '歌诀不得直接解释为疾病、灾殃、官非、方位或吉凶的确定结论。',
    '闰月沿用同名月序，农历日按东八区民用日零点换日。',
    '未采用无可核验出处的宫间五行推进、固定应期和通用方位扩展。',
  ];
  final promptText = [
    '【传统依据】',
    rule.source,
    '',
    '【排盘资料】',
    '农历：${isLeapMonth ? '闰' : ''}$lunarMonth月$lunarDay日，$hourLabel',
    '顺数轨迹：月宫${sequence['month']!.name}；日宫${sequence['day']!.name}；时宫${sequence['hour']!.name}',
    '占得宫：${sequence['hour']!.name}',
    '歌诀原文：${sequence['hour']!.verse}',
  ].join('\n');
  return XiaoliurenEvidenceAnalysis(
    status: '已计算',
    calculationSteps: steps,
    palaceFacts: palaceFacts,
    limitations: limitations,
    promptText: promptText,
    interpretationOrder: const [
      '先复核农历月、日和时辰数，再逐步复算月宫、日宫、时宫。',
      '只把时宫作为本次占得宫，月宫和日宫仅保留为计算轨迹。',
      '按所问事项选择时宫歌诀中的对应句义，不跨事项套用。',
      '把歌诀视为传统分类材料，不输出确定灾病、官非、方位或应期。',
    ],
  );
}

/// 生成小六壬时间课
///
/// 闰月沿用同名月序；农历日按东八区民用日零点换日。
XiaoliurenData generateXiaoliuren({
  XiaoliurenMethod? method,
  XiaoliurenRule? rule,
  DateTime? customDate,
}) {
  // 验证六宫数据
  _assertReferenceData();

  final ruleDetail = resolveXiaoliurenRule(rule);
  final actualMethod = method ?? XiaoliurenMethod.time;

  if (actualMethod != XiaoliurenMethod.time) {
    throw ArgumentError('小六壬当前仅保留有明确顺数规则的时间起课。');
  }

  // 小六壬统一按东八区民用时间读取农历和时辰。
  final resolvedTime = _resolveChinaTime(customDate);
  final timestamp = resolvedTime.instant;
  final civilTime = resolvedTime.civil;

  // 使用 lunar 库获取农历信息
  final solar = Solar.fromDate(civilTime);
  final lunar = solar.getLunar();

  final lunarMonth = lunar.getMonth();
  final lunarDay = lunar.getDay();
  final isLeapMonth = lunar.getMonth() < 0; // lunar 库用负数表示闰月
  final lunarMonthAbs = lunarMonth.abs();

  // 获取时辰信息
  final hour = civilTime.hour;
  final minute = civilTime.minute;
  final clockHourIndex = getTimeIndexFromClock(hour, minute);
  final shichen = getShichenByIndex(clockHourIndex);

  if (shichen == null) {
    throw ArgumentError('小六壬时辰索引无效：$clockHourIndex');
  }

  // dateUtils 以 0 表示早子、12 表示晚子；掌诀均按子1至亥12计数
  final hourNumber = (clockHourIndex % 12) + 1;

  // 计算种子和宫位索引
  final monthSeed = lunarMonthAbs;
  final daySeed = lunarMonthAbs + lunarDay - 1 + ruleDetail.dayStartOffset;
  final hourSeed =
      lunarMonthAbs + lunarDay + hourNumber - 2 + ruleDetail.dayStartOffset;

  final monthPalaceIndex = (monthSeed - 1) % 6;
  final dayPalaceIndex = (daySeed - 1) % 6;
  final hourPalaceIndex = (hourSeed - 1) % 6;

  final sequence = <String, XiaoliurenPalaceDetail>{
    'month': _palaceAt(monthPalaceIndex, ruleDetail.id),
    'day': _palaceAt(dayPalaceIndex, ruleDetail.id),
    'hour': _palaceAt(hourPalaceIndex, ruleDetail.id),
  };
  final palaceOrder = _xiaoliurenPalaces
      .map((palace) => _palaceAt(palace.index, ruleDetail.id))
      .toList();
  final evidenceAnalysis = _buildEvidence(
    rule: ruleDetail,
    lunarMonth: lunarMonthAbs,
    lunarDay: lunarDay,
    isLeapMonth: isLeapMonth,
    hourNumber: hourNumber,
    hourLabel: shichen.name,
    monthPalaceIndex: monthPalaceIndex,
    dayPalaceIndex: dayPalaceIndex,
    hourPalaceIndex: hourPalaceIndex,
    sequence: sequence,
  );
  final meta = createResultMeta(
    descriptor: ruleDetail.id == XiaoliurenRule.duoneng
        ? AlgorithmCatalog.xiaoliurenDuoneng
        : AlgorithmCatalog.xiaoliurenCommon,
    input: {
      'method': actualMethod.name,
      'rule': ruleDetail.id.name,
      'timestamp': timestamp,
    },
    calculatedAt: timestamp,
  );

  // 构建结果
  final data = XiaoliurenData(
    meta: meta,
    rule: ruleDetail.id,
    ruleLabel: ruleDetail.label,
    method: actualMethod,
    methodLabel: '时间起课',
    timestamp: timestamp,
    lunarMonth: lunarMonthAbs,
    lunarDay: lunarDay,
    isLeapMonth: isLeapMonth,
    hourIndex: clockHourIndex,
    hourLabel: shichen.name,
    ganzhi: XiaoliurenGanzhi(
      year: lunar.getYearInGanZhiExact(),
      month: lunar.getMonthInGanZhiExact(),
      day: lunar.getDayInGanZhiExact(),
      hour: lunar.getTimeInGanZhi(),
    ),
    calculation: XiaoliurenCalculation(
      lunarMonth: lunarMonthAbs,
      lunarDay: lunarDay,
      hourNumber: hourNumber,
      monthSeed: monthSeed,
      daySeed: daySeed,
      hourSeed: hourSeed,
      monthPalaceIndex: monthPalaceIndex,
      dayPalaceIndex: dayPalaceIndex,
      hourPalaceIndex: hourPalaceIndex,
      dayBoundary: '东八区民用日零点换日',
      leapMonthRule: '闰月沿用同名月序',
      timezoneOffsetMinutes: 480,
    ),
    sequence: sequence,
    palaceOrder: palaceOrder,
    primary: sequence['hour']!,
    evidenceAnalysis: evidenceAnalysis,
  );

  return data;
}
