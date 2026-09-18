import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = jsonDecode(
    File('test_vectors/meihua/v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final vectors = fixture['vectors'] as List<dynamic>;
  setUpAll(HexagramData.load);

  group('梅花易数 v1 固定向量', () {
    for (final raw in vectors) {
      final vector = Map<String, dynamic>.from(raw as Map);
      test(vector['caseId'] as String, () {
        final input = Map<String, dynamic>.from(vector['input'] as Map);
        final expected = Map<String, dynamic>.from(vector['expected'] as Map);
        final result = input['method'] == 'random'
            ? MeihuaDivination.random(seed: input['seed'])
            : MeihuaDivination.number(
                number: input['number'] as int,
                hourBranch: input['hourBranch'] as String,
              );

        expect(result.upperTrigramIndex, expected['upperTrigramIndex']);
        expect(result.lowerTrigramIndex, expected['lowerTrigramIndex']);
        expect(result.movingYaoIndex, expected['movingYaoIndex']);
        expect(result.original.name, expected['original']);
        expect(result.inter.name, expected['inter']);
        expect(result.changed.name, expected['changed']);
        expect(result.tiGua.name, expected['tiGua']);
        expect(result.yongGua.name, expected['yongGua']);
        expect(result.tiYongRelation, expected['tiYongRaw']);
        expect(result.movingYaoCi, expected['movingYaoCi']);
        if (expected['randomSamples'] case final List<dynamic> samples) {
          expect(result.randomTrace?.samples, samples.cast<double>());
        }
      });
    }
  });

  group('梅花易数时间法 v1 固定向量', () {
    final timeFixture = jsonDecode(
      File('test_vectors/meihua/time_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final timeVectors = timeFixture['vectors'] as List<dynamic>;

    for (final raw in timeVectors) {
      final vector = Map<String, dynamic>.from(raw as Map);
      test(vector['caseId'] as String, () {
        final input = Map<String, dynamic>.from(vector['input'] as Map);
        final expected = Map<String, dynamic>.from(vector['expected'] as Map);
        final result = MeihuaDivination.time(
          dateTime: DateTime.parse(input['civilDateTime'] as String),
        );

        for (final key in [
          'lunarYearGanzhi',
          'solarTermYearGanzhi',
          'yearZhi',
          'yearZhiIndex',
          'month',
          'day',
          'timeZhi',
          'timeZhiIndex',
        ]) {
          expect(result.calculation[key], expected[key], reason: key);
        }
        expect(result.upperTrigramIndex, expected['upperTrigramIndex']);
        expect(result.lowerTrigramIndex, expected['lowerTrigramIndex']);
        expect(result.movingYaoIndex, expected['movingYaoIndex']);
        expect(result.original.name, expected['original']);
        expect(result.changed.name, expected['changed']);
      });
    }
  });
}
