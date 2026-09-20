import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_evidence.dart';

const compatibilityAlgorithmId = 'compatibility';
const compatibilityAlgorithmVersion = 1;

enum CompatibilityRelation {
  romance('恋爱'),
  marriage('婚姻'),
  friendship('朋友'),
  parentChild('亲子'),
  partnership('合作');

  const CompatibilityRelation(this.label);
  final String label;
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.first,
    required this.second,
    required this.relation,
    required this.score,
    required this.level,
    required this.headline,
    required this.overview,
    required this.firstZodiac,
    required this.secondZodiac,
    required this.firstElement,
    required this.secondElement,
    required this.strengths,
    required this.frictions,
    required this.actions,
    required this.evidence,
  });

  factory CompatibilityResult.build({
    required CaseSnapshot first,
    required CaseSnapshot second,
    required CompatibilityRelation relation,
  }) {
    if (first.caseId == second.caseId) {
      throw ArgumentError('合盘必须选择两个不同角色');
    }
    final firstLunar = _birthLunar(first);
    final secondLunar = _birthLunar(second);
    final firstZodiac = firstLunar.getYearShengXiao();
    final secondZodiac = secondLunar.getYearShengXiao();
    final firstElement = _yearElement(firstLunar.getYearGan());
    final secondElement = _yearElement(secondLunar.getYearGan());
    final zodiacRelation = _zodiacRelation(firstZodiac, secondZodiac);
    final elementRelation = _elementRelation(firstElement, secondElement);
    final seasonRelation = _seasonRelation(
      first.birthDateTime.month,
      second.birthDateTime.month,
    );
    final ids = [first.stableHash, second.stableHash]..sort();
    final seed = _stableSeed('${ids.join('|')}|${relation.name}|v1');
    var score = 58 + seed % 13;
    score += zodiacRelation.$2;
    score += elementRelation.$2;
    score += seasonRelation.$2;
    score = score.clamp(35, 94).toInt();
    final strengths = <String>[
      zodiacRelation.$2 >= 0 ? zodiacRelation.$3 : '彼此差异明显，适合建立清晰分工',
      elementRelation.$2 >= 0 ? elementRelation.$3 : '表达方式不同，能够提供另一种观察角度',
      seasonRelation.$2 >= 0 ? seasonRelation.$3 : '生活节奏不同，需要主动协调时间与优先级',
    ];
    final frictions = <String>[
      if (zodiacRelation.$2 < 0) zodiacRelation.$3,
      if (elementRelation.$2 < 0) elementRelation.$3,
      if (seasonRelation.$2 < 0) seasonRelation.$3,
      if (zodiacRelation.$2 >= 0 && elementRelation.$2 >= 0)
        '条件较顺时也要避免替对方做决定，把默契落实为明确沟通',
    ];
    final actions = _actionsFor(relation);
    final level = switch (score) {
      >= 82 => '高度协调',
      >= 70 => '较为协调',
      >= 58 => '互补可磨合',
      >= 46 => '需要经营',
      _ => '差异较大',
    };
    final headline = '$level · ${first.displayName}与${second.displayName}';
    final overview = score >= 70
        ? '双方存在可利用的共同点，但稳定关系仍取决于现实沟通、边界和持续行动。'
        : '双方差异比共同点更突出，关系并非不能推进，但需要把期待、责任与沟通方式说清楚。';
    final evidence = DivinationEvidence(
      methodId: compatibilityAlgorithmId,
      version: compatibilityAlgorithmVersion,
      calculationFacts: [
        DivinationEvidenceItem(
          id: 'subjects',
          label: '合盘主体',
          detail:
              '${first.displayName}与${second.displayName} · ${relation.label}',
        ),
        DivinationEvidenceItem(
          id: 'zodiac',
          label: '生肖关系',
          detail: '属$firstZodiac与属$secondZodiac：${zodiacRelation.$1}',
        ),
        DivinationEvidenceItem(
          id: 'elements',
          label: '年干五行',
          detail: '$firstElement与$secondElement：${elementRelation.$1}',
        ),
      ],
      supportingEvidence: [
        for (final item in strengths)
          DivinationEvidenceItem(
            id: 'strength-${strengths.indexOf(item)}',
            label: '相处优势',
            detail: item,
          ),
      ],
      counterEvidence: [
        for (final item in frictions)
          DivinationEvidenceItem(
            id: 'risk-${frictions.indexOf(item)}',
            label: '磨合重点',
            detail: item,
          ),
      ],
      limitations: const [
        DivinationEvidenceItem(
          id: 'boundary',
          label: '适用边界',
          detail: '合盘只提供传统文化视角，不能证明感情结果、合作成败或他人的真实想法。',
        ),
      ],
      summary: '依据双方出生年生肖、年干五行、出生季节和关系类型进行版本化稳定整理。',
    );
    return CompatibilityResult(
      first: first,
      second: second,
      relation: relation,
      score: score,
      level: level,
      headline: headline,
      overview: overview,
      firstZodiac: firstZodiac,
      secondZodiac: secondZodiac,
      firstElement: firstElement,
      secondElement: secondElement,
      strengths: List.unmodifiable(strengths),
      frictions: List.unmodifiable(frictions),
      actions: List.unmodifiable(actions),
      evidence: evidence,
    );
  }

  final CaseSnapshot first;
  final CaseSnapshot second;
  final CompatibilityRelation relation;
  final int score;
  final String level;
  final String headline;
  final String overview;
  final String firstZodiac;
  final String secondZodiac;
  final String firstElement;
  final String secondElement;
  final List<String> strengths;
  final List<String> frictions;
  final List<String> actions;
  final DivinationEvidence evidence;

  String get stableId {
    final ids = [first.caseId, second.caseId]..sort();
    return 'compatibility:${ids.join(':')}:${relation.name}';
  }

  String get localAnswer =>
      '$headline。$overview 优势：${strengths.join('；')}。'
      '磨合重点：${frictions.join('；')}。建议：${actions.join('；')}。';
}

