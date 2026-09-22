import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/ziwei_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ZiweiData.resetForTest);

  test('紫微独立数据源包含十二宫、十四主星和基础辅煞曜', () async {
    final palaces = await ZiweiData.loadPalaces();
    final stars = await ZiweiData.loadStars();
    expect(palaces, hasLength(12));
    expect(stars, hasLength(28));
    expect(palaces.map((e) => e.id).toSet(), hasLength(12));
    expect(stars.map((e) => e.id).toSet(), hasLength(28));
    expect(stars.where((e) => e.group == 'major'), hasLength(14));
    expect(stars.every((e) => e.keywords.isNotEmpty), isTrue);
  });

  test('十天干四化表完整且每干包含禄权科忌四项', () async {
    final mutagens = await ZiweiData.loadMutagens();
    expect(mutagens.keys.toSet(), {
      '甲',
      '乙',
      '丙',
      '丁',
      '戊',
      '己',
      '庚',
      '辛',
      '壬',
      '癸',
    });
    expect(mutagens.values.every((items) => items.length == 4), isTrue);
  });

  test('全书系七档亮度表覆盖二十星与十二地支', () async {
    final brightness = await ZiweiData.loadBrightness();
    expect(brightness.profileId, 'quanshu-seven-tier-v1');
    expect(brightness.byStar, hasLength(20));
    expect(brightness.sourceCommit, isNot('unknown'));
    expect(brightness.levels, ['庙', '旺', '得', '利', '平', '不', '陷']);
    for (final rows in brightness.byStar.values) {
      expect(rows, isA<Map<String, String?>>());
      expect(rows, hasLength(12));
      expect(
        rows.values.whereType<String>().every(brightness.levels.contains),
        isTrue,
      );
    }
  });

  test('数据清单声明项目独立规则版本', () async {
    final manifest = await ZiweiData.loadManifest();
    expect(manifest['schemaVersion'], 1);
    expect(manifest['dataVersion'], 4);
    expect(
      manifest['ruleset'],
      'zhaoxingzhai-ziwei-foundation-stars-brightness-relations-limits-v3',
    );
    expect(
      manifest['status'],
      'foundation-stars-brightness-relations-and-decadal-mutagens',
    );
    expect(
      (manifest['files'] as List).toSet(),
      containsAll({
        'palaces.json',
        'stars.json',
        'mutagens.json',
        'brightness.json',
        'placement_rules.json',
      }),
    );
  });
}
