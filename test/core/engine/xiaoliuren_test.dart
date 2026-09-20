/// 小六壬算法测试
///
/// 小六壬算法回归测试。
library;

import 'package:test/test.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';
import 'package:zhaoxingzhai/core/shared/result.dart';

void main() {
  group('小六壬算法测试', () {
    test('古法二月例、闰月与子时边界保持同一偏移，旧盘沿用通行法', () {
      // 2025-02-28T00:30:00+08:00 (二月初一)
      final secondMonth = generateXiaoliuren(
        rule: XiaoliurenRule.duoneng,
        customDate: DateTime.parse('2025-02-28T00:30:00'),
      );

      expect(secondMonth.lunarMonth, equals(2));
      expect(secondMonth.lunarDay, equals(1));
      expect(secondMonth.primary.name, equals('速喜'));

      // 测试多个时间点
      final testTimes = [
        '2025-07-25T08:00:00',
        '2025-06-29T23:00:00',
        '2025-06-30T00:00:00',
      ];

      for (final timeStr in testTimes) {
        final customDate = DateTime.parse(timeStr);
        final common = generateXiaoliuren(customDate: customDate);
        final ancient = generateXiaoliuren(
          customDate: customDate,
          rule: XiaoliurenRule.duoneng,
        );

        // 古法与通行法相差一个宫位
        expect(ancient.primary.index, equals((common.primary.index + 1) % 6));
        expect(ancient.lunarDay, equals(common.lunarDay));
        expect(ancient.isLeapMonth, equals(common.isLeapMonth));
      }
    });

    test('多能鄙事正月初一十二时辰与扫描例题一致', () {
      final names = ['留连', '速喜', '赤口', '小吉', '空亡', '大安'];

      // 2025-01-29T00:30:00+08:00 是正月初一
      final baseTimestamp = DateTime.parse('2025-01-29T00:30:00')
          .millisecondsSinceEpoch;

      for (int i = 0; i < 12; i++) {
        final customDate = DateTime.fromMillisecondsSinceEpoch(
          baseTimestamp + i * 7200000, // 每次增加 2 小时
        );

        final data = generateXiaoliuren(
          rule: XiaoliurenRule.duoneng,
          customDate: customDate,
        );

        final common = generateXiaoliuren(customDate: customDate);

        expect(data.lunarMonth, equals(1), reason: '时间 $i: 应该是正月');
        expect(data.lunarDay, equals(1), reason: '时间 $i: 应该是初一');
        expect(
          data.sequence['month']!.name,
          equals('大安'),
          reason: '时间 $i: 月宫应该是大安',
        );
        expect(
          data.sequence['day']!.name,
          equals('留连'),
          reason: '时间 $i: 日宫应该是留连',
        );
        expect(data.primary.name, equals(names[i % 6]), reason: '时间 $i: 时宫不符');
        expect(data.primary.index, equals((common.primary.index + 1) % 6));
        expect(data.ruleLabel, equals('《多能鄙事》'));
      }
    });

    test('通行掌诀正月初一子时起大安', () {
      // 正月初一早子时（00:30）
      final data = generateXiaoliuren(
        rule: XiaoliurenRule.common,
        customDate: DateTime.parse('2025-01-29T00:30:00'),
      );

      expect(data.lunarMonth, equals(1));
      expect(data.lunarDay, equals(1));
      expect(data.sequence['month']!.name, equals('大安'));
      expect(data.sequence['day']!.name, equals('大安'));
      expect(data.primary.name, equals('大安'));
      expect(data.ruleLabel, equals('通行掌诀'));
    });

    test('六宫顺序验证：大安、留连、速喜、赤口、小吉、空亡', () {
      final data = generateXiaoliuren(
        customDate: DateTime.parse('2025-01-29T00:30:00'),
      );

      final expectedNames = ['大安', '留连', '速喜', '赤口', '小吉', '空亡'];
      expect(data.palaceOrder.length, equals(6));

      for (int i = 0; i < 6; i++) {
        expect(data.palaceOrder[i].name, equals(expectedNames[i]));
        expect(data.palaceOrder[i].index, equals(i));
        expect(data.palaceOrder[i].verse.isNotEmpty, isTrue);
      }
    });

    test('计算过程数据完整性', () {
      final data = generateXiaoliuren(
        customDate: DateTime.parse('2025-02-15T14:30:00'),
      );

      final calc = data.calculation;
      expect(calc.lunarMonth, greaterThan(0));
      expect(calc.lunarDay, greaterThan(0));
      expect(calc.hourNumber, greaterThan(0));
      expect(calc.monthSeed, greaterThan(0));
      expect(calc.daySeed, greaterThan(0));
      expect(calc.hourSeed, greaterThan(0));
      expect(calc.monthPalaceIndex, greaterThanOrEqualTo(0));
      expect(calc.monthPalaceIndex, lessThan(6));
      expect(calc.dayPalaceIndex, greaterThanOrEqualTo(0));
      expect(calc.dayPalaceIndex, lessThan(6));
      expect(calc.hourPalaceIndex, greaterThanOrEqualTo(0));
      expect(calc.hourPalaceIndex, lessThan(6));
      expect(calc.dayBoundary, equals('东八区民用日零点换日'));
      expect(calc.leapMonthRule, equals('闰月沿用同名月序'));
    });

    test('时辰转换正确性', () {
      // 测试不同时辰
      final testCases = [
        {'time': '2025-01-29T00:30:00', 'shichen': '早子时'},
        {'time': '2025-01-29T02:00:00', 'shichen': '丑时'},
        {'time': '2025-01-29T08:00:00', 'shichen': '辰时'},
        {'time': '2025-01-29T12:00:00', 'shichen': '午时'},
        {'time': '2025-01-29T18:00:00', 'shichen': '酉时'},
        {'time': '2025-01-29T23:30:00', 'shichen': '晚子时'},
      ];

      for (final testCase in testCases) {
        final data = generateXiaoliuren(
          customDate: DateTime.parse(testCase['time'] as String),
        );
        expect(data.hourLabel, equals(testCase['shichen']));
      }
    });

    test('JSON 序列化', () {
      final data = generateXiaoliuren(
        customDate: DateTime.parse('2025-01-29T12:00:00'),
      );

      final json = data.toJson();
      expect(json['meta']['engineVersion'], equals(zhaoxingzhaiEngineVersion));
      expect(json['meta']['algorithm'], equals('xiaoliuren'));
      expect(json['meta']['algorithmVersion'], equals(1));
      expect(json['meta']['ruleset'], equals('common-six-palace'));
      expect(json['meta']['implementation'], equals('zhaoxingzhai-dart'));
      expect(json['meta']['resultId'], startsWith('xiaoliuren:'));
      expect(json['rule'], isNotNull);
      expect(json['ruleLabel'], isNotNull);
      expect(json['method'], isNotNull);
      expect(json['methodLabel'], isNotNull);
      expect(json['timestamp'], isNotNull);
      expect(json['lunarMonth'], isNotNull);
      expect(json['lunarDay'], isNotNull);
      expect(json['calculation'], isNotNull);
      expect(json['sequence'], isNotNull);
      expect(json['palaceOrder'], isNotNull);
      expect(json['primary'], isNotNull);
      expect(json['ganzhi'], isNotNull);
      expect(json['calculation']['timezoneOffsetMinutes'], equals(480));
      expect(json['evidenceAnalysis']['status'], equals('已计算'));
      expect(json['evidenceAnalysis']['calculationSteps'], hasLength(3));
      expect(data.evidenceAnalysis.promptText, contains('占得宫'));
    });

    test('UTC 时间应按东八区民用时间起课', () {
      final utcResult = generateXiaoliuren(
        customDate: DateTime.parse('2025-01-28T16:30:00Z'),
      );
      final civilResult = generateXiaoliuren(
        customDate: DateTime(2025, 1, 29, 0, 30),
      );

      expect(utcResult.lunarMonth, civilResult.lunarMonth);
      expect(utcResult.lunarDay, civilResult.lunarDay);
      expect(utcResult.hourLabel, '早子时');
      expect(utcResult.primary.name, civilResult.primary.name);
      expect(utcResult.ganzhi.year, isNotEmpty);
      expect(utcResult.ganzhi.month, isNotEmpty);
      expect(utcResult.ganzhi.day, isNotEmpty);
      expect(utcResult.ganzhi.hour, isNotEmpty);
    });
  });
}
