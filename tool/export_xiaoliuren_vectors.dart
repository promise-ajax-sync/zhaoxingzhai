import 'dart:convert';
import 'dart:io';

import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';

Map<String, String> _readArgs(List<String> arguments) {
  if (arguments.length.isOdd) {
    throw const FormatException('参数必须使用 --key value 格式。');
  }
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final key = arguments[index];
    if (!key.startsWith('--')) throw FormatException('参数格式错误：$key');
    result[key.substring(2)] = arguments[index + 1];
  }
  return result;
}

Map<String, dynamic> _normalize(XiaoliurenData result) => {
  'lunarMonth': result.lunarMonth,
  'lunarDay': result.lunarDay,
  'isLeapMonth': result.isLeapMonth,
  'hourLabel': result.hourLabel,
  'hourNumber': result.calculation.hourNumber,
  'monthPalace': result.sequence['month']!.name,
  'dayPalace': result.sequence['day']!.name,
  'hourPalace': result.sequence['hour']!.name,
  'monthPalaceIndex': result.calculation.monthPalaceIndex,
  'dayPalaceIndex': result.calculation.dayPalaceIndex,
  'hourPalaceIndex': result.calculation.hourPalaceIndex,
  'dayBoundary': result.calculation.dayBoundary,
  'leapMonthRule': result.calculation.leapMonthRule,
};

Future<void> main(List<String> arguments) async {
  final args = _readArgs(arguments);
  final fixturePath = args['vectors'];
  final outputPath = args['output'];
  if (fixturePath == null || outputPath == null) {
    throw const FormatException('必须提供 --vectors 和 --output。');
  }

  final fixture = jsonDecode(await File(fixturePath).readAsString())
      as Map<String, dynamic>;
  final vectors = fixture['vectors'] as List<dynamic>;
  final results = <Map<String, dynamic>>[];

  for (final raw in vectors) {
    final vector = Map<String, dynamic>.from(raw as Map);
    final input = Map<String, dynamic>.from(vector['input'] as Map);
    final rule = input['rule'] == 'duoneng'
        ? XiaoliurenRule.duoneng
        : XiaoliurenRule.common;
    final result = generateXiaoliuren(
      customDate: DateTime.parse(input['dateTime'] as String),
      rule: rule,
    );
    results.add({'id': vector['id'], 'result': _normalize(result)});
  }

  final output = File(outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'algorithmId': fixture['algorithmId'],
      'reference': 'zhaoxingzhai-dart',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'results': results,
    })}\n',
  );
  stdout.writeln('已导出 ${results.length} 条 Dart 小六壬向量：$outputPath');
}
