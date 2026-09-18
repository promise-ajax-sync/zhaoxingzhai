import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/calendar/divination_calendar_snapshot.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

enum MeihuaMethod { time, number, sound, character, direction, random }

class MeihuaTrigramRole {
  const MeihuaTrigramRole({
    required this.name,
    required this.element,
    required this.nature,
  });

  final String name;
  final String element;
  final String nature;

  Map<String, dynamic> toJson() => {
    'name': name,
    'element': element,
    'nature': nature,
  };
}

class MeihuaResult {
  const MeihuaResult({
    required this.method,
    required this.methodLabel,
    required this.upperTrigramIndex,
    required this.lowerTrigramIndex,
    required this.movingYaoIndex,
    required this.original,
    required this.inter,
    required this.changed,
    required this.tiGua,
    required this.yongGua,
    required this.tiYongRelation,
    required this.movingYaoCi,
    required this.calculation,
    required this.generatedAt,
    required this.algorithm,
    this.randomTrace,
  });

  final MeihuaMethod method;
  final String methodLabel;
  final int upperTrigramIndex;
  final int lowerTrigramIndex;
  final int movingYaoIndex;
  final Hexagram original;
  final Hexagram inter;
  final Hexagram changed;
  final MeihuaTrigramRole tiGua;
  final MeihuaTrigramRole yongGua;
  final String tiYongRelation;
  final String movingYaoCi;
  final Map<String, dynamic> calculation;
  final DateTime generatedAt;
  final AlgorithmDescriptor algorithm;
  final RandomTrace? randomTrace;

  String get movingYaoName =>
      const ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][movingYaoIndex - 1];

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm.toJson(),
    'method': method.name,
    'methodLabel': methodLabel,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'calculation': calculation,
    'original': _hexagramJson(original),
    'inter': _hexagramJson(inter),
    'changed': _hexagramJson(changed),
    'movingYao': {
      'position': movingYaoIndex,
      'name': movingYaoName,
      'text': movingYaoCi,
    },
    'tiGua': tiGua.toJson(),
    'yongGua': yongGua.toJson(),
    'tiYongRelation': tiYongRelation,
    if (randomTrace != null) 'randomTrace': randomTrace!.toJson(),
  };

  static Map<String, dynamic> _hexagramJson(Hexagram value) => {
    'id': value.id,
    'name': value.name,
    'symbol': value.symbol,
    'binary': value.binary,
    'upper': value.upper,
    'lower': value.lower,
    'description': value.description,
  };
}

abstract final class MeihuaDivination {
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

  /// 年月日时起卦。
  ///
  /// 年支取农历年（正月初一换年），月日取农历数字，时支按中国民用时间；
  /// 立春干支年只作为历法证据保存，不参与此处取数。
  static MeihuaResult time({required DateTime dateTime}) {
    final calendar = DivinationCalendarSnapshot.chinaCivil(dateTime);
    final yearIndex = _branches.indexOf(calendar.lunarYearBranch) + 1;
    if (yearIndex == 0) {
      throw StateError('无法识别农历年支：${calendar.lunarYearBranch}');
    }
    final upperTotal = yearIndex + calendar.lunarMonth + calendar.lunarDay;
    final fullTotal = upperTotal + calendar.hourBranchIndex;
    return _build(
      method: MeihuaMethod.time,
      methodLabel: '年月日时起卦法',
      upperIndex: _positiveModulo(upperTotal, 8),
      lowerIndex: _positiveModulo(fullTotal, 8),
      movingIndex: _positiveModulo(fullTotal, 6),
      generatedAt: calendar.instant,
      algorithm: AlgorithmCatalog.meihuaTime,
      calculation: {
        ...calendar.toJson(),
        'yearZhi': calendar.lunarYearBranch,
        'yearZhiIndex': yearIndex,
        'month': calendar.lunarMonth,
        'day': calendar.lunarDay,
        'timeZhi': calendar.hourBranch,
        'timeZhiIndex': calendar.hourBranchIndex,
        'upperTotal': upperTotal,
        'totalWithTime': fullTotal,
      },
    );
  }

