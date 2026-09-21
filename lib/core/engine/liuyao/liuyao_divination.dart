import 'package:zhaoxingzhai/core/calendar/divination_calendar_snapshot.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

enum LiuyaoRelation { brothers, descendants, wealth, officer, parents }

extension LiuyaoRelationLabel on LiuyaoRelation {
  String get label => switch (this) {
    LiuyaoRelation.brothers => '兄弟',
    LiuyaoRelation.descendants => '子孙',
    LiuyaoRelation.wealth => '妻财',
    LiuyaoRelation.officer => '官鬼',
    LiuyaoRelation.parents => '父母',
  };
}

class LiuyaoLine {
  const LiuyaoLine({
    required this.position,
    required this.yao,
    required this.stem,
    required this.branch,
    required this.element,
    required this.relation,
    required this.spirit,
    required this.isShi,
    required this.isYing,
    required this.isVoid,
  });

  final int position;
  final DailyHexagramYaoType yao;
  final String stem;
  final String branch;
  final String element;
  final LiuyaoRelation relation;
  final String spirit;
  final bool isShi;
  final bool isYing;
  final bool isVoid;

  String get ganZhi => '$stem$branch';

  Map<String, dynamic> toJson() => {
    'position': position,
    'value': yao.value,
    'label': yao.label,
    'moving': yao.isMoving,
    'isYang': yao.isYang,
    'stem': stem,
    'branch': branch,
    'element': element,
    'relation': relation.label,
    'spirit': spirit,
    'isShi': isShi,
    'isYing': isYing,
    'isVoid': isVoid,
  };
}

class LiuyaoResult {
  const LiuyaoResult({
    required this.generatedAt,
    required this.question,
    required this.base,
    required this.opposite,
    required this.reversed,
    required this.calendar,
    required this.palaceElement,
    required this.palaceStage,
    required this.shiPosition,
    required this.yingPosition,
    required this.voidBranches,
    required this.lines,
    required this.focusRelation,
    required this.algorithm,
    required this.randomTrace,
  });

  final DateTime generatedAt;
  final String question;
  final DailyHexagramResult base;
  final Hexagram opposite;
  final Hexagram reversed;
  final DivinationCalendarSnapshot calendar;
  final String palaceElement;
  final String palaceStage;
  final int shiPosition;
  final int yingPosition;
  final List<String> voidBranches;
  final List<LiuyaoLine> lines;
  final LiuyaoRelation? focusRelation;
  final AlgorithmDescriptor algorithm;
  final RandomTrace randomTrace;

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm.toJson(),
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    if (question.isNotEmpty) 'question': question,
    'calendar': calendar.toJson(),
    'original': _hexagramJson(base.original),
    'changed': _hexagramJson(base.changed),
    'inter': _hexagramJson(base.inter),
    'opposite': _hexagramJson(opposite),
    'reversed': _hexagramJson(reversed),
    'palaceElement': palaceElement,
    'palaceStage': palaceStage,
    'shiPosition': shiPosition,
    'yingPosition': yingPosition,
    'voidBranches': voidBranches,
    'lines': lines.map((line) => line.toJson()).toList(growable: false),
    if (focusRelation != null) 'focusRelation': focusRelation!.label,
    'coinThrows': base.coinThrows
        .map((item) => item.toJson())
        .toList(growable: false),
    'takingRule': base.takingRule.toJson(),
    'randomTrace': randomTrace.toJson(),
  };

  static Map<String, dynamic> _hexagramJson(Hexagram value) => {
    'id': value.id,
    'name': value.name,
    'symbol': value.symbol,
    'binary': value.binary,
    'upper': value.upper,
    'lower': value.lower,
    'palace': value.palace,
  };
}

