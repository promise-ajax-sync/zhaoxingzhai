/// 核心随机数系统
///
/// 完整移植自 mingyu-core/src/shared/random.ts
/// 支持三种随机模式：system（系统随机）、seeded（种子随机）、replay（重放模式）
///
/// 核心特性：
/// 1. 可重放：相同 seed 产生相同结果
/// 2. 可追溯：记录所有随机样本
/// 3. 可验证：replay 模式精确复现
library;

import 'dart:math' as math;
import 'result.dart';

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
  final RandomMode mode;
  final dynamic seed;  // String 或 int
  final List<double> samples;

  const RandomTrace({
    required this.mode,
    this.seed,
    required this.samples,
  });

  RandomTrace copyWith({
    RandomMode? mode,
    dynamic seed,
    List<double>? samples,
  }) {
    return RandomTrace(
      mode: mode ?? this.mode,
      seed: seed ?? this.seed,
      samples: samples ?? List.from(this.samples),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        if (seed != null) 'seed': seed,
        'samples': samples,
      };
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

/// 生成系统级安全随机浮点数 [0, 1)
double secureRandomFloat() {
  final random = math.Random.secure();
  // 生成 53 位精度的随机数
  final high = random.nextInt(1 << 26);
  final low = random.nextInt(1 << 27);
  return (high * 67108864 + low) / 9007199254740992;
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

  final random = math.Random.secure();
  final acceptanceLimit = _uint32Range - (_uint32Range % maxExclusive);
  
  int value;
  do {
    value = random.nextInt(_uint32Range);
  } while (value >= acceptanceLimit);
  
  return value % maxExclusive;
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
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  
  return hash;
}

/// 创建种子随机源（PCG 算法）
RandomSource createSeededRandom(dynamic seed) {
  int state = _hashSeed(seed);
  if (state == 0) state = 1;

  return () {
    state = (state + 0x6d2b79f5) & 0xFFFFFFFF;
    int value = state;
    
    value = _imul(value ^ (value >> 15), value | 1);
    value ^= value + _imul(value ^ (value >> 7), value | 61);
    
    return ((value ^ (value >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  };
}

/// 模拟 Math.imul
int _imul(int a, int b) {
  final ah = (a >> 16) & 0xffff;
  final al = a & 0xffff;
  final bh = (b >> 16) & 0xffff;
  final bl = b & 0xffff;
  return ((al * bl) + (((ah * bl + al * bh) << 16) & 0xFFFFFFFF)) & 0xFFFFFFFF;
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