  /// 数字起卦：上卦=数字%8，下卦=(数字+时支序)%8，动爻同总数%6。
  static MeihuaResult number({
    required int number,
    required String hourBranch,
    DateTime? generatedAt,
  }) {
    if (number <= 0 || number > 9007199254740991) {
      throw ArgumentError.value(number, 'number', '数字起卦必须是安全范围内的正整数');
    }
    final hourIndex = _branches.indexOf(hourBranch) + 1;
    if (hourIndex == 0) {
      throw ArgumentError.value(hourBranch, 'hourBranch', '无法识别起卦时辰');
    }
    final total = number + hourIndex;
    if (total > 9007199254740991) {
      throw ArgumentError.value(number, 'number', '数字与时辰序数之和超出安全整数范围');
    }
    return _build(
      method: MeihuaMethod.number,
      methodLabel: '数字起卦法',
      upperIndex: _positiveModulo(number, 8),
      lowerIndex: _positiveModulo(total, 8),
      movingIndex: _positiveModulo(total, 6),
      generatedAt: generatedAt ?? DateTime.now(),
      algorithm: AlgorithmCatalog.meihua,
      calculation: {
        'number': number,
        'timeZhi': hourBranch,
        'timeZhiIndex': hourIndex,
        'totalWithTime': total,
      },
    );
  }

  static MeihuaResult sound({
    required int soundCount,
    required String hourBranch,
    DateTime? generatedAt,
  }) {
    _ensureSafePositive(soundCount, 'soundCount');
    final hourIndex = _branchIndex(hourBranch);
    final total = soundCount + hourIndex;
    _ensureSafe(total, 'soundCount');
    return _build(
      method: MeihuaMethod.sound,
      methodLabel: '声音起卦法',
      upperIndex: _positiveModulo(soundCount, 8),
      lowerIndex: _positiveModulo(total, 8),
      movingIndex: _positiveModulo(total, 6),
      generatedAt: generatedAt ?? DateTime.now(),
      algorithm: AlgorithmCatalog.meihuaSound,
      calculation: {
        'soundCount': soundCount,
        'timeZhi': hourBranch,
        'timeZhiIndex': hourIndex,
        'total': total,
      },
    );
  }

