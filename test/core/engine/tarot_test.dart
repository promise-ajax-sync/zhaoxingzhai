import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';
import 'package:zhaoxingzhai/features/tarot/tarot_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(TarotData.load);

  List<String> snapshot(TarotDrawResult result) => result.cards
      .map((card) => '${card.cardId}:${card.name}:${card.orientation}')
      .toList();

  group('塔罗占卜', () {
    test('相同 seed 应生成相同牌面和正逆位', () {
      final first = TarotDivination(seed: '昭星斋-塔罗').drawSpread('three');
      final second = TarotDivination(seed: '昭星斋-塔罗').drawSpread('three');

      expect(snapshot(first), snapshot(second));
      expect(first.randomTrace?.mode, RandomMode.seeded);
      expect(first.randomTrace?.seed, '昭星斋-塔罗');
      expect(first.randomTrace?.samples, isNotEmpty);
    });

    test('随机轨迹应能完整 replay', () {
      final original = TarotDivination(seed: '重放测试').drawSpread('love');
      final replayed = TarotDivination(replay: original.randomTrace!.samples)
          .drawSpread('love');

      expect(snapshot(replayed), snapshot(original));
      expect(replayed.randomTrace?.mode, RandomMode.replay);
    });

    test('复用引擎连续抽牌时每次结果只保留本次随机轨迹', () {
      final tarot = TarotDivination(seed: '连续抽牌');
      tarot.drawSingle();
      final second = tarot.drawSpread('three');
      final replayed = TarotDivination(replay: second.randomTrace!.samples)
          .drawSpread('three');

      expect(snapshot(replayed), snapshot(second));
    });

    test('全部上游牌阵都可以完成抽牌且不重复', () {
      for (final entry in TarotData.spreads.entries) {
        final result = TarotDivination(seed: '牌阵-${entry.key}')
            .drawSpread(entry.key);
        expect(result.cards.length, entry.value.cardCount, reason: entry.key);
        expect(
          result.cards.map((card) => card.cardId).toSet().length,
          entry.value.cardCount,
          reason: entry.key,
        );
      }
    });

    test('手动录入无效牌号时应抛出明确参数错误', () {
      expect(
        () => TarotDivination().drawManual('single', const [
          ManualCardInput(id: 999, reversed: false),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
