import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = jsonDecode(
    File('test_vectors/daily_hexagram/v3.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final vectors = fixture['vectors'] as List<dynamic>;

  setUpAll(HexagramData.load);

  group('每日一卦 v3 golden 向量', () {
    for (final raw in vectors) {
      final vector = Map<String, dynamic>.from(raw as Map);
      test(vector['caseId'] as String, () {
        final expected = Map<String, dynamic>.from(vector['expected'] as Map);
        final result = DailyHexagramEngine.fromYaoValues(
          (vector['yaos'] as List).cast<int>(),
          date: DateTime(2026, 9, 17),
        );

        expect(result.algorithm.version, fixture['_meta']['algorithmVersion']);
        expect(result.original.name, expected['original']);
        expect(result.changed.name, expected['changed']);
        expect(result.inter.name, expected['inter']);
        expect(
          result.movingLines.map((item) => item.position).toList(),
          (expected['moving'] as List).cast<int>(),
        );
        expect(result.takingRule.primaryTexts.first, expected['primary']);
        if (expected['secondary'] case final String secondary) {
          expect(result.takingRule.secondaryTexts.first, secondary);
        }
      });
    }
  });
}
