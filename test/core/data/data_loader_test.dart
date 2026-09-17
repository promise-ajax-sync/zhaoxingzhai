import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/data/ganzhi_data.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('塔罗牌数据测试', () {
    test('应该能加载塔罗牌数据', () async {
      await TarotData.load();
      expect(TarotData.cards.length, 78);
      expect(TarotData.majorArcana.length, 22);
      expect(TarotData.minorArcana.length, 56);
    });

    test('应该能根据编号获取塔罗牌', () async {
      await TarotData.load();
      final card = TarotData.getCardByNumber(1);
      expect(card?.name, '愚者');
      expect(card?.keywords, ['新开始', '冒险', '纯真']);
    });

    test('全部 78 张牌都应包含由上游同步的有效关键词', () async {
      await TarotData.load();
      expect(TarotData.cards, hasLength(78));
      for (final card in TarotData.cards) {
        expect(card.keywords, isNotEmpty, reason: card.name);
        expect(
          card.keywords.every((keyword) => keyword.trim().isNotEmpty),
          isTrue,
          reason: card.name,
        );
        expect(TarotData.getCardByName(card.name), same(card));
      }
      expect(TarotData.getCardByName('不存在的牌'), isNull);
    });

    test('不存在的塔罗编号应返回 null', () async {
      await TarotData.load();
      expect(TarotData.getCardByNumber(999), isNull);
    });

    test('牌阵应与 mingyu 0.4.0 数据保持一致', () async {
      await TarotData.load();
      expect(TarotData.spreads.length, 18);
      expect(TarotData.spreads['celtic']?.cardCount, 10);
      expect(TarotData.spreads.containsKey('cross'), isFalse);
    });
  });

  group('卦象数据测试', () {
    test('应该能加载八卦数据', () async {
      await HexagramData.load();
      expect(HexagramData.trigrams.length, 8);
    });

    test('应该能加载六十四卦数据', () async {
      await HexagramData.load();
      expect(HexagramData.hexagrams.length, 64);
    });

    test('应该能根据名称获取八卦', () async {
      await HexagramData.load();
      final trigram = HexagramData.getTrigramByName('乾');
      expect(trigram?.symbol, '☰');
      expect(trigram?.element, '金');
    });

    test('应该能根据ID获取六十四卦', () async {
      await HexagramData.load();
      final hexagram = HexagramData.getHexagramById(1);
      expect(hexagram?.name, '乾为天');
      expect(hexagram?.description, '元亨利贞');
      expect(hexagram?.yaoCi, hasLength(6));
      expect(hexagram?.yaoCi.first, '潜龙勿用');
      expect(hexagram?.yongCi, '见群龙无首，吉');
    });

    test('六十四卦完整数据应满足唯一性与爻辞约束', () async {
      await HexagramData.load();
      final hexagrams = HexagramData.hexagrams;
      expect(hexagrams.map((item) => item.id).toSet(), hasLength(64));
      expect(hexagrams.map((item) => item.binary).toSet(), hasLength(64));

      for (final hexagram in hexagrams) {
        expect(
          hexagram.binary,
          matches(RegExp(r'^[01]{6}$')),
          reason: hexagram.name,
        );
        expect(hexagram.yaoCi, hasLength(6), reason: hexagram.name);
        expect(
          hexagram.yaoCi.every((text) => text.trim().isNotEmpty),
          isTrue,
          reason: hexagram.name,
        );
        expect(
          HexagramData.getTrigramByName(hexagram.upper)?.binary,
          hexagram.binary.substring(0, 3),
          reason: '${hexagram.name} 上卦',
        );
        expect(
          HexagramData.getTrigramByName(hexagram.lower)?.binary,
          hexagram.binary.substring(3),
          reason: '${hexagram.name} 下卦',
        );
        expect(
          HexagramData.getHexagramByBinary(hexagram.binary),
          same(hexagram),
        );
      }

      expect(HexagramData.getHexagramById(2)?.yongCi, '利永贞');
      expect(
        hexagrams
            .where((item) => item.yongCi != null)
            .map((item) => item.id)
            .toSet(),
        {1, 2},
      );
      expect(HexagramData.getHexagramByBinary('222222'), isNull);
    });

    test('不存在的卦象查询应返回 null', () async {
      await HexagramData.load();
      expect(HexagramData.getTrigramByIndex(99), isNull);
      expect(HexagramData.getTrigramByName('不存在'), isNull);
      expect(HexagramData.getHexagramById(999), isNull);
      expect(HexagramData.getHexagramByName('不存在'), isNull);
    });
  });

  group('干支数据测试', () {
    test('应该能加载干支数据', () async {
      await GanzhiData.load();
      expect(GanzhiData.tiangan.length, 10);
      expect(GanzhiData.dizhi.length, 12);
    });

    test('应该能生成六十甲子', () async {
      await GanzhiData.load();
      final jiazi = GanzhiData.sixtyJiazi;
      expect(jiazi.length, 60);
      expect(jiazi.first, '甲子');
      expect(jiazi.last, '癸亥');
    });
  });

  test('三山国王灵签数据应包含完整 92 签', () async {
    await SsgwData.load();
    expect(SsgwData.signs, hasLength(92));
    expect(SsgwData.getByNumber(1)?.title, contains('第一签'));
    expect(SsgwData.getByNumber(92)?.title, contains('第九十二签'));
  });
}
