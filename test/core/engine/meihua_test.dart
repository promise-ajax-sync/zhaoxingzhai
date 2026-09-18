import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  group('梅花易数最小核心', () {
    test('时间起卦在立春后春节前仍使用农历卯年', () {
      final result = MeihuaDivination.time(dateTime: DateTime(2024, 2, 5, 12));

      expect(result.calculation['lunarYearGanzhi'], '癸卯');
      expect(result.calculation['solarTermYearGanzhi'], '甲辰');
      expect(result.calculation['yearZhi'], '卯');
      expect(result.calculation['yearZhiIndex'], 4);
      expect(result.calculation['month'], 12);
      expect(result.calculation['day'], 26);
      expect(result.calculation['timeZhi'], '午');
      expect(result.calculation['timeZhiIndex'], 7);
      expect(result.upperTrigramIndex, 2);
      expect(result.lowerTrigramIndex, 1);
      expect(result.movingYaoIndex, 1);
      expect(result.original.name, '泽天夬');
      expect(result.changed.name, '泽风大过');
      expect(result.algorithm.id, 'meihua.time');
      expect(result.algorithm.version, 1);
    });

    test('数字123按辰时生成主互变、动爻和体用', () {
      final result = MeihuaDivination.number(
        number: 123,
        hourBranch: '辰',
        generatedAt: DateTime(2025, 1, 1, 8),
      );

      expect(result.original.name, '火地晋');
      expect(result.inter.name, '水山蹇');
      expect(result.changed.name, '火水未济');
      expect(result.movingYaoIndex, 2);
      expect(result.tiGua.name, '离');
      expect(result.yongGua.name, '坤');
      expect(result.tiYongRelation, '体生用');
      expect(result.movingYaoCi, '晋如愁如，贞吉');
      expect(result.algorithm.version, 1);
    });

    test('随机起卦同种子可复现并可用轨迹重放', () {
      final first = MeihuaDivination.random(seed: '梅花-golden-甲');
      final replayed = MeihuaDivination.random(
        replay: first.randomTrace!.samples,
      );

      expect(replayed.original, same(first.original));
      expect(replayed.inter, same(first.inter));
      expect(replayed.changed, same(first.changed));
      expect(replayed.movingYaoIndex, first.movingYaoIndex);
      expect(first.randomTrace!.samples, hasLength(3));
    });

    test('数字起卦拒绝非法数字和时支', () {
      expect(
        () => MeihuaDivination.number(number: 0, hourBranch: '辰'),
        throwsArgumentError,
      );
      expect(
        () => MeihuaDivination.number(number: 1, hourBranch: '不存在'),
        throwsArgumentError,
      );
    });

    test('1至192的数字起卦始终生成完整三卦和爻辞', () {
      for (var number = 1; number <= 192; number++) {
        final result = MeihuaDivination.number(number: number, hourBranch: '辰');
        expect(result.original.name, isNotEmpty, reason: '$number');
        expect(result.inter.name, isNotEmpty, reason: '$number');
        expect(result.changed.name, isNotEmpty, reason: '$number');
        expect(result.movingYaoCi, isNotEmpty, reason: '$number');
      }
    });
  });
}
