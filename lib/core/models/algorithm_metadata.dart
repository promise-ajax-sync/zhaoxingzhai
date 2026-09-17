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
}