abstract final class LiuyaoEngine {
  static const _branches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];
  static const _branchElements = {
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
  static const _palaceElements = {
    '乾': '金',
    '兑': '金',
    '震': '木',
    '巽': '木',
    '坎': '水',
    '离': '火',
    '艮': '土',
    '坤': '土',
  };
  static const _stageNames = ['本宫', '一世', '二世', '三世', '四世', '五世', '游魂', '归魂'];
  static const _shiPositions = [6, 1, 2, 3, 4, 5, 4, 3];
  static const _spirits = ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武'];

  static LiuyaoResult generate({
    DateTime? dateTime,
    String question = '',
    LiuyaoRelation? focusRelation,
  }) {
    final now = dateTime ?? DateTime.now();
    final context = createRandomContext(
      seed: 'liuyao:${now.toUtc().microsecondsSinceEpoch}:$question',
    );
    final values = List<int>.generate(6, (_) {
      var total = 0;
      for (var coin = 0; coin < 3; coin++) {
        total += randomInt(2, context.random) == 0 ? 2 : 3;
      }
      return total;
    }, growable: false);
    return _build(
      values,
      dateTime: now,
      question: question,
      focusRelation: focusRelation,
      randomTrace: context.getTrace(),
    );
  }

  static LiuyaoResult fromYaoValues(
    List<int> values, {
    DateTime? dateTime,
    String question = '',
    LiuyaoRelation? focusRelation,
  }) => _build(
    values,
    dateTime: dateTime ?? DateTime.now(),
    question: question,
    focusRelation: focusRelation,
    randomTrace: const RandomTrace(
      mode: RandomMode.custom,
      seed: 'manual-liuyao',
      samples: [],
    ),
  );

  static LiuyaoResult _build(
    List<int> values, {
    required DateTime dateTime,
    required String question,
    required LiuyaoRelation? focusRelation,
    required RandomTrace randomTrace,
  }) {
    final base = DailyHexagramEngine.fromYaoValues(values, date: dateTime);
    final calendar = DivinationCalendarSnapshot.chinaCivil(dateTime);
    final palaceHexagrams = HexagramData.getHexagramsByPalace(
      base.original.palace,
    );
    final stageIndex = palaceHexagrams.indexWhere(
      (item) => item.id == base.original.id,
    );
    if (stageIndex < 0 || stageIndex >= _shiPositions.length) {
      throw StateError('无法识别${base.original.name}的八宫序位');
    }
    final shiPosition = _shiPositions[stageIndex];
    final yingPosition = shiPosition <= 3 ? shiPosition + 3 : shiPosition - 3;
    final palaceElement = _palaceElements[base.original.palace];
    if (palaceElement == null) {
      throw StateError('无法识别${base.original.palace}宫五行');
    }
    final voidBranches = _voidBranches(calendar.dayGanzhi);
    final spiritOffset = _spiritOffset(calendar.dayGanzhi.substring(0, 1));
    final lines = List<LiuyaoLine>.generate(6, (index) {
      final trigram = index < 3 ? base.original.lower : base.original.upper;
      final inner = index < 3;
      final trigramIndex = index % 3;
      final branch = _najiaBranches(trigram, inner)[trigramIndex];
      final element = _branchElements[branch]!;
      return LiuyaoLine(
        position: index + 1,
        yao: base.yaos[index],
        stem: _najiaStem(trigram, inner),
        branch: branch,
        element: element,
        relation: _relation(palaceElement, element),
        spirit: _spirits[(spiritOffset + index) % _spirits.length],
        isShi: index + 1 == shiPosition,
        isYing: index + 1 == yingPosition,
        isVoid: voidBranches.contains(branch),
      );
    }, growable: false);
    final originalLines = base.yaos.map((yao) => yao.isYang).toList();
    return LiuyaoResult(
      generatedAt: dateTime,
      question: question.trim(),
      base: base,
      opposite: _findByLines(originalLines.map((line) => !line).toList()),
      reversed: _findByLines(originalLines.reversed.toList()),
      calendar: calendar,
      palaceElement: palaceElement,
      palaceStage: _stageNames[stageIndex],
      shiPosition: shiPosition,
      yingPosition: yingPosition,
      voidBranches: List.unmodifiable(voidBranches),
      lines: List.unmodifiable(lines),
      focusRelation: focusRelation,
      algorithm: AlgorithmCatalog.liuyao,
      randomTrace: randomTrace,
    );
  }

  static List<String> _najiaBranches(String trigram, bool inner) =>
      switch ((trigram, inner)) {
        ('乾', true) => const ['子', '寅', '辰'],
        ('乾', false) => const ['午', '申', '戌'],
        ('坤', true) => const ['未', '巳', '卯'],
        ('坤', false) => const ['丑', '亥', '酉'],
        ('震', true) => const ['子', '寅', '辰'],
        ('震', false) => const ['午', '申', '戌'],
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

  static String _najiaStem(String trigram, bool inner) =>
      switch ((trigram, inner)) {
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

  static String _produces(String value) => switch (value) {
    '木' => '火',
    '火' => '土',
    '土' => '金',
    '金' => '水',
    '水' => '木',
    _ => throw StateError('未知五行：$value'),
  };

  static String _controls(String value) => switch (value) {
    '木' => '土',
    '土' => '水',
    '水' => '火',
    '火' => '金',
    '金' => '木',
    _ => throw StateError('未知五行：$value'),
  };

  static int _spiritOffset(String dayStem) => switch (dayStem) {
    '甲' || '乙' => 0,
    '丙' || '丁' => 1,
    '戊' => 2,
    '己' => 3,
    '庚' || '辛' => 4,
    '壬' || '癸' => 5,
    _ => throw StateError('无法识别日干：$dayStem'),
  };

  static List<String> _voidBranches(String dayGanzhi) {
    if (dayGanzhi.length < 2) {
      throw StateError('日干支格式无效：$dayGanzhi');
    }
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
    final stemIndex = stems.indexOf(dayGanzhi.substring(0, 1));
    final branchIndex = _branches.indexOf(dayGanzhi.substring(1, 2));
    if (stemIndex < 0 || branchIndex < 0) {
      throw StateError('日干支格式无效：$dayGanzhi');
    }
    final xunStart = (branchIndex - stemIndex) % 12;
    return [_branches[(xunStart + 10) % 12], _branches[(xunStart + 11) % 12]];
  }

  static Hexagram _findByLines(List<bool> lines) {
    String bits(Iterable<bool> values) =>
        values.map((line) => line ? '1' : '0').join();
    final binary = '${bits(lines.skip(3))}${bits(lines.take(3))}';
    final result = HexagramData.getHexagramByBinary(binary);
    if (result == null) {
      throw StateError('找不到卦象：$binary');
    }
    return result;
  }
}
