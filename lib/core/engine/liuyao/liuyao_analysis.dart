import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/liuyao/liuyao_divination.dart';

enum LiuyaoSeasonState { prosperous, supporting, resting, confined, weakened }

extension LiuyaoSeasonStateLabel on LiuyaoSeasonState {
  String get label => switch (this) {
    LiuyaoSeasonState.prosperous => '旺',
    LiuyaoSeasonState.supporting => '相',
    LiuyaoSeasonState.resting => '休',
    LiuyaoSeasonState.confined => '囚',
    LiuyaoSeasonState.weakened => '死',
  };
}

class LiuyaoLineAnalysis {
  const LiuyaoLineAnalysis({
    required this.position,
    required this.seasonState,
    required this.monthBreak,
    required this.dayBreak,
    required this.dayClash,
    required this.dayCombine,
    required this.releasedFromVoid,
    required this.changedBranch,
    required this.transformation,
    required this.focusRole,
  });

  final int position;
  final LiuyaoSeasonState seasonState;
  final bool monthBreak;
  final bool dayBreak;
  final bool dayClash;
  final bool dayCombine;
  final bool releasedFromVoid;
  final String? changedBranch;
  final String? transformation;
  final String? focusRole;

  List<String> get tags => [
    seasonState.label,
    if (monthBreak) '月破',
    if (dayBreak) '日破',
    if (dayClash) '日冲',
    if (dayCombine) '日合',
    if (releasedFromVoid) '冲空',
    ?transformation,
    ?focusRole,
  ];

  Map<String, dynamic> toJson() => {
    'position': position,
    'seasonState': seasonState.label,
    'monthBreak': monthBreak,
    'dayBreak': dayBreak,
    'dayClash': dayClash,
    'dayCombine': dayCombine,
    'releasedFromVoid': releasedFromVoid,
    if (changedBranch != null) 'changedBranch': changedBranch,
    if (transformation != null) 'transformation': transformation,
    if (focusRole != null) 'focusRole': focusRole,
    'tags': tags,
  };
}

class LiuyaoHiddenSpirit {
  const LiuyaoHiddenSpirit({
    required this.position,
    required this.relation,
    required this.stem,
    required this.branch,
    required this.element,
    required this.flyingRelation,
    required this.flyingBranch,
  });

  final int position;
  final LiuyaoRelation relation;
  final String stem;
  final String branch;
  final String element;
  final LiuyaoRelation flyingRelation;
  final String flyingBranch;

  Map<String, dynamic> toJson() => {
    'position': position,
    'relation': relation.label,
    'stem': stem,
    'branch': branch,
    'element': element,
    'flyingRelation': flyingRelation.label,
    'flyingBranch': flyingBranch,
  };
}

class LiuyaoAdvancedAnalysis {
  const LiuyaoAdvancedAnalysis({
    required this.monthBranch,
    required this.dayBranch,
    required this.lineAnalyses,
    required this.hiddenSpirits,
    required this.combinations,
    required this.clashes,
    required this.threeHarmony,
    required this.focusSummary,
    required this.cautions,
  });

  final String monthBranch;
  final String dayBranch;
  final List<LiuyaoLineAnalysis> lineAnalyses;
  final List<LiuyaoHiddenSpirit> hiddenSpirits;
  final List<String> combinations;
  final List<String> clashes;
  final List<String> threeHarmony;
  final String? focusSummary;
  final List<String> cautions;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'monthBranch': monthBranch,
    'dayBranch': dayBranch,
    'lineAnalyses': lineAnalyses.map((item) => item.toJson()).toList(),
    'hiddenSpirits': hiddenSpirits.map((item) => item.toJson()).toList(),
    'combinations': combinations,
    'clashes': clashes,
    'threeHarmony': threeHarmony,
    if (focusSummary != null) 'focusSummary': focusSummary,
    'cautions': cautions,
  };
}

abstract final class LiuyaoAdvancedAnalyzer {
  static const _elements = {
    '寅': '木',
    '卯': '木',
    '巳': '火',
    '午': '火',
    '辰': '土',
    '戌': '土',
    '丑': '土',
    '未': '土',
    '申': '金',
    '酉': '金',
    '亥': '水',
    '子': '水',
  };
  static const _clash = {
    '子': '午',
    '午': '子',
    '丑': '未',
    '未': '丑',
    '寅': '申',
    '申': '寅',
    '卯': '酉',
    '酉': '卯',
    '辰': '戌',
    '戌': '辰',
    '巳': '亥',
    '亥': '巳',
  };
  static const _combine = {
    '子': '丑',
    '丑': '子',
    '寅': '亥',
    '亥': '寅',
    '卯': '戌',
    '戌': '卯',
    '辰': '酉',
    '酉': '辰',
    '巳': '申',
    '申': '巳',
    '午': '未',
    '未': '午',
  };
  static const _threeHarmonyGroups = [
    ['申', '子', '辰', '水局'],
    ['亥', '卯', '未', '木局'],
    ['寅', '午', '戌', '火局'],
    ['巳', '酉', '丑', '金局'],
  ];
  static const _advancePairs = {
    '亥': '子',
    '寅': '卯',
    '巳': '午',
    '申': '酉',
    '丑': '辰',
    '辰': '未',
    '未': '戌',
  };

