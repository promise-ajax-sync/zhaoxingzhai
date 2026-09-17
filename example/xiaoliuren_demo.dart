// ignore_for_file: avoid_print

import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';

void main() {
  print('='.repeat(60));
  print('小六壬时间起课演示');
  print('='.repeat(60));
  print('');

  // 示例 1：使用当前时间（通行掌诀）
  print('【示例 1】使用当前时间 - 通行掌诀');
  print('-'.repeat(60));
  final result1 = generateXiaoliuren();
  printResult(result1);
  print('');

  // 示例 2：使用指定时间（通行掌诀）
  print('【示例 2】2025年1月29日子时（正月初一） - 通行掌诀');
  print('-'.repeat(60));
  final result2 = generateXiaoliuren(
    customDate: DateTime.parse('2025-01-29T00:30:00'),
  );
  printResult(result2);
  print('');

  // 示例 3：使用《多能鄙事》规则
  print('【示例 3】2025年1月29日子时（正月初一） - 《多能鄙事》');
  print('-'.repeat(60));
  final result3 = generateXiaoliuren(
    rule: XiaoliurenRule.duoneng,
    customDate: DateTime.parse('2025-01-29T00:30:00'),
  );
  printResult(result3);
  print('');

  // 示例 4：对比不同时辰
  print('【示例 4】正月初一十二时辰对比（通行掌诀）');
  print('-'.repeat(60));
  final baseTime = DateTime.parse('2025-01-29T00:30:00').millisecondsSinceEpoch;
  final shichens = [
    '早子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '晚子',
  ];

  for (int i = 0; i < 12; i++) {
    final time = DateTime.fromMillisecondsSinceEpoch(baseTime + i * 7200000);
    final result = generateXiaoliuren(customDate: time);
    print(
      '${shichens[i]}时：${result.primary.name.padRight(6)} - ${result.primary.verse}',
    );
  }
  print('');

  // 示例 5：JSON 序列化
  print('【示例 5】JSON 序列化');
  print('-'.repeat(60));
  final result5 = generateXiaoliuren(
    customDate: DateTime.parse('2025-02-15T14:30:00'),
  );
  final json = result5.toJson();
  print('规则：${json['ruleLabel']}');
  print('农历：${json['lunarMonth']}月${json['lunarDay']}日');
  print('时辰：${json['hourLabel']}');
  print('月宫：${json['sequence']['month']['name']}');
  print('日宫：${json['sequence']['day']['name']}');
  print('时宫：${json['sequence']['hour']['name']}');
  print('主断：${json['primary']['name']} - ${json['primary']['verse']}');
  print('');

  print('='.repeat(60));
  print('演示完成');
  print('='.repeat(60));
}

void printResult(XiaoliurenData result) {
  print('规则：${result.ruleLabel}');
  print(
    '农历：${result.lunarMonth}月${result.lunarDay}日${result.isLeapMonth ? '（闰月）' : ''}',
  );
  print('时辰：${result.hourLabel}');
  print('');
  print('起课过程：');
  print(
    '  月宫：${result.sequence['month']!.name.padRight(6)} (月种子: ${result.calculation.monthSeed})',
  );
  print(
    '  日宫：${result.sequence['day']!.name.padRight(6)} (日种子: ${result.calculation.daySeed})',
  );
  print(
    '  时宫：${result.sequence['hour']!.name.padRight(6)} (时种子: ${result.calculation.hourSeed})',
  );
  print('');
  print('主断：【${result.primary.name}】');
  print('断辞：${result.primary.verse}');
}

extension StringExtension on String {
  String repeat(int count) => List.filled(count, this).join();
}
