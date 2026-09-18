import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  test('声音起卦按声音次数和时支取数', () {
    final result = MeihuaDivination.sound(soundCount: 3, hourBranch: '辰');
    expect(
      (
        result.upperTrigramIndex,
        result.lowerTrigramIndex,
        result.movingYaoIndex,
      ),
      (3, 8, 2),
    );
    expect(result.algorithm.id, 'meihua.sound');
  });

  test('二字按逐字笔画数分上下卦', () {
    final result = MeihuaDivination.character(text: '西林', strokeCounts: [7, 8]);
    expect(
      (
        result.upperTrigramIndex,
        result.lowerTrigramIndex,
        result.movingYaoIndex,
      ),
      (7, 8, 3),
    );
  });

  test('四至十字按传统平上去入取数', () {
    final result = MeihuaDivination.character(
      text: '今日动静如何',
      traditionalTones: [1, 4, 3, 3, 1, 1],
    );
    expect(
      (
        result.upperTrigramIndex,
        result.lowerTrigramIndex,
        result.movingYaoIndex,
      ),
      (8, 5, 1),
    );
  });

  test('十一字以上只按字数分组', () {
    final result = MeihuaDivination.character(text: '天地玄黄宇宙洪荒日月盈昃');
    expect(
      (
        result.upperTrigramIndex,
        result.lowerTrigramIndex,
        result.movingYaoIndex,
      ),
      (6, 6, 6),
    );
  });

  test('方位起卦按物象、方位和时支取数', () {
    final result = MeihuaDivination.direction(
      direction: 'south',
      objectType: 'fire',
      hourBranch: '辰',
    );
    expect(
      (
        result.upperTrigramIndex,
        result.lowerTrigramIndex,
        result.movingYaoIndex,
      ),
      (3, 3, 5),
    );
    expect(result.algorithm.id, 'meihua.direction');
  });
}