  static MeihuaResult character({
    required String text,
    List<int>? strokeCounts,
    List<int>? traditionalTones,
    DateTime? generatedAt,
  }) {
    final count = text.runes.length;
    if (count < 1 || count > 100) {
      throw ArgumentError.value(count, 'text', '字数必须为1到100');
    }
    int upperNumber, lowerNumber;
    if (count == 1) {
      if (traditionalTones != null) {
        throw ArgumentError('单字起卦不接受声调数值');
      }
      if (strokeCounts == null || strokeCounts.length != 2) {
        throw ArgumentError('单字请提供左右部首笔画数');
      }
      upperNumber = strokeCounts[0];
      lowerNumber = strokeCounts[1];
    } else if (count <= 3) {
      if (traditionalTones != null) {
        throw ArgumentError('二至三字只使用逐字笔画数');
      }
      if (strokeCounts == null || strokeCounts.length != count) {
        throw ArgumentError('二至三字请提供每字笔画数');
      }
      final split = count ~/ 2;
      upperNumber = strokeCounts.take(split).fold(0, (a, b) => a + b);
      lowerNumber = strokeCounts.skip(split).fold(0, (a, b) => a + b);
    } else if (count <= 10) {
      if (strokeCounts != null) {
        throw ArgumentError('四至十字只使用传统平上去入数值');
      }
      if (traditionalTones == null ||
          traditionalTones.length != count ||
          traditionalTones.any((v) => v < 1 || v > 4)) {
        throw ArgumentError('四至十字请提供1至4的平上去入数值');
      }
      final split = count ~/ 2;
      upperNumber = traditionalTones.take(split).fold(0, (a, b) => a + b);
      lowerNumber = traditionalTones.skip(split).fold(0, (a, b) => a + b);
    } else {
      if (strokeCounts != null || traditionalTones != null) {
        throw ArgumentError('十一字以上只按字数起卦');
      }
      upperNumber = count ~/ 2;
      lowerNumber = count - upperNumber;
    }
    final suppliedValues = strokeCounts ?? traditionalTones;
    if (suppliedValues != null &&
        suppliedValues.any((value) => value <= 0 || value > 9007199254740991)) {
      throw ArgumentError('取数必须为安全范围内的正整数');
    }
    if (upperNumber <= 0 || lowerNumber <= 0) {
      throw ArgumentError('分组数值必须为正数');
    }
    final total = upperNumber + lowerNumber;
    _ensureSafe(total, 'values');
    return _build(
      method: MeihuaMethod.character,
      methodLabel: '文字起卦法',
      upperIndex: _positiveModulo(upperNumber, 8),
      lowerIndex: _positiveModulo(lowerNumber, 8),
      movingIndex: _positiveModulo(total, 6),
      generatedAt: generatedAt ?? DateTime.now(),
      algorithm: AlgorithmCatalog.meihuaCharacter,
      calculation: {
        'text': text,
        'characterCount': count,
        'upperNumber': upperNumber,
        'lowerNumber': lowerNumber,
        'total': total,
      },
    );
  }

  static MeihuaResult direction({
    required String direction,
    required String objectType,
    required String hourBranch,
    DateTime? generatedAt,
  }) {
    const directions = {
      'northwest': 1,
      'west': 2,
      'south': 3,
      'east': 4,
      'southeast': 5,
      'north': 6,
      'northeast': 7,
      'southwest': 8,
    };
    const objects = {
      'heaven': 1,
      'lake': 2,
      'fire': 3,
      'thunder': 4,
      'wind': 5,
      'water': 6,
      'mountain': 7,
      'earth': 8,
    };
    final lower = directions[direction], upper = objects[objectType];
    if (lower == null) {
      throw ArgumentError.value(direction, 'direction');
    }
    if (upper == null) {
      throw ArgumentError.value(objectType, 'objectType');
    }
    final hourIndex = _branchIndex(hourBranch);
    final total = upper + lower + hourIndex;
    return _build(
      method: MeihuaMethod.direction,
      methodLabel: '方位起卦法',
      upperIndex: upper,
      lowerIndex: lower,
      movingIndex: _positiveModulo(total, 6),
      generatedAt: generatedAt ?? DateTime.now(),
      algorithm: AlgorithmCatalog.meihuaDirection,
      calculation: {
        'direction': direction,
        'objectType': objectType,
        'timeZhi': hourBranch,
        'timeZhiIndex': hourIndex,
        'total': total,
      },
    );
  }

  static int _branchIndex(String value) {
    final index = _branches.indexOf(value) + 1;
    if (index == 0) {
      throw ArgumentError.value(value, 'hourBranch', '无效时辰');
    }
    return index;
  }

  static void _ensureSafePositive(int value, String name) {
    if (value <= 0 || value > 9007199254740991) {
      throw ArgumentError.value(value, name);
    }
  }

  static void _ensureSafe(int value, String name) {
    if (value > 9007199254740991) {
      throw ArgumentError.value(value, name);
    }
  }

  static MeihuaResult random({
    Object? seed,
    List<double>? replay,
    DateTime? generatedAt,
  }) {
    final context = createRandomContext(seed: seed, replay: replay);
    final upper = randomInt(8, context.random) + 1;
    final lower = randomInt(8, context.random) + 1;
    final moving = randomInt(6, context.random) + 1;
    return _build(
      method: MeihuaMethod.random,
      methodLabel: '随机起卦法',
      upperIndex: upper,
      lowerIndex: lower,
      movingIndex: moving,
      generatedAt: generatedAt ?? DateTime.now(),
      algorithm: AlgorithmCatalog.meihua,
      calculation: const {},
      randomTrace: context.getTrace(),
    );
  }

