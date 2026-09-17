/// 核心随机数系统
///
/// 设计参考 mingyu-core/src/shared/random.ts，但**不追求与上游位级一致**。
/// 本实现自成一个确定性体系：同一 seed 在同一实现版本内跨设备、跨平台结果恒定。
///
/// 支持四种随机模式：system（系统随机）、seeded（种子随机）、
/// custom（自定义随机源）、replay（重放模式）
///
/// 核心特性：
/// 1. 可重放：相同 seed 产生相同结果
/// 2. 可追溯：记录所有随机样本
/// 3. 可验证：replay 模式精确复现
///
/// 注意：原生 Dart 可精确承载这里的乘积，但 Dart Web 使用 JS Number，
/// 两个 32 位数直接相乘会超过 53 位安全整数范围。因此 `_imul` 必须采用
/// 16 位半字分解，保证固定种子在 Web 与原生平台产生同一序列。
library;

import 'dart:math' as math;
import 'result.dart';

/// 随机序列兼容版本。改变哈希、PRNG、取整或拒绝采样规则时必须递增。
const randomAlgorithmId = 'fnv1a32-mulberry32';
const randomAlgorithmVersion = 2;

/// 随机源函数类型
typedef RandomSource = double Function();

/// 随机模式
enum RandomMode {
  system,  // 系统级安全随机
  seeded,  // 种子随机
  custom,  // 自定义随机源
  replay,  // 重放模式
}

/// 随机轨迹（用于记录和重放）
class RandomTrace {
  final String algorithmId;
  final int algorithmVersion;
  final RandomMode mode;
  final dynamic seed;  // String 或 int
  final List<double> samples;

  const RandomTrace({
    this.algorithmId = randomAlgorithmId,
    this.algorithmVersion = randomAlgorithmVersion,
    required this.mode,
    this.seed,
    required this.samples,
  });

  RandomTrace copyWith({
    String? algorithmId,
    int? algorithmVersion,
    RandomMode? mode,
    dynamic seed,
    List<double>? samples,
  }) {
    return RandomTrace(
      algorithmId: algorithmId ?? this.algorithmId,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      mode: mode ?? this.mode,
      seed: seed ?? this.seed,
      samples: samples ?? List.from(this.samples),
    );
  }

  Map<String, dynamic> toJson() => {
        'algorithmId': algorithmId,
        'algorithmVersion': algorithmVersion,
        'mode': mode.name,
        if (seed != null) 'seed': seed,
        'samples': samples,
      };

  factory RandomTrace.fromJson(Map<String, dynamic> json) {
    return RandomTrace(
      // 旧记录没有版本字段，归入版本 1，不能假定为当前算法。
      algorithmId: json['algorithmId'] as String? ?? randomAlgorithmId,
      algorithmVersion: json['algorithmVersion'] as int? ?? 1,
      mode: RandomMode.values.byName(json['mode'] as String),
      seed: json['seed'],
      samples: (json['samples'] as List)
          .map((sample) => (sample as num).toDouble())
          .toList(growable: false),
    );
  }
}

/// 随机上下文（包含随机源和轨迹记录）
class RandomContext {
  final RandomSource random;
  final RandomTrace Function() getTrace;

  const RandomContext({
    required this.random,
    required this.getTrace,
  });
}

/// 32位无符号整数范围
const _uint32Range = 0x100000000;

/// [0, 1) 的 53 位精度分母
const _uint53Range = 9007199254740992;

/// 系统级安全随机源。复用同一实例，避免每次调用都重新初始化熵池。
final math.Random _secureRandom = math.Random.secure();

/// 生成系统级安全随机浮点数 [0, 1)
///
/// 取 27 位高位与 26 位低位拼成 53 位整数，再除以 2^53。
double secureRandomFloat() {
  final high = _secureRandom.nextInt(1 << 27);
  final low = _secureRandom.nextInt(1 << 26);
  return (high * 67108864 + low) / _uint53Range;
}

/// 使用拒绝采样生成无模偏差的随机整数
int secureRandomInt(int maxExclusive) {
  if (maxExclusive <= 0 || maxExclusive > _uint32Range) {
    throw MingyuCoreError(
      code: 'RANDOM_SECURE_RANGE_INVALID',
      category: ErrorCategory.validation,
      message: '安全随机整数范围必须是 1 至 4294967296 之间的整数',
    );
  }

  final bucketSize = _uint32Range ~/ maxExclusive;
  final acceptanceLimit = bucketSize * maxExclusive;

  int value;
  do {
    value = _secureRandom.nextInt(_uint32Range);
  } while (value >= acceptanceLimit);

  return value ~/ bucketSize;
}

