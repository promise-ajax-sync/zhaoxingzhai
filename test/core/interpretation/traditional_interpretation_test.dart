import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';
import 'package:zhaoxingzhai/core/interpretation/ssgw_interpretation.dart';
import 'package:zhaoxingzhai/core/interpretation/tarot_interpretation.dart';
import 'package:zhaoxingzhai/core/interpretation/xiaoliuren_interpretation.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 顺序预热资源，避免 Flutter 测试绑定下多个 rootBundle 读取互相竞态。
    await SsgwData.load();
    await TarotData.load();
  });

  test('小六壬两套规则均生成现代白话解读', () {
    for (final rule in XiaoliurenRule.values) {
      final result = generateXiaoliuren(
        rule: rule,
        customDate: DateTime(2026, 9, 17, 12),
      );
      final reading = XiaoliurenInterpretation.build(result);
      expect(reading.id, 'xiaoliuren.local-reading');
      expect(reading.version, 2);
      expect(reading.action, isNotEmpty);
      expect(reading.riskReminder, contains('不代表现实事件必然发生'));
    }
  });

  test('小六壬按是否问题生成直接回应与结构化证据', () {
    final result = generateXiaoliuren(
      customDate: DateTime(2026, 9, 17, 12),
    );
    final question = DivinationQuestion.parse('这件事近期会不会成功');
    final reading = XiaoliurenInterpretation.build(result, question: question);

    expect(reading.questionIntent, 'yes_no');
    expect(reading.directAnswer, isNotEmpty);
    expect(reading.evidence.methodId, 'xiaoliuren');
    expect(reading.evidence.supportingEvidence, isNotEmpty);
    expect(reading.evidence.limitations, isNotEmpty);
    expect(reading.toJson()['evidence']['methodId'], 'xiaoliuren');
  });

  test('塔罗现代白话解读覆盖正逆位牌面', () {
    final result = TarotDivination(seed: '白话解释测试').drawSpread('three');
    final reading = TarotInterpretation.build(result);
    expect(reading.id, 'tarot.local-reading');
    expect(reading.version, 2);
    expect(reading.cardReadings, hasLength(3));
    expect(reading.action, contains('可验证'));
    expect(reading.riskReminder, contains('不应用来断定'));
  });

  test('塔罗按人物心理问题生成直接回应与结构化证据', () {
    final result = TarotDivination(seed: '人物问题').drawSpread('three');
    final question = DivinationQuestion.parse(
      '对方内心怎么想',
      topic: DivinationQuestion.inferTopic('对方内心怎么想'),
    );
    final reading = TarotInterpretation.build(result, question: question);

    expect(reading.questionIntent, 'person');
    expect(question.topic, 'relationship');
    expect(reading.directAnswer, contains('人物线索'));
    expect(reading.evidence.methodId, 'tarot');
    expect(reading.evidence.calculationFacts, hasLength(3));
    expect(reading.evidence.counterEvidence, isNotEmpty);
    expect(reading.toJson()['evidence']['methodId'], 'tarot');
  });

  test('灵签现代白话解读读取签文中的行动和风险字段', () {
    final reading = SsgwInterpretation.build(SsgwDivination.resolve(1));
    expect(reading.id, 'ssgw.local-reading');
    expect(reading.version, 2);
    expect(reading.overview, contains('明月'));
    expect(reading.action, contains('借势而行'));
    expect(reading.riskReminder, contains('专业判断'));
  });

  test('灵签按感情问题选择相关栏目并生成结构化证据', () {
    final question = DivinationQuestion.parse(
      '这段感情未来会如何发展',
      topic: DivinationQuestion.inferTopic('这段感情未来会如何发展'),
    );
    final reading = SsgwInterpretation.build(
      SsgwDivination.resolve(1),
      question: question,
    );

    expect(question.topic, 'relationship');
    expect(reading.questionIntent, 'trend');
    expect(reading.directAnswer, isNotEmpty);
    expect(reading.evidence.methodId, 'ssgw');
    expect(reading.evidence.supportingEvidence, isNotEmpty);
    expect(reading.evidence.limitations, isNotEmpty);
  });
}
