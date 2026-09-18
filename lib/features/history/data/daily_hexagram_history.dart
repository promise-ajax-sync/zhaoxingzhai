import 'package:zhaoxingzhai/core/interpretation/daily_hexagram_interpretation.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

class HistoricalHexagramSnapshot {
  const HistoricalHexagramSnapshot({
    required this.name,
    required this.symbol,
    required this.description,
    required this.upper,
    required this.lower,
  });

  final String name;
  final String symbol;
  final String description;
  final String upper;
  final String lower;

  static HistoricalHexagramSnapshot? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = map['name'];
    if (name is! String || name.isEmpty) return null;
    return HistoricalHexagramSnapshot(
      name: name,
      symbol: map['symbol'] is String ? map['symbol'] as String : '',
      description: map['description'] is String
          ? map['description'] as String
          : '',
      upper: map['upper'] is String ? map['upper'] as String : '',
      lower: map['lower'] is String ? map['lower'] as String : '',
    );
  }
}

class HistoricalMovingLine {
  const HistoricalMovingLine({
    required this.position,
    required this.name,
    required this.type,
    required this.text,
  });

  final int position;
  final String name;
  final String type;
  final String text;

  static HistoricalMovingLine? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final position = (map['position'] as num?)?.toInt();
    if (position == null || position < 1 || position > 6) return null;
    return HistoricalMovingLine(
      position: position,
      name: map['name'] is String ? map['name'] as String : '第$position爻',
      type: map['type'] is String ? map['type'] as String : '动爻',
      text: map['text'] is String ? map['text'] as String : '',
    );
  }
}

class DailyHexagramHistoryDetails {
  const DailyHexagramHistoryDetails({
    required this.algorithmVersion,
    required this.dateKey,
    required this.original,
    required this.changed,
    required this.inter,
    required this.yaos,
    required this.coinThrows,
    required this.movingLines,
    required this.takingSummary,
    required this.primaryTexts,
    required this.secondaryTexts,
    required this.interpretation,
    required this.compatibilityNotice,
  });

  final int algorithmVersion;
  final String dateKey;
  final HistoricalHexagramSnapshot original;
  final HistoricalHexagramSnapshot? changed;
  final HistoricalHexagramSnapshot? inter;
  final List<int> yaos;
  final List<List<int>> coinThrows;
  final List<HistoricalMovingLine> movingLines;
  final String? takingSummary;
  final List<String> primaryTexts;
  final List<String> secondaryTexts;
  final DailyHexagramInterpretation? interpretation;
  final String compatibilityNotice;

  bool get isLegacy => algorithmVersion < 3;

  static DailyHexagramHistoryDetails? tryParse(DivinationHistoryRecord record) {
    if (record.type != 'daily-hexagram') return null;
    final payload = record.payload;
    // v1 使用 hexagram；v2/v3 使用 original。
    final original = HistoricalHexagramSnapshot.tryParse(
      payload['original'] ?? payload['hexagram'],
    );
    if (original == null) return null;

    final yaos = payload['yaos'] is List
        ? (payload['yaos'] as List)
              .whereType<num>()
              .map((item) => item.toInt())
              .where((item) => item >= 6 && item <= 9)
              .toList(growable: false)
        : const <int>[];
    final movingLines = payload['movingLines'] is List
        ? (payload['movingLines'] as List)
              .map(HistoricalMovingLine.tryParse)
              .whereType<HistoricalMovingLine>()
              .toList(growable: false)
        : const <HistoricalMovingLine>[];
    final coinThrows = payload['coinThrows'] is List
        ? (payload['coinThrows'] as List)
              .whereType<Map>()
              .map((raw) => Map<String, dynamic>.from(raw))
              .map((item) => item['coins'])
              .whereType<List>()
              .map(
                (coins) => coins
                    .whereType<num>()
                    .map((coin) => coin.toInt())
                    .toList(growable: false),
              )
              .where(
                (coins) =>
                    coins.length == 3 &&
                    coins.every((coin) => coin == 2 || coin == 3),
              )
              .toList(growable: false)
        : const <List<int>>[];
    final takingRule = payload['takingRule'] is Map
        ? Map<String, dynamic>.from(payload['takingRule'] as Map)
        : const <String, dynamic>{};

    List<String> texts(String key) => takingRule[key] is List
        ? (takingRule[key] as List).whereType<String>().toList(growable: false)
        : const <String>[];

    final version = record.algorithmVersion;
    final notice = switch (version) {
      >= 3 => '按保存时的 v$version 结果原样展示。',
      2 => '这是 v2 历史：保留本卦、变卦、互卦和动爻；当时尚未保存结构化取用规则，不使用 v3 规则重新解释。',
      _ => '这是早期单卦历史：当时未保存六爻、变卦和互卦，仅展示原始单卦数据。',
    };

    return DailyHexagramHistoryDetails(
      algorithmVersion: version,
      dateKey: payload['dateKey'] is String ? payload['dateKey'] as String : '',
      original: original,
      changed: HistoricalHexagramSnapshot.tryParse(payload['changed']),
      inter: HistoricalHexagramSnapshot.tryParse(payload['inter']),
      yaos: yaos,
      coinThrows: coinThrows,
      movingLines: movingLines,
      takingSummary: takingRule['summary'] is String
          ? takingRule['summary'] as String
          : null,
      primaryTexts: texts('primaryTexts'),
      secondaryTexts: texts('secondaryTexts'),
      interpretation: DailyHexagramInterpretation.tryParse(
        payload['interpretation'],
      ),
      compatibilityNotice: notice,
    );
  }
}