  static LiuyaoAdvancedAnalysis build(LiuyaoResult result) {
    final monthBranch = _branchOf(result.calendar.solarTermMonthGanzhi);
    final dayBranch = _branchOf(result.calendar.dayGanzhi);
    final changedBranches = _branchesForHexagram(result.base.changed);
    final focusElement = _focusElement(result);
    final lineAnalyses = <LiuyaoLineAnalysis>[];
    for (var index = 0; index < result.lines.length; index++) {
      final line = result.lines[index];
      final changedBranch = line.yao.isMoving ? changedBranches[index] : null;
      lineAnalyses.add(
        LiuyaoLineAnalysis(
          position: line.position,
          seasonState: _seasonState(line.element, _elements[monthBranch]!),
          monthBreak: _clash[line.branch] == monthBranch,
          dayBreak: line.isVoid && _clash[line.branch] == dayBranch,
          dayClash: _clash[line.branch] == dayBranch,
          dayCombine: _combine[line.branch] == dayBranch,
          releasedFromVoid: line.isVoid && _clash[line.branch] == dayBranch,
          changedBranch: changedBranch,
          transformation: changedBranch == null
              ? null
              : _transformation(line.branch, changedBranch),
          focusRole: focusElement == null
              ? null
              : _focusRole(line.element, focusElement),
        ),
      );
    }
    final branches = result.lines.map((line) => line.branch).toList();
    final combinations = _pairs(branches, _combine, '合');
    final clashes = _pairs(branches, _clash, '冲');
    final available = {...branches, monthBranch, dayBranch};
    final threeHarmony = [
      for (final group in _threeHarmonyGroups)
        if (group.take(3).every(available.contains))
          '${group[0]}${group[1]}${group[2]}三合${group[3]}',
    ];
    return LiuyaoAdvancedAnalysis(
      monthBranch: monthBranch,
      dayBranch: dayBranch,
      lineAnalyses: List.unmodifiable(lineAnalyses),
      hiddenSpirits: List.unmodifiable(_hiddenSpirits(result)),
      combinations: List.unmodifiable(combinations),
      clashes: List.unmodifiable(clashes),
      threeHarmony: List.unmodifiable(threeHarmony),
      focusSummary: result.focusRelation == null
          ? null
          : '以${result.focusRelation!.label}为观察重点；同我者为用神，同五行生用者为原神，克用者为忌神，生忌者为仇神。',
      cautions: const [
        '旺衰标签仅表达月令五行季节关系，仍需结合日辰、动变、空破和具体占问综合判断。',
        '三合只标记盘中结构齐备，不自动断定成局；是否成化需结合月日、发动和受制情况。',
        '应期与吉凶不在本版本自动下结论，避免把传统规则包装成确定预测。',
      ],
    );
  }

  static String _branchOf(String ganzhi) {
    if (ganzhi.length < 2) {
      throw StateError('干支格式无效：$ganzhi');
    }
    return ganzhi.substring(1, 2);
  }

  static LiuyaoSeasonState _seasonState(String line, String month) {
    if (line == month) {
      return LiuyaoSeasonState.prosperous;
    }
    if (_produces(month) == line) {
      return LiuyaoSeasonState.supporting;
    }
    if (_produces(line) == month) {
      return LiuyaoSeasonState.resting;
    }
    if (_controls(line) == month) {
      return LiuyaoSeasonState.confined;
    }
    return LiuyaoSeasonState.weakened;
  }

  static String? _transformation(String original, String changed) {
    if (original == changed) {
      return '伏吟';
    }
    if (_clash[original] == changed) {
      return '反吟';
    }
    if (_advancePairs[original] == changed) {
      return '化进神';
    }
    if (_advancePairs[changed] == original) {
      return '化退神';
    }
    if (_combine[original] == changed) {
      return '化合';
    }
    return null;
  }

