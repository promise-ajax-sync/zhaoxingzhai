import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = jsonDecode(
    File('test_vectors/ssgw/v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = fixture['cases'] as List<dynamic>;

  setUpAll(SsgwData.load);

  group('三山国王灵签固定回归向量', () {
    for (final raw in cases) {
      final vector = Map<String, dynamic>.from(raw as Map);
      test(vector['caseId'] as String, () {
        final expected = Map<String, dynamic>.from(vector['expected'] as Map);
        final result = SsgwDivination(seed: vector['seed']).draw();

        expect(result.sign.number, expected['number']);
        expect(result.sign.title, expected['title']);
        expect(result.sign.poem, expected['poem']);
        expect(result.algorithm.version, fixture['algorithmVersion']);
        expect(result.randomTrace?.algorithmId, fixture['randomAlgorithmId']);
        expect(
          result.randomTrace?.algorithmVersion,
          fixture['randomAlgorithmVersion'],
        );
      });
    }
  });
}
