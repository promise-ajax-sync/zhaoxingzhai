import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';

class SsgwResult {
  const SsgwResult({
    required this.sign,
    required this.method,
    required this.timestamp,
    required this.algorithm,
    this.randomTrace,
  });

  final SsgwSign sign;
  final String method;
  final DateTime timestamp;
  final AlgorithmDescriptor algorithm;
  final RandomTrace? randomTrace;

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm.toJson(),
    'method': method,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'sign': sign.toJson(),
    if (randomTrace != null) 'randomTrace': randomTrace!.toJson(),
  };
}

class SsgwDivination {
  SsgwDivination({dynamic seed, List<double>? replay, RandomSource? random})
    : _randomContext = createRandomContext(
        seed: seed,
        replay: replay,
        random: random,
      );

  final RandomContext _randomContext;

  SsgwResult draw({DateTime? timestamp}) {
    final before = _randomContext.getTrace().samples.length;
    final index = randomInt(SsgwData.signs.length, _randomContext.random);
    final trace = _randomContext.getTrace();
    return SsgwResult(
      sign: SsgwData.signs[index],
      method: 'random',
      timestamp: timestamp ?? DateTime.now(),
      algorithm: AlgorithmCatalog.ssgwDraw,
      randomTrace: trace.copyWith(samples: trace.samples.sublist(before)),
    );
  }

  static SsgwResult resolve(int number, {DateTime? timestamp}) {
    final sign = SsgwData.getByNumber(number);
    if (sign == null) throw ArgumentError('签号需为1至92的整数');
    return SsgwResult(
      sign: sign,
      method: 'manual',
      timestamp: timestamp ?? DateTime.now(),
      algorithm: AlgorithmCatalog.ssgwManual,
    );
  }
}