  static MeihuaResult _build({
    required MeihuaMethod method,
    required String methodLabel,
    required int upperIndex,
    required int lowerIndex,
    required int movingIndex,
    required DateTime generatedAt,
    required AlgorithmDescriptor algorithm,
    required Map<String, dynamic> calculation,
    RandomTrace? randomTrace,
  }) {
    final upper = _trigram(upperIndex);
    final lower = _trigram(lowerIndex);
    final mainLines = [...lower.lines, ...upper.lines];
    final original = _hexagramFromLines(mainLines);
    final inter = _hexagramFromLines([
      mainLines[1],
      mainLines[2],
      mainLines[3],
      mainLines[2],
      mainLines[3],
      mainLines[4],
    ]);
    final changedLines = [...mainLines];
    changedLines[movingIndex - 1] = 1 - changedLines[movingIndex - 1];
    final changed = _hexagramFromLines(changedLines);

    // 动爻所在经卦为用，静止的另一经卦为体。
    final ti = movingIndex > 3 ? lower : upper;
    final yong = movingIndex > 3 ? upper : lower;
    final tiRole = _role(ti);
    final yongRole = _role(yong);

    return MeihuaResult(
      method: method,
      methodLabel: methodLabel,
      upperTrigramIndex: upperIndex,
      lowerTrigramIndex: lowerIndex,
      movingYaoIndex: movingIndex,
      original: original,
      inter: inter,
      changed: changed,
      tiGua: tiRole,
      yongGua: yongRole,
      tiYongRelation: _relation(yong.element, ti.element),
      movingYaoCi: original.yaoCi[movingIndex - 1],
      calculation: {
        ...calculation,
        'upperTrigramIndex': upperIndex,
        'lowerTrigramIndex': lowerIndex,
        'movingYaoIndex': movingIndex,
      },
      generatedAt: generatedAt,
      algorithm: algorithm,
      randomTrace: randomTrace,
    );
  }

  static int _positiveModulo(int value, int modulus) =>
      value % modulus == 0 ? modulus : value % modulus;

  static Trigram _trigram(int index) {
    final trigram = HexagramData.getTrigramByIndex(index);
    if (trigram == null) {
      throw StateError('找不到八卦索引：$index');
    }
    return trigram;
  }

  static MeihuaTrigramRole _role(Trigram trigram) => MeihuaTrigramRole(
    name: trigram.name,
    element: trigram.element,
    nature: trigram.nature,
  );

  static Hexagram _hexagramFromLines(List<int> bottomToTop) {
    if (bottomToTop.length != 6 ||
        bottomToTop.any((line) => line != 0 && line != 1)) {
      throw StateError('梅花易数六爻编码无效');
    }
    final binary =
        '${bottomToTop.sublist(3).join()}${bottomToTop.sublist(0, 3).join()}';
    final result = HexagramData.getHexagramByBinary(binary);
    if (result == null) {
      throw StateError('找不到梅花卦象：$binary');
    }
    return result;
  }

  static String _relation(String yong, String ti) {
    if (yong == ti) {
      return '比和';
    }
    if (_sheng(yong, ti)) {
      return '用生体';
    }
    if (_sheng(ti, yong)) {
      return '体生用';
    }
    if (_ke(yong, ti)) {
      return '用克体';
    }
    if (_ke(ti, yong)) {
      return '体克用';
    }
    throw StateError('无法判断体用五行关系：用$yong、体$ti');
  }

  static bool _sheng(String source, String target) =>
      const {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'}[source] ==
      target;

  static bool _ke(String source, String target) =>
      const {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'}[source] ==
      target;
}
