import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

enum DailyHexagramYaoType {
  oldYin(6, '老阴', true, false),
  youngYang(7, '少阳', false, true),
  youngYin(8, '少阴', false, false),
  oldYang(9, '老阳', true, true);

  const DailyHexagramYaoType(
    this.value,
    this.label,
    this.isMoving,
    this.isYang,
  );

  final int value;
  final String label;
  final bool isMoving;
  final bool isYang;

  bool get changedIsYang => isMoving ? !isYang : isYang;

  static DailyHexagramYaoType fromValue(int value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', '爻值只能是 6、7、8、9'),
  );
}

class DailyHexagramCoinThrow {
  const DailyHexagramCoinThrow({required this.coins, required this.total});

  final List<int> coins;
  final int total;

  DailyHexagramYaoType get yao => DailyHexagramYaoType.fromValue(total);

  Map<String, dynamic> toJson() => {'coins': coins, 'total': total};
}

class DailyHexagramMovingLine {
  const DailyHexagramMovingLine({
    required this.position,
    required this.type,
    required this.text,
  });

  final int position;
  final DailyHexagramYaoType type;
  final String text;

  String get name => const ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][position - 1];

  Map<String, dynamic> toJson() => {
    'position': position,
    'name': name,
    'type': type.label,
    'text': text,
  };
}

class DailyHexagramTakingRule {
  const DailyHexagramTakingRule({
    required this.movingCount,
    required this.summary,
    required this.primaryTexts,
    this.secondaryTexts = const [],
  });

  final int movingCount;
  final String summary;
  final List<String> primaryTexts;
  final List<String> secondaryTexts;

  Map<String, dynamic> toJson() => {
    'movingCount': movingCount,
    'summary': summary,
    'primaryTexts': primaryTexts,
    'secondaryTexts': secondaryTexts,
  };
}

class DailyHexagramResult {
  const DailyHexagramResult({
    required this.dateKey,
    required this.original,
    required this.changed,
    required this.inter,
    required this.yaos,
    required this.coinThrows,
    required this.movingLines,
    required this.takingRule,
    required this.caseKey,
    required this.generatedAt,
    required this.algorithm,
    required this.randomTrace,
    required this.isManual,
  });

  final String dateKey;
  final Hexagram original;
  final Hexagram changed;
  final Hexagram inter;
  final List<DailyHexagramYaoType> yaos;
  final List<DailyHexagramCoinThrow> coinThrows;
  final List<DailyHexagramMovingLine> movingLines;
  final DailyHexagramTakingRule takingRule;
  final String? caseKey;
  final DateTime generatedAt;
  final AlgorithmDescriptor algorithm;
  final RandomTrace randomTrace;
  final bool isManual;

  /// 兼容基础版调用；正式算法中的主卦即原来的单卦结果。
  Hexagram get hexagram => original;

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm.toJson(),
    'dateKey': dateKey,
    if (caseKey != null) 'caseKey': caseKey,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'method': isManual ? 'manual-coins' : 'seeded-coins',
    'yaos': yaos.map((item) => item.value).toList(),
    'coinThrows': coinThrows.map((item) => item.toJson()).toList(),
    'original': _hexagramJson(original),
    'changed': _hexagramJson(changed),
    'inter': _hexagramJson(inter),
    'movingLines': movingLines.map((item) => item.toJson()).toList(),
    'takingRule': takingRule.toJson(),
    'randomTrace': randomTrace.toJson(),
  };

  static Map<String, dynamic> _hexagramJson(Hexagram hexagram) => {
    'id': hexagram.id,
    'name': hexagram.name,
    'symbol': hexagram.symbol,
    'binary': hexagram.binary,
    'upper': hexagram.upper,
    'lower': hexagram.lower,
    'palace': hexagram.palace,
    'description': hexagram.description,
    'yaoCi': hexagram.yaoCi,
    if (hexagram.yongCi != null) 'yongCi': hexagram.yongCi,
  };
}

abstract final class DailyHexagramEngine {
  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 同一天、同一案例使用固定种子模拟三枚铜钱六次投掷。
  static DailyHexagramResult generate({DateTime? date, String? caseKey}) {
    final now = date ?? DateTime.now();
    final day = dateKey(now);
    final normalizedCase = _normalizeCase(caseKey);
    final seed = normalizedCase == null
        ? 'daily-hexagram:$day'
        : 'daily-hexagram:$day:$normalizedCase';
    final context = createRandomContext(seed: seed);
    final throws = List.generate(6, (_) {
      final coins = List.generate(
        3,
        (_) => randomInt(2, context.random) == 0 ? 2 : 3,
        growable: false,
      );
      return DailyHexagramCoinThrow(
        coins: coins,
        total: coins.reduce((sum, coin) => sum + coin),
      );
    }, growable: false);

    return _build(
      coinThrows: throws,
      now: now,
      caseKey: normalizedCase,
      randomTrace: context.getTrace(),
      isManual: false,
    );
  }

  /// 根据用户从初爻到上爻录入的 6、7、8、9 构造卦象。
  static DailyHexagramResult fromYaoValues(
    List<int> values, {
    DateTime? date,
    String? caseKey,
  }) {
    if (values.length != 6) {
      throw ArgumentError.value(values, 'values', '必须从初爻到上爻录入六个爻值');
    }
    final throws = values.map(_canonicalThrow).toList(growable: false);
    final now = date ?? DateTime.now();
    return _build(
      coinThrows: throws,
      now: now,
      caseKey: _normalizeCase(caseKey),
      randomTrace: const RandomTrace(
        mode: RandomMode.custom,
        seed: 'manual-coins',
        samples: [],
      ),
      isManual: true,
    );
  }

