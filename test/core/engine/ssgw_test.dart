import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(SsgwData.load);

  group('三山国王灵签', () {
    test('应加载完整 92 签和增强解签字段', () {
      expect(SsgwData.signs, hasLength(92));
      expect(SsgwData.signs.first.number, 1);
      expect(SsgwData.signs.last.number, 92);
      expect(SsgwData.signs.first.details['核心寓意'], isNotEmpty);
    });

    test('相同 seed 应抽中同一签并支持 replay', () {
      final first = SsgwDivination(seed: '灵签固定种子').draw();
      final second = SsgwDivination(seed: '灵签固定种子').draw();
      final replay = SsgwDivination(replay: first.randomTrace!.samples).draw();

      expect(second.sign.number, first.sign.number);
      expect(replay.sign.number, first.sign.number);
      expect(first.randomTrace?.algorithmId, randomAlgorithmId);
      expect(first.randomTrace?.algorithmVersion, randomAlgorithmVersion);
      expect(first.algorithm.id, 'ssgw.draw');
    });

    test('手动查签应返回对应签号且拒绝越界', () {
      final result = SsgwDivination.resolve(1);
      expect(result.sign.number, 1);
      expect(result.method, 'manual');
      expect(result.randomTrace, isNull);
      expect(() => SsgwDivination.resolve(0), throwsArgumentError);
      expect(() => SsgwDivination.resolve(93), throwsArgumentError);
    });
  });
}
