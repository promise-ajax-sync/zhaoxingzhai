import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/shared/random.dart';
import 'package:zhaoxingzhai/core/shared/result.dart';

void main() {
  group('随机数系统测试', () {
    test('系统随机模式应生成 [0, 1) 范围内的数', () {
      final ctx = createRandomContext();
      for (int i = 0; i < 100; i++) {
        final value = ctx.random();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('种子随机模式应可重复', () {
      final ctx1 = createRandomContext(seed: 'test-seed-123');
      final ctx2 = createRandomContext(seed: 'test-seed-123');

      final samples1 = List.generate(10, (_) => ctx1.random());
      final samples2 = List.generate(10, (_) => ctx2.random());

      expect(samples1, equals(samples2));
    });

    test('不同种子应产生不同结果', () {
      final ctx1 = createRandomContext(seed: 'seed-a');
      final ctx2 = createRandomContext(seed: 'seed-b');

      final samples1 = List.generate(10, (_) => ctx1.random());
      final samples2 = List.generate(10, (_) => ctx2.random());

      expect(samples1, isNot(equals(samples2)));
    });

    test('replay 模式应精确重放', () {
      final ctx1 = createRandomContext(seed: 42);
      final samples = List.generate(5, (_) => ctx1.random());
      final trace = ctx1.getTrace();

      // 使用 replay 模式重放
      final ctx2 = createRandomContext(replay: trace.samples);
      final replayed = List.generate(5, (_) => ctx2.random());

      expect(replayed, equals(samples));
    });

    test('replay 模式用尽样本应抛出异常', () {
      final ctx = createRandomContext(replay: [0.5, 0.3]);
      ctx.random(); // 消耗第一个
      ctx.random(); // 消耗第二个

      expect(
        () => ctx.random(),
        throwsA(isA<MingyuCoreError>()),
      );
    });

    test('randomInt 应生成正确范围内的整数', () {
      final ctx = createRandomContext(seed: 'test');
      for (int i = 0; i < 100; i++) {
        final value = randomInt(10, ctx.random);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('randomInt 应无偏分布（统计测试）', () {
      final ctx = createRandomContext(seed: 12345);
      final counts = List.filled(5, 0);
      
      for (int i = 0; i < 5000; i++) {
        final value = randomInt(5, ctx.random);
        counts[value]++;
      }

      // 每个值应该接近 1000 次（允许 20% 偏差）
      for (final count in counts) {
        expect(count, greaterThan(800));
        expect(count, lessThan(1200));
      }
    });

    test('getTrace 应记录所有样本', () {
      final ctx = createRandomContext(seed: 'trace-test');
      
      ctx.random();
      ctx.random();
      ctx.random();

      final trace = ctx.getTrace();
      expect(trace.samples.length, equals(3));
      expect(trace.mode, equals(RandomMode.seeded));
      expect(trace.seed, equals('trace-test'));
    });

    test('自定义随机源应正常工作', () {
      var counter = 0.1;
      double custom() {
        final value = counter;
        counter += 0.1;
        if (counter >= 1.0) counter = 0.1;
        return value;
      }

      final ctx = createRandomContext(random: custom);
      expect(ctx.random(), closeTo(0.1, 0.01));
      expect(ctx.random(), closeTo(0.2, 0.01));
      expect(ctx.random(), closeTo(0.3, 0.01));
    });

    test('种子为数字应正常工作', () {
      final ctx1 = createRandomContext(seed: 42);
      final ctx2 = createRandomContext(seed: 42);

      final samples1 = List.generate(5, (_) => ctx1.random());
      final samples2 = List.generate(5, (_) => ctx2.random());

      expect(samples1, equals(samples2));
    });

    test('种子应支持字符串和整数', () {
      // 字符串种子
      final ctx1 = createRandomContext(seed: 'test');
      expect(ctx1.random(), greaterThanOrEqualTo(0.0));

      // 整数种子
      final ctx2 = createRandomContext(seed: 123);
      expect(ctx2.random(), greaterThanOrEqualTo(0.0));
    });

    test('replay 空数组应抛出异常', () {
      expect(
        () => createRandomContext(replay: []),
        throwsA(isA<MingyuCoreError>()),
      );
    });

    test('多个随机选项同时提供应抛出异常', () {
      expect(
        () => createRandomContext(seed: 123, replay: [0.5]),
        throwsA(isA<MingyuCoreError>()),
      );
    });

    test('randomInt 超出范围应抛出异常', () {
      final ctx = createRandomContext();
      expect(
        () => randomInt(0, ctx.random),
        throwsA(isA<MingyuCoreError>()),
      );
      expect(
        () => randomInt(-1, ctx.random),
        throwsA(isA<MingyuCoreError>()),
      );
    });

    test('secureRandomInt 应生成正确范围', () {
      for (int i = 0; i < 100; i++) {
        final value = secureRandomInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('secureRandomFloat 应生成 [0, 1) 范围', () {
      for (int i = 0; i < 100; i++) {
        final value = secureRandomFloat();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });
  });

  group('哈希和种子测试', () {
    test('相同字符串种子应产生相同哈希', () {
      final ctx1 = createRandomContext(seed: 'same-seed');
      final ctx2 = createRandomContext(seed: 'same-seed');

      expect(ctx1.random(), equals(ctx2.random()));
    });

    test('不同字符串长度应产生不同结果', () {
      final ctx1 = createRandomContext(seed: 'short');
      final ctx2 = createRandomContext(seed: 'longer-seed');

      expect(ctx1.random(), isNot(equals(ctx2.random())));
    });
  });

  // 固定向量回归网。
  //
  // 这些数值是当前实现的确定性输出，跨设备、跨平台必须恒定不变。
  // 任何随机层改动只要让它们变化，就会让用户已保存的历史记录无法重放，
  // 因此必须显式确认后才有意更新。
  group('固定种子向量（回归基线）', () {
    const vectors = <String, List<double>>{
      'test': [0.7171058997, 0.3465085106, 0.2675761438, 0.2510541403, 0.8766860503],
      'abc': [0.5166419989, 0.6596221293, 0.0018796597, 0.8993499738, 0.7205349628],
      'seed': [0.9498909889, 0.0760880485, 0.0262593005, 0.6270247973, 0.0932085868],
      'xiaoliuren': [0.3633643612, 0.1510057927, 0.0453237824, 0.0621373011, 0.4749033514],
      '资料隔离': [0.7317366910, 0.7408707764, 0.0761906742, 0.5007299406, 0.7770696981],
      '': [0.6112444522, 0.4935242918, 0.7740248835, 0.4122861116, 0.8122657815],
      '1': [0.8317172497, 0.1230088961, 0.8262572752, 0.7499541824, 0.5743482173],
    };

    vectors.forEach((seed, expected) {
      test('种子 "$seed" 应产生既定序列', () {
        final ctx = createRandomContext(seed: seed);
        final actual = List.generate(expected.length, (_) => ctx.random());

        for (int i = 0; i < expected.length; i++) {
          expect(
            actual[i],
            closeTo(expected[i], 1e-9),
            reason: 'seed="$seed" 第 $i 个样本偏离基线',
          );
        }
      });
    });

    test('整数种子 42 应产生既定序列', () {
      final ctx = createRandomContext(seed: 42);
      final actual = List.generate(5, (_) => ctx.random());
      // int 种子经 toString() 后与字符串 "42" 同哈希
      final asText = createRandomContext(seed: '42');
      final expected = List.generate(5, (_) => asText.random());

      expect(actual, equals(expected));
    });

    test('固定向量落盘后可经 replay 精确复原', () {
      final ctx = createRandomContext(seed: 'test');
      final drawn = List.generate(5, (_) => ctx.random());
      final trace = ctx.getTrace();

      final replayed = createRandomContext(replay: trace.samples);
      final restored = List.generate(5, (_) => replayed.random());

      expect(restored, equals(drawn));
      for (int i = 0; i < 5; i++) {
        expect(restored[i], closeTo(vectors['test']![i], 1e-9));
      }
    });

    // Web 平台回归网。
    //
    // 在 Web 上 Dart 的 int 由 JS 数字承载，只有 53 位精度。
    // 若 _imul 写成 `(a * b) & 0xFFFFFFFF`，两个 32 位数的乘积可达 2⁶⁴，
    // 会静默丢精度，使 Web 与原生平台产生完全不同的随机序列。
    // 下面用乘积超过 2⁵³ 的输入把这一点钉住。
    test('种子哈希应正确截断超过 2^53 的乘积', () {
      // 0xFFFFFFFF * 16777619 ≈ 7.2e16 > 2^53，是精度丢失的高危输入
      final ctx = createRandomContext(seed: 'test');
      expect(ctx.random(), closeTo(0.7171058997, 1e-9));
    });

    test('长种子（多轮哈希累乘）应保持确定性', () {
      const long = '这是一个足够长的种子用来触发多轮哈希累乘与截断验证';
      final a = createRandomContext(seed: long);
      final b = createRandomContext(seed: long);
      expect(a.random(), equals(b.random()));

      // 中文种子走 UTF-16 code unit，需与上游一致
      final cn = createRandomContext(seed: '资料隔离');
      expect(cn.random(), closeTo(0.7317366910, 1e-9));
    });
  });

  group('安全随机数值域', () {
    test('secureRandomFloat 应覆盖完整的 53 位精度而不塌缩', () {
      final values = List.generate(20000, (_) => secureRandomFloat());

      // 全部落在 [0, 1)
      expect(values.every((v) => v >= 0 && v < 1), isTrue);
      // 若位宽写反，高 27 位会退化成小值，导致最大样本明显偏小
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      expect(maxValue, greaterThan(0.9));
      // 均值应接近 0.5
      final mean = values.reduce((a, b) => a + b) / values.length;
      expect(mean, closeTo(0.5, 0.02));
      // 相邻样本不应大量重复（塌缩成少数取值的迹象）
      expect(values.toSet().length, greaterThan(values.length * 0.99));
    });

    test('secureRandomInt 应覆盖全范围且无空桶', () {
      const m = 6;
      const n = 60000;
      final counts = List.filled(m, 0);

      for (int i = 0; i < n; i++) {
        final value = secureRandomInt(m);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(m));
        counts[value]++;
      }

      // 每个桶都应被命中，无空桶
      expect(counts.every((c) => c > 0), isTrue);
      // 各桶计数不应严重偏离均值
      final mean = n / m;
      expect(counts.every((c) => (c - mean).abs() < mean * 0.2), isTrue);
    });

    test('secureRandomInt 在大范围下应给出分散取值', () {
      final distinct = List.generate(2000, (_) => secureRandomInt(1000000)).toSet();
      expect(distinct.length, greaterThan(1900));
    });
  });
}