  static DailyHexagramCoinThrow _canonicalThrow(int value) {
    DailyHexagramYaoType.fromValue(value);
    final coins = switch (value) {
      6 => const [2, 2, 2],
      7 => const [3, 2, 2],
      8 => const [3, 3, 2],
      9 => const [3, 3, 3],
      _ => throw StateError('unreachable'),
    };
    return DailyHexagramCoinThrow(coins: coins, total: value);
  }

  static DailyHexagramResult _build({
    required List<DailyHexagramCoinThrow> coinThrows,
    required DateTime now,
    required String? caseKey,
    required RandomTrace randomTrace,
    required bool isManual,
  }) {
    if (coinThrows.length != 6) {
      throw ArgumentError.value(coinThrows, 'coinThrows', '必须包含六次投掷');
    }
    final yaos = coinThrows
        .map((item) {
          if (item.coins.length != 3 ||
              item.coins.any((coin) => coin != 2 && coin != 3) ||
              item.coins.reduce((sum, coin) => sum + coin) != item.total) {
            throw ArgumentError.value(item.coins, 'coinThrows', '铜钱记录无效');
          }
          return item.yao;
        })
        .toList(growable: false);

    final originalLines = yaos.map((item) => item.isYang).toList();
    final original = _findByLines(originalLines);
    final changed = _findByLines(
      yaos.map((item) => item.changedIsYang).toList(),
    );
    final inter = _findByLines([
      originalLines[1],
      originalLines[2],
      originalLines[3],
      originalLines[2],
      originalLines[3],
      originalLines[4],
    ]);
    final movingLines = <DailyHexagramMovingLine>[
      for (var index = 0; index < yaos.length; index++)
        if (yaos[index].isMoving)
          DailyHexagramMovingLine(
            position: index + 1,
            type: yaos[index],
            text: original.yaoCi[index],
          ),
    ];
    final takingRule = _buildTakingRule(
      original: original,
      changed: changed,
      movingLines: movingLines,
    );

    return DailyHexagramResult(
      dateKey: dateKey(now),
      original: original,
      changed: changed,
      inter: inter,
      yaos: yaos,
      coinThrows: coinThrows,
      movingLines: movingLines,
      takingRule: takingRule,
      caseKey: caseKey,
      generatedAt: now,
      algorithm: AlgorithmCatalog.dailyHexagram,
      randomTrace: randomTrace,
      isManual: isManual,
    );
  }

  static Hexagram _findByLines(List<bool> lines) {
    if (lines.length != 6) throw StateError('六爻数量必须为 6');
    String bits(Iterable<bool> values) =>
        values.map((isYang) => isYang ? '1' : '0').join();
    final binary = '${bits(lines.skip(3))}${bits(lines.take(3))}';
    final result = HexagramData.getHexagramByBinary(binary);
    if (result == null) throw StateError('找不到二进制卦象：$binary');
    return result;
  }

  static DailyHexagramTakingRule _buildTakingRule({
    required Hexagram original,
    required Hexagram changed,
    required List<DailyHexagramMovingLine> movingLines,
  }) {
    final movingPositions = movingLines.map((item) => item.position).toSet();
    final unchangedPositions = [
      for (var position = 1; position <= 6; position++)
        if (!movingPositions.contains(position)) position,
    ];
    String lineText(int position) =>
        '${_lineName(position)}：${original.yaoCi[position - 1]}';

    return switch (movingLines.length) {
      0 => DailyHexagramTakingRule(
        movingCount: 0,
        summary: '六爻皆静，以本卦卦辞定主调。',
        primaryTexts: [original.description],
      ),
      1 => DailyHexagramTakingRule(
        movingCount: 1,
        summary: '${movingLines.first.name}独动，以该爻爻辞为主。',
        primaryTexts: [lineText(movingLines.first.position)],
      ),
      2 => DailyHexagramTakingRule(
        movingCount: 2,
        summary: '两爻同动，以上方动爻为主、下方动爻为辅。',
        primaryTexts: [lineText(movingLines.last.position)],
        secondaryTexts: [lineText(movingLines.first.position)],
      ),
      3 => DailyHexagramTakingRule(
        movingCount: 3,
        summary: '三爻发动，兼看本卦与变卦卦辞，本卦主当前，变卦主后势。',
        primaryTexts: [
          '本卦${original.name}：${original.description}',
          '变卦${changed.name}：${changed.description}',
        ],
      ),
      4 => DailyHexagramTakingRule(
        movingCount: 4,
        summary: '四爻发动，取两个静爻，以下方静爻为主、上方静爻为辅。',
        primaryTexts: [lineText(unchangedPositions.first)],
        secondaryTexts: [lineText(unchangedPositions.last)],
      ),
      5 => DailyHexagramTakingRule(
        movingCount: 5,
        summary: '五爻发动，取唯一静爻的爻辞。',
        primaryTexts: [lineText(unchangedPositions.single)],
      ),
      6 when original.yongCi != null => DailyHexagramTakingRule(
        movingCount: 6,
        summary: '六爻皆动，乾坤卦取用九或用六。',
        primaryTexts: [original.yongCi!],
      ),
      6 => DailyHexagramTakingRule(
        movingCount: 6,
        summary: '六爻皆动且无专用用辞，以变卦卦辞判断后势。',
        primaryTexts: ['变卦${changed.name}：${changed.description}'],
      ),
      _ => throw StateError('动爻数量超出范围'),
    };
  }

  static String _lineName(int position) =>
      const ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'][position - 1];

  static String? _normalizeCase(String? caseKey) {
    final value = caseKey?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
