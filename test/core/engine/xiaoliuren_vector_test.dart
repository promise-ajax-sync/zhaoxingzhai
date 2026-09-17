import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';

void main() {
  final fixture = jsonDecode(
    File('test_vectors/xiaoliuren/v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final vectors = fixture['vectors'] as List<dynamic>;

  group('小六壬外部测试向量', () {
    for (final raw in vectors) {
      final vector = Map<String, dynamic>.from(raw as Map);
      test(vector['id'] as String, () {
        final input = Map<String, dynamic>.from(vector['input'] as Map);
        final expected = Map<String, dynamic>.from(vector['expected'] as Map);
        final rule = switch (input['rule']) {
          'duoneng' => XiaoliurenRule.duoneng,
          _ => XiaoliurenRule.common,
        };

        final result = generateXiaoliuren(
          rule: rule,
          customDate: DateTime.parse(input['dateTime'] as String),
        );

        expect(result.meta.algorithm, fixture['algorithmId']);
        expect(result.meta.algorithmVersion, fixture['algorithmVersion']);
        expect(result.lunarMonth, expected['lunarMonth']);
        expect(result.lunarDay, expected['lunarDay']);
        if (expected.containsKey('isLeapMonth')) {
          expect(result.isLeapMonth, expected['isLeapMonth']);
        }
        expect(result.hourLabel, expected['hourLabel']);
        if (expected.containsKey('hourNumber')) {
          expect(result.calculation.hourNumber, expected['hourNumber']);
        }
        expect(result.sequence['month']!.name, expected['monthPalace']);
        expect(result.sequence['day']!.name, expected['dayPalace']);
        expect(result.sequence['hour']!.name, expected['hourPalace']);
      });
    }
  });
}
