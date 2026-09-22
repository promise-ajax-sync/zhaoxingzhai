/// 算法身份与版本信息。
///
/// 算法版本独立于 App 版本：只要同一输入的结构化计算结果可能变化，
/// 就必须提升 [version]，以便历史记录、缓存和 replay 正确识别旧结果。
class AlgorithmDescriptor {
  final String id;
  final int version;
  final String ruleset;
  final String implementation;

  const AlgorithmDescriptor({
    required this.id,
    required this.version,
    required this.ruleset,
    this.implementation = 'zhaoxingzhai-dart',
  }) : assert(version > 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'ruleset': ruleset,
    'implementation': implementation,
  };
}

/// 当前已接入版本治理的算法。
abstract final class AlgorithmCatalog {
  static const xiaoliurenCommon = AlgorithmDescriptor(
    id: 'xiaoliuren',
    version: 1,
    ruleset: 'common-six-palace',
  );

  static const xiaoliurenDuoneng = AlgorithmDescriptor(
    id: 'xiaoliuren',
    version: 1,
    ruleset: 'duoneng-bishi',
  );

  static const tarot = AlgorithmDescriptor(
    id: 'tarot',
    version: 1,
    ruleset: 'rider-waite-78',
  );

  static const ssgwDraw = AlgorithmDescriptor(
    id: 'ssgw.draw',
    version: 1,
    ruleset: 'ssgw-92-signs-random',
  );

  static const ssgwManual = AlgorithmDescriptor(
    id: 'ssgw.resolve.manual',
    version: 1,
    ruleset: 'ssgw-92-signs-manual',
  );

  static const dailyHexagram = AlgorithmDescriptor(
    id: 'daily-hexagram',
    version: 3,
    ruleset: 'three-coins-six-lines-taking-rules-v1',
  );

  static const liuyao = AlgorithmDescriptor(
    id: 'liuyao',
    version: 2,
    ruleset: 'jingfang-najia-strength-relations-v2',
  );

  static const bazi = AlgorithmDescriptor(
    id: 'bazi',
    version: 2,
    ruleset: 'lunar-true-solar-hidden-stems-yun-v2',
  );

  static const ziwei = AlgorithmDescriptor(
    id: 'ziwei',
    version: 3,
    ruleset: 'foundation-28-stars-brightness-relations-limits-v3',
  );

  static const meihua = AlgorithmDescriptor(
    id: 'meihua',
    version: 1,
    ruleset: 'shaoshi-number-random-core-v1',
  );

  static const meihuaTime = AlgorithmDescriptor(
    id: 'meihua.time',
    version: 1,
    ruleset: 'lunar-year-month-day-china-civil-hour-v1',
  );

  static const meihuaSound = AlgorithmDescriptor(
    id: 'meihua.sound',
    version: 1,
    ruleset: 'sound-count-hour-branch-v1',
  );
  static const meihuaCharacter = AlgorithmDescriptor(
    id: 'meihua.character',
    version: 1,
    ruleset: 'character-segmentation-v1',
  );
  static const meihuaDirection = AlgorithmDescriptor(
    id: 'meihua.direction',
    version: 1,
    ruleset: 'direction-object-hour-branch-v1',
  );
}
