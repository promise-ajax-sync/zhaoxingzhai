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
}