/// 32 位截断乘法（等价于 JS 的 Math.imul）
///
/// 为什么不用更短的 `(a * b) & 0xFFFFFFFF`：在 **Web 平台**上 Dart 的 int
/// 由 JS 数字承载，只有 53 位精度，而两个 32 位数的乘积可达 2⁶⁴，
/// 会静默丢精度，导致 Web 与原生平台产生不同的随机序列。
/// 这里拆成 16 位半字，保证任一中间结果都不超过 2⁵³。
///
/// `ah * bh` 项的真实权重是 2³²，在 32 位截断中必然为 0，故无需计算。
int _imul(int a, int b) {
  final ah = (a >> 16) & 0xffff;
  final al = a & 0xffff;
  final bh = (b >> 16) & 0xffff;
  final bl = b & 0xffff;

  return (al * bl + (((ah * bl + al * bh) & 0xffff) << 16)) & 0xFFFFFFFF;
}

/// 哈希种子（FNV-1a 算法）
int _hashSeed(dynamic seed) {
  if (seed is! String && seed is! int) {
    throw MingyuCoreError(
      code: 'RANDOM_SEED_INVALID',
      category: ErrorCategory.validation,
      message: '随机种子必须是有限数字或文本',
      field: 'seed',
    );
  }

  final text = seed.toString();
  int hash = 2166136261;

  for (int i = 0; i < text.length; i++) {
    hash ^= text.codeUnitAt(i);
    hash = _imul(hash, 16777619);
  }

  return hash & 0xFFFFFFFF;
}

/// 创建种子随机源（Mulberry32 变体）
RandomSource createSeededRandom(dynamic seed) {
  int state = _hashSeed(seed);
  if (state == 0) state = 1;

  return () {
    state = (state + 0x6d2b79f5) & 0xFFFFFFFF;
    int value = state;

    value = _imul(value ^ (value >> 15), value | 1);
    // 加法会产生 33 位中间值，必须在异或前先截断到 32 位，
    // 否则高位会漏进异或结果（此前版本即因此与预期序列分叉）。
    final mixed = (value + _imul(value ^ (value >> 7), value | 61)) & 0xFFFFFFFF;
    value = (value ^ mixed) & 0xFFFFFFFF;

    return (value ^ (value >> 14)) / 4294967296.0;
  };
}

/// 断言随机样本有效性
double _assertRandomSample(double value) {
  if (!value.isFinite || value < 0 || value >= 1) {
    throw MingyuCoreError(
      code: 'RANDOM_SAMPLE_INVALID',
      category: ErrorCategory.validation,
      message: '随机源必须返回大于等于 0 且小于 1 的数字',
      field: 'random',
    );
  }
  return value;
}

/// 创建随机上下文
RandomContext createRandomContext({
  dynamic seed,
  List<double>? replay,
  RandomSource? random,
}) {
  // 验证参数冲突
  final optionsCount = [seed != null, replay != null, random != null]
      .where((x) => x)
      .length;
  
  if (optionsCount > 1) {
    throw MingyuCoreError(
      code: 'RANDOM_OPTIONS_CONFLICT',
      category: ErrorCategory.validation,
      message: 'seed、replay 与自定义随机源只能提供一种',
    );
  }

  RandomMode mode = RandomMode.system;
  RandomSource source = secureRandomFloat;
  dynamic traceSeed;

  if (replay != null) {
    if (replay.isEmpty) {
      throw MingyuCoreError(
        code: 'RANDOM_REPLAY_REQUIRED',
        category: ErrorCategory.validation,
        message: '随机重放样本必须是非空数组',
        field: 'replay',
      );
    }
    
    final samples = replay.map(_assertRandomSample).toList();
    int index = 0;
    mode = RandomMode.replay;
    
    source = () {
      if (index >= samples.length) {
        throw MingyuCoreError(
          code: 'RANDOM_REPLAY_EXHAUSTED',
          category: ErrorCategory.validation,
          message: '随机重放样本已用尽',
          field: 'replay',
        );
      }
      return samples[index++];
    };
  } else if (random != null) {
    mode = RandomMode.custom;
    source = random;
  } else if (seed != null) {
    mode = RandomMode.seeded;
    source = createSeededRandom(seed);
    traceSeed = seed;
  }

  final samples = <double>[];

  return RandomContext(
    random: () {
      final value = _assertRandomSample(source());
      samples.add(value);
      return value;
    },
    getTrace: () => RandomTrace(
      mode: mode,
      seed: traceSeed,
      samples: List.from(samples),
    ),
  );
}

/// 生成随机整数 [0, maxExclusive)
int randomInt(int maxExclusive, RandomSource rng) {
  if (maxExclusive <= 0 || maxExclusive > _uint32Range) {
    throw MingyuCoreError(
      code: 'RANDOM_RANGE_INVALID',
      category: ErrorCategory.validation,
      message: '随机整数范围必须是 1 至 4294967296 之间的整数',
    );
  }

  final bucketSize = _uint32Range ~/ maxExclusive;
  final acceptanceLimit = bucketSize * maxExclusive;
  
  int candidate;
  do {
    candidate = (_assertRandomSample(rng()) * _uint32Range).floor();
  } while (candidate >= acceptanceLimit);
  
  return candidate ~/ bucketSize;
}
