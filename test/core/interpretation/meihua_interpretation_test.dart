import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/interpretation/meihua_interpretation.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  test('体生用转换为投入与成本的现代白话提醒', () {
    final result = MeihuaDivination.number(number: 123, hourBranch: '辰');
    final reading = MeihuaInterpretation.build(result);

    expect(reading.id, 'meihua.local-reading');
    expect(reading.version, 4);
    expect(reading.situation, contains('投入精力、时间或资源'));
    expect(reading.action, contains('投入上限'));
    expect(reading.trend, contains(result.movingYaoCi));
    expect(reading.riskReminder, contains('不应替代'));
  });

  test('五种体用关系都有对应白话解释', () {
    final readings = <String, MeihuaInterpretation>{};
    const branches = [
      '子',
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
      '亥',
    ];
    for (final branch in branches) {
      for (var number = 1; number <= 64 && readings.length < 5; number++) {
        final result = MeihuaDivination.number(
          number: number,
          hourBranch: branch,
        );
        readings.putIfAbsent(
          result.tiYongRelation,
          () => MeihuaInterpretation.build(result),
        );
      }
      if (readings.length == 5) break;
    }

    expect(readings.keys, containsAll(['比和', '用生体', '体生用', '用克体', '体克用']));
    for (final reading in readings.values) {
      expect(reading.situation, isNotEmpty);
      expect(reading.action, isNotEmpty);
      expect(reading.riskReminder, isNotEmpty);
    }
  });

  test('解释可以序列化恢复，损坏结构安全返回空', () {
    final result = MeihuaDivination.number(number: 1, hourBranch: '辰');
    final reading = MeihuaInterpretation.build(result);
    final restored = MeihuaInterpretation.tryParse(reading.toJson());

    expect(restored?.action, reading.action);
    expect(restored?.version, 4);
    expect(MeihuaInterpretation.tryParse({'version': 1}), isNull);
  });

  test('按占问分类生成对应的现代白话提示', () {
    final result = MeihuaDivination.number(number: 123, hourBranch: '辰');
    final career = MeihuaInterpretation.build(result, topic: 'career');
    final health = MeihuaInterpretation.build(result, topic: 'health');

    expect(career.topicLabel, '事业工作');
    expect(career.topicGuidance, contains('职责'));
    expect(health.topicLabel, '健康状态');
    expect(health.topicGuidance, contains('医疗'));
  });

  test('地点问题会直接回应地点和场景而不是泛化感情建议', () {
    final result = MeihuaDivination.number(number: 123, hourBranch: '辰');
    final question = DivinationQuestion.parse(
      '我会在哪里找到对象',
      topic: 'relationship',
    );
    final reading = MeihuaInterpretation.build(
      result,
      topic: 'relationship',
      question: question,
    );

    expect(question.intent, DivinationQuestionIntent.location);
    expect(reading.questionIntent, 'location');
    expect(reading.directAnswer, contains('地点'));
    expect(reading.directAnswer, contains('场景'));
    expect(reading.evidenceSummary, contains('用卦'));
    expect(reading.evidence.methodId, 'meihua');
    expect(reading.evidence.calculationFacts, hasLength(3));
    expect(
      reading.evidence.counterEvidence.map((item) => item.id),
      contains('direction-not-address'),
    );
    expect(reading.evidence.limitations, isNotEmpty);
  });
}
