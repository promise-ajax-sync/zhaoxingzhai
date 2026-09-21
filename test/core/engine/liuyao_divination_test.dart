import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/liuyao/liuyao_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  group('六爻纳甲排盘', () {
    test('乾为天按京房纳甲排出六亲、世应和六神', () {
      final result = LiuyaoEngine.fromYaoValues(
        List.filled(6, 7),
        dateTime: DateTime(2026, 9, 21, 12),
        question: '测试',
      );

      expect(result.base.original.name, '乾为天');
      expect(result.palaceElement, '金');
      expect(result.palaceStage, '本宫');
      expect(result.shiPosition, 6);
      expect(result.yingPosition, 3);
      expect(result.lines.map((line) => line.ganZhi), [
        '甲子',
        '甲寅',
        '甲辰',
        '壬午',
        '壬申',
        '壬戌',
      ]);
      expect(result.lines.map((line) => line.relation.label), [
        '子孙',
        '妻财',
        '父母',
        '官鬼',
        '兄弟',
        '父母',
      ]);
      expect(result.lines.where((line) => line.isShi).single.position, 6);
      expect(result.lines.where((line) => line.isYing).single.position, 3);
      expect(result.lines.map((line) => line.spirit).toSet(), hasLength(6));
    });

    test('八宫六十四卦均能确定唯一世应和纳甲', () {
      for (final hexagram in HexagramData.hexagrams) {
        final lines =
            '${hexagram.binary.substring(3)}${hexagram.binary.substring(0, 3)}'
                .split('')
                .map((bit) => bit == '1' ? 7 : 8)
                .toList(growable: false);
        final result = LiuyaoEngine.fromYaoValues(
          lines,
          dateTime: DateTime(2026, 9, 21, 12),
        );
        expect(result.base.original.id, hexagram.id);
        expect(result.lines, hasLength(6));
        expect(result.lines.where((line) => line.isShi), hasLength(1));
        expect(result.lines.where((line) => line.isYing), hasLength(1));
      }
    });

    test('动爻同时生成变卦、互卦、错卦和综卦并保存旬空', () {
      final result = LiuyaoEngine.fromYaoValues([
        6,
        7,
        7,
        7,
        7,
        9,
      ], dateTime: DateTime(2026, 9, 21, 9, 30));

      expect(result.base.original.name, '天风姤');
      expect(result.base.changed.name, '泽天夬');
      expect(result.base.inter.name, '乾为天');
      expect(result.opposite.id, isNot(result.base.original.id));
      expect(result.reversed, isNotNull);
      expect(result.voidBranches, hasLength(2));
      expect(result.algorithm.id, 'liuyao');
      expect(result.algorithm.version, 1);
      expect(result.toJson()['lines'], hasLength(6));
    });
  });
}
