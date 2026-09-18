import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/daily_hexagram/daily_hexagram.dart';
import 'package:zhaoxingzhai/core/interpretation/daily_hexagram_interpretation.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  group('每日一卦本地分项解读', () {
    test('零动爻强调稳定延续且保留风险提醒', () {
      final result = DailyHexagramEngine.fromYaoValues(List.filled(6, 7));
      final reading = DailyHexagramInterpretation.build(result);

      expect(reading.version, 2);
      expect(reading.traditionalOverview, contains('本卦“乾为天”'));
      expect(reading.trend, contains('六爻皆静'));
      expect(reading.pace, contains('稳定'));
      expect(reading.riskReminder, contains('不把卦象当作确定结论'));
    });

    test('一个动爻使用取用规则并指出集中变化', () {
      final result = DailyHexagramEngine.fromYaoValues([6, 7, 7, 7, 7, 7]);
      final reading = DailyHexagramInterpretation.build(result);

      expect(reading.traditionalOverview, contains(result.takingRule.summary));
      expect(reading.traditionalOverview, contains('系于金柅'));
      expect(reading.trend, contains('1个动爻'));
      expect(reading.pace, contains('变化集中'));
    });

    test('三个动爻兼顾本卦互卦与变卦', () {
      final result = DailyHexagramEngine.fromYaoValues([6, 9, 6, 7, 7, 7]);
      final reading = DailyHexagramInterpretation.build(result);

      expect(reading.situation, contains(result.original.name));
      expect(reading.innerContext, contains(result.inter.name));
      expect(reading.trend, contains(result.changed.name));
      expect(reading.pace, contains('本卦与变卦'));
    });

    test('六爻皆动提示整体转换并可序列化恢复', () {
      final result = DailyHexagramEngine.fromYaoValues(List.filled(6, 9));
      final reading = DailyHexagramInterpretation.build(result);
      final restored = DailyHexagramInterpretation.tryParse(reading.toJson());

      expect(reading.traditionalOverview, contains('见群龙无首'));
      expect(reading.pace, contains('整体结构正在转换'));
      expect(reading.riskReminder, contains('6个老阳'));
      expect(restored?.trend, reading.trend);
    });

    test('损坏的历史解读安全返回 null', () {
      expect(DailyHexagramInterpretation.tryParse({'version': 1}), isNull);
    });

    test('按行动问题生成直接回应与结构化证据', () {
      final result = DailyHexagramEngine.fromYaoValues([6, 7, 7, 7, 7, 7]);
      final question = DivinationQuestion.parse('今天工作上应该怎么做');
      final reading = DailyHexagramInterpretation.build(
        result,
        question: question,
      );

      expect(reading.questionIntent, 'action');
      expect(reading.directAnswer, contains('针对今天怎么做'));
      expect(reading.evidence.methodId, 'daily-hexagram');
      expect(reading.evidence.calculationFacts, hasLength(3));
      expect(reading.evidence.limitations, isNotEmpty);
    });
  });
}
