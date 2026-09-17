import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture = jsonDecode(
    File('test_vectors/tarot/v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = fixture['cases'] as List<dynamic>;

  setUpAll(TarotData.load);

  group('塔罗 mingyu 0.4.0 golden 向量', () {
    for (final raw in cases) {
      final vector = Map<String, dynamic>.from(raw as Map);
      test(vector['caseId'] as String, () {
        final result = TarotDivination(seed: vector['seed'])
            .drawSpread(vector['spreadType'] as String);
        final actual = result.cards
            .map(
              (card) => {
                'cardId': card.cardId,
                'name': card.name,
                'position': card.position,
                'orientation': card.orientation,
              },
            )
            .toList();
        final expected = (vector['expected'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        expect(result.algorithm.version, fixture['algorithmVersion']);
        expect(result.randomTrace?.algorithmId, fixture['randomAlgorithmId']);
        expect(
          result.randomTrace?.algorithmVersion,
          fixture['randomAlgorithmVersion'],
        );
        expect(actual, expected);
      });
    }
  });
}
