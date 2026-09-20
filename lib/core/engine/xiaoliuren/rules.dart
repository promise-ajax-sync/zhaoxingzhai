/// 小六壬规则定义
///
/// 小六壬规则定义。
library;

/// 小六壬起课规则
enum XiaoliurenRule {
  common, // 通行掌诀
  duoneng, // 《多能鄙事》
}

/// 规则详情
class XiaoliurenRuleDetail {
  final XiaoliurenRule id;
  final String label;
  final int dayStartOffset; // 日宫起始偏移
  final String source; // 口径来源

  const XiaoliurenRuleDetail({
    required this.id,
    required this.label,
    required this.dayStartOffset,
    required this.source,
  });
}

/// 规则选项
const xiaoliurenRuleOptions = [
  {'value': 'common', 'label': '通行掌诀'},
  {'value': 'duoneng', 'label': '《多能鄙事》'},
];

/// 解析小六壬规则
XiaoliurenRuleDetail resolveXiaoliurenRule([XiaoliurenRule? rule]) {
  final actualRule = rule ?? XiaoliurenRule.common;

  if (actualRule == XiaoliurenRule.duoneng) {
    return const XiaoliurenRuleDetail(
      id: XiaoliurenRule.duoneng,
      label: '《多能鄙事》',
      dayStartOffset: 1,
      source: '《多能鄙事》卷八"小六壬课时"：正月初一留连，二月初一速喜；日宫起子时，依大安、留连、速喜、赤口、小吉、空亡顺行',
    );
  }

  return const XiaoliurenRuleDetail(
    id: XiaoliurenRule.common,
    label: '通行掌诀',
    dayStartOffset: 0,
    source: '通行俗传小六壬掌诀：正月从大安起，月上起初一，日上起子时，依大安、留连、速喜、赤口、小吉、空亡顺行',
  );
}

/// 《多能鄙事》卷八小六壬课时歌诀
const duonengXiaoliurenVerses = [
  '大安时青龙主事，百事吉，失物在，行人未动。',
  '留连时玄武主事，凡事难成，求谋日未明，官事只可缓，去者未回程，失物巽上见，急讨方称情，更须防口舌，人口且平平。',
  '速喜时朱雀用事，有喜即至，行人来，公事了，失物离上可觅见。',
  '赤口时白虎用事，有口舌官灾，行人有惊，病者重，有咒咀，失物有争。',
  '小吉时六合主事，去行人至，失物坤方寻得，交关宜利。',
  '空亡时勾陈主事，求财无利，行人有灾，失物难觅，百事无成。',
];

/// 通行掌诀歌诀
const commonXiaoliurenVerses = [
  '大安事事昌，求财在坤方，失物去不远，宅舍保安康，行人身未动，病者主无妨，将军回田野，仔细更推详。',
  '留连事难成，求谋日未明，官事凡宜缓，去者未回程，失物南方见，急讨方心称，更须防口舌，人口且平平。',
  '速喜喜来临，求财向南行，失物申午未，逢人路上寻，官事有福德，病者无祸侵，田宅六畜吉，行人有信音。',
  '赤口主口舌，官非切宜防，失物急去寻，行人有惊慌，六畜多作怪，病者出西方，更须防咀咒，恐怕染瘟皇。',
  '小吉最吉昌，路上好商量，阴人来报喜，失物在坤方，行人立便至，交关甚是强，凡事皆和合，病者叩穷苍。',
  '空亡事不祥，阴人多乖张，求财无利益，行人有灾殃，失物寻不见，官事有刑伤，病人逢暗鬼，祈解保安康。',
];