Lunar _birthLunar(CaseSnapshot value) {
  final birth = value.birthDateTime;
  return value.calendarType == CaseCalendarType.lunar
      ? Lunar.fromYmd(
          birth.year,
          value.isLeapMonth ? -birth.month : birth.month,
          birth.day,
        )
      : Solar.fromYmd(birth.year, birth.month, birth.day).getLunar();
}

String _yearElement(String gan) => switch (gan) {
  '甲' || '乙' => '木',
  '丙' || '丁' => '火',
  '戊' || '己' => '土',
  '庚' || '辛' => '金',
  _ => '水',
};

(String, int, String) _zodiacRelation(String left, String right) {
  if (left == right) return ('同生肖', 4, '熟悉彼此的节奏和反应方式，较容易形成默契');
  const harmonious = [
    {'鼠', '牛'},
    {'虎', '猪'},
    {'兔', '狗'},
    {'龙', '鸡'},
    {'蛇', '猴'},
    {'马', '羊'},
    {'鼠', '龙'},
    {'鼠', '猴'},
    {'牛', '蛇'},
    {'牛', '鸡'},
    {'虎', '马'},
    {'虎', '狗'},
    {'兔', '羊'},
    {'兔', '猪'},
    {'龙', '猴'},
    {'蛇', '鸡'},
    {'马', '狗'},
    {'羊', '猪'},
  ];
  const clashes = [
    {'鼠', '马'},
    {'牛', '羊'},
    {'虎', '猴'},
    {'兔', '鸡'},
    {'龙', '狗'},
    {'蛇', '猪'},
  ];
  final pair = {left, right};
  if (harmonious.any(
    (item) => item.length == pair.length && item.containsAll(pair),
  )) {
    return ('传统合关系', 13, '双方在传统生肖关系中较协调，容易找到共同语言');
  }
  if (clashes.any(
    (item) => item.length == pair.length && item.containsAll(pair),
  )) {
    return ('传统相冲关系', -14, '双方节奏与立场容易正面碰撞，需要避免把分歧升级为对错之争');
  }
  return ('普通关系', 1, '生肖层面没有明显合冲，关系质量更依赖现实互动');
}

(String, int, String) _elementRelation(String left, String right) {
  if (left == right) return ('同气', 5, '核心表达倾向相近，理解彼此的出发点相对容易');
  const generates = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
  if (generates[left] == right || generates[right] == left) {
    return ('相生', 9, '一方的长处较容易转化为对另一方的支持');
  }
  const controls = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
  if (controls[left] == right || controls[right] == left) {
    return ('相制', -7, '双方处理问题的方式容易互相牵制，需要明确边界和决定权');
  }
  return ('相邻', 1, '双方表达方式存在差异，也保留了互补空间');
}

(String, int, String) _seasonRelation(int leftMonth, int rightMonth) {
  int season(int month) => switch (month) {
    3 || 4 || 5 => 0,
    6 || 7 || 8 => 1,
    9 || 10 || 11 => 2,
    _ => 3,
  };
  final distance = (season(leftMonth) - season(rightMonth)).abs();
  if (distance == 0) return ('同季', 4, '双方的基础生活节奏和外部环境经验较接近');
  if (distance == 2) return ('对季', -3, '双方天然节奏差异较大，需要为彼此保留调整空间');
  return ('邻季', 2, '双方既有相似处，也能带来不同的行动节奏');
}

List<String> _actionsFor(CompatibilityRelation relation) => switch (relation) {
  CompatibilityRelation.romance || CompatibilityRelation.marriage => [
    '分别说清楚对关系的期待，不用试探代替沟通',
    '出现分歧时先确认事实，再讨论感受和解决方案',
    '保留各自空间，同时建立稳定的共同安排',
  ],
  CompatibilityRelation.friendship => [
    '尊重联系频率差异，不用回复速度衡量关系',
    '涉及金钱和承诺时提前说明边界',
    '用共同活动维持连接，也允许阶段性安静',
  ],
  CompatibilityRelation.parentChild => [
    '先区分照顾、建议和控制，给对方符合年龄的选择权',
    '批评行为而非否定人格',
    '固定安排不被打断的倾听时间',
  ],
  CompatibilityRelation.partnership => [
    '把职责、权限、交付标准和退出机制写清楚',
    '重要决定留下可复查记录',
    '定期对齐目标，避免默认双方理解一致',
  ],
};

int _stableSeed(String input) {
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
