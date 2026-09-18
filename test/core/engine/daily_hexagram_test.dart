import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  group('每日一卦三钱六爻算法', () {
    test('同一天同一案例应得到完全相同的六次投掷', () {
      final first = DailyHexagramEngine.generate(
        date: DateTime(2026, 9, 17, 8, 30),
        caseKey: 'case-a',
      );
      final second = DailyHexagramEngine.generate(
        date: DateTime(2026, 9, 17, 23, 59),
        caseKey: 'case-a',
      );

      expect(
        second.yaos.map((item) => item.value),
        first.yaos.map((item) => item.value),
      );
      expect(second.original, same(first.original));
      expect(second.changed, same(first.changed));
      expect(second.inter, same(first.inter));
      expect(first.algorithm.id, 'daily-hexagram');
      expect(first.algorithm.version, 3);
      expect(first.randomTrace.algorithmId, randomAlgorithmId);
      expect(first.randomTrace.algorithmVersion, randomAlgorithmVersion);
      expect(first.randomTrace.samples, hasLength(18));
      expect(first.coinThrows, hasLength(6));
    });

    test('跨本地日期后使用新的每日种子', () {
      final first = DailyHexagramEngine.generate(
        date: DateTime(2026, 9, 17, 23, 59),
      );
      final next = DailyHexagramEngine.generate(date: DateTime(2026, 9, 18));

      expect(first.dateKey, '2026-09-17');
      expect(next.dateKey, '2026-09-18');
      expect(first.randomTrace.seed, 'daily-hexagram:2026-09-17');
      expect(next.randomTrace.seed, 'daily-hexagram:2026-09-18');
    });

    test('老阴老阳正确生成本卦、变卦、互卦和动爻辞', () {
      final result = DailyHexagramEngine.fromYaoValues([
        6,
        7,
        7,
        7,
        7,
        9,
      ], date: DateTime(2026, 9, 17));

      expect(result.original.name, '天风姤');
      expect(result.changed.name, '泽天夬');
      expect(result.inter.name, '乾为天');
      expect(result.movingLines.map((item) => item.position), [1, 6]);
      expect(result.movingLines.first.type, DailyHexagramYaoType.oldYin);
      expect(result.movingLines.first.text, result.original.yaoCi.first);
      expect(result.movingLines.last.type, DailyHexagramYaoType.oldYang);
      expect(result.isManual, isTrue);
    });

    test('全静乾卦保持不变且无动爻', () {
      final result = DailyHexagramEngine.fromYaoValues(List.filled(6, 7));

      expect(result.original.name, '乾为天');
      expect(result.changed.name, '乾为天');
      expect(result.inter.name, '乾为天');
      expect(result.movingLines, isEmpty);
    });

    test('全动乾卦变坤并保留用九', () {
      final result = DailyHexagramEngine.fromYaoValues(List.filled(6, 9));

      expect(result.original.name, '乾为天');
      expect(result.changed.name, '坤为地');
      expect(result.movingLines, hasLength(6));
      expect(result.original.yongCi, '见群龙无首，吉');
      expect(result.toJson()['movingLines'], hasLength(6));
    });

    test('非乾坤六爻全动时以变卦卦辞为主', () {
      final result = DailyHexagramEngine.fromYaoValues([6, 9, 6, 9, 6, 9]);

      expect(result.original.name, '火水未济');
      expect(result.changed.name, '水火既济');
      expect(result.original.yongCi, isNull);
      expect(result.takingRule.primaryTexts.single, contains('变卦水火既济'));
    });

    test('穷举六十四卦的静爻编码均可往返', () {
      for (final hexagram in HexagramData.hexagrams) {
        final bottomToTopBits =
            '${hexagram.binary.substring(3)}'
            '${hexagram.binary.substring(0, 3)}';
        final values = bottomToTopBits
            .split('')
            .map((bit) => bit == '1' ? 7 : 8)
            .toList();
        final result = DailyHexagramEngine.fromYaoValues(values);

        expect(result.original, same(hexagram), reason: hexagram.name);
        expect(result.changed, same(hexagram), reason: hexagram.name);
      }
    });

    test('手工录入必须恰好包含六个合法爻值', () {
      expect(
        () => DailyHexagramEngine.fromYaoValues([7, 7]),
        throwsArgumentError,
      );
      expect(
        () => DailyHexagramEngine.fromYaoValues([7, 7, 7, 7, 7, 5]),
        throwsArgumentError,
      );
    });

    test('逐枚铜钱记录应原样保存并正确计算六爻', () {
      final throws = [
        const DailyHexagramCoinThrow(coins: [2, 2, 2], total: 6),
        const DailyHexagramCoinThrow(coins: [3, 2, 2], total: 7),
        const DailyHexagramCoinThrow(coins: [3, 3, 2], total: 8),
        const DailyHexagramCoinThrow(coins: [3, 3, 3], total: 9),
        const DailyHexagramCoinThrow(coins: [2, 3, 2], total: 7),
        const DailyHexagramCoinThrow(coins: [2, 3, 3], total: 8),
      ];
      final result = DailyHexagramEngine.fromCoinThrows(throws);

      expect(result.yaos.map((item) => item.value), [6, 7, 8, 9, 7, 8]);
      expect(result.coinThrows[4].coins, [2, 3, 2]);
      expect(result.toJson()['coinThrows'][4]['coins'], [2, 3, 2]);
    });

    test('逐枚铜钱必须每爻三枚、值为 2 或 3 且合计一致', () {
      List<DailyHexagramCoinThrow> six(DailyHexagramCoinThrow first) => [
        first,
        ...List.generate(
          5,
          (_) => const DailyHexagramCoinThrow(coins: [3, 2, 2], total: 7),
        ),
      ];

      expect(
        () => DailyHexagramEngine.fromCoinThrows(
          six(const DailyHexagramCoinThrow(coins: [2, 2], total: 4)),
        ),
        throwsArgumentError,
      );
      expect(
        () => DailyHexagramEngine.fromCoinThrows(
          six(const DailyHexagramCoinThrow(coins: [2, 3, 4], total: 9)),
        ),
        throwsArgumentError,
      );
      expect(
        () => DailyHexagramEngine.fromCoinThrows(
          six(const DailyHexagramCoinThrow(coins: [2, 2, 2], total: 7)),
        ),
        throwsArgumentError,
      );
    });
  });
}