  static List<String> _pairs(
    List<String> branches,
    Map<String, String> relation,
    String label,
  ) {
    final values = <String>{};
    for (var first = 0; first < branches.length; first++) {
      for (var second = first + 1; second < branches.length; second++) {
        if (relation[branches[first]] == branches[second]) {
          values.add(
            '${first + 1}爻${branches[first]}与${second + 1}爻${branches[second]}$label',
          );
        }
      }
    }
    return values.toList(growable: false);
  }

  static List<LiuyaoHiddenSpirit> _hiddenSpirits(LiuyaoResult result) {
    final present = result.lines.map((line) => line.relation).toSet();
    final missing = LiuyaoRelation.values.where(
      (item) => !present.contains(item),
    );
    if (missing.isEmpty) {
      return const [];
    }
    final pure = HexagramData.getHexagramsByPalace(result.base.original.palace)
        .first;
    final branches = _branchesForHexagram(pure);
    final hidden = <LiuyaoHiddenSpirit>[];
    for (var index = 0; index < branches.length; index++) {
      final element = _elements[branches[index]]!;
      final relation = _relation(result.palaceElement, element);
      if (!missing.contains(relation)) {
        continue;
      }
      hidden.add(
        LiuyaoHiddenSpirit(
          position: index + 1,
          relation: relation,
          stem: _stemForPosition(pure, index),
          branch: branches[index],
          element: element,
          flyingRelation: result.lines[index].relation,
          flyingBranch: result.lines[index].branch,
        ),
      );
    }
    return hidden;
  }

  static List<String> _branchesForHexagram(Hexagram hexagram) => [
    ..._trigramBranches(hexagram.lower, true),
    ..._trigramBranches(hexagram.upper, false),
  ];

  static List<String> _trigramBranches(String trigram, bool inner) =>
      switch ((trigram, inner)) {
        ('乾', true) || ('震', true) => const ['子', '寅', '辰'],
        ('乾', false) || ('震', false) => const ['午', '申', '戌'],
        ('坤', true) => const ['未', '巳', '卯'],
        ('坤', false) => const ['丑', '亥', '酉'],
        ('巽', true) => const ['丑', '亥', '酉'],
        ('巽', false) => const ['未', '巳', '卯'],
        ('坎', true) => const ['寅', '辰', '午'],
        ('坎', false) => const ['申', '戌', '子'],
        ('离', true) => const ['卯', '丑', '亥'],
        ('离', false) => const ['酉', '未', '巳'],
        ('艮', true) => const ['辰', '午', '申'],
        ('艮', false) => const ['戌', '子', '寅'],
        ('兑', true) => const ['巳', '卯', '丑'],
        ('兑', false) => const ['亥', '酉', '未'],
        _ => throw StateError('无法识别八卦纳支：$trigram'),
      };

  static String _stemForPosition(Hexagram hexagram, int index) {
    final trigram = index < 3 ? hexagram.lower : hexagram.upper;
    final inner = index < 3;
    return switch ((trigram, inner)) {
      ('乾', true) => '甲',
      ('乾', false) => '壬',
      ('坤', true) => '乙',
      ('坤', false) => '癸',
      ('震', _) => '庚',
      ('巽', _) => '辛',
      ('坎', _) => '戊',
      ('离', _) => '己',
      ('艮', _) => '丙',
      ('兑', _) => '丁',
      _ => throw StateError('无法识别八卦纳干：$trigram'),
    };
  }

  static String? _focusElement(LiuyaoResult result) {
    final focus = result.focusRelation;
    if (focus == null) {
      return null;
    }
    for (final line in result.lines) {
      if (line.relation == focus) {
        return line.element;
      }
    }
    for (final hidden in _hiddenSpirits(result)) {
      if (hidden.relation == focus) {
        return hidden.element;
      }
    }
    return null;
  }

  static String _focusRole(String line, String focus) {
    if (line == focus) {
      return '用神';
    }
    if (_produces(line) == focus) {
      return '原神';
    }
    if (_controls(line) == focus) {
      return '忌神';
    }
    if (_produces(line) == _controllerOf(focus)) {
      return '仇神';
    }
    return '闲神';
  }

  static String _controllerOf(String value) =>
      const {'木': '金', '火': '水', '土': '木', '金': '火', '水': '土'}[value]!;

  static LiuyaoRelation _relation(String palace, String line) {
    if (palace == line) {
      return LiuyaoRelation.brothers;
    }
    if (_produces(palace) == line) {
      return LiuyaoRelation.descendants;
    }
    if (_controls(palace) == line) {
      return LiuyaoRelation.wealth;
    }
    if (_controls(line) == palace) {
      return LiuyaoRelation.officer;
    }
    return LiuyaoRelation.parents;
  }

  static String _produces(String value) =>
      const {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'}[value]!;

  static String _controls(String value) =>
      const {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'}[value]!;
}
