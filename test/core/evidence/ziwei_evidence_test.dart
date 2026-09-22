import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/evidence/ziwei_evidence.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AI 证据只包含已计算盘面并明确未接入规则', () async {
    final result = await ZiweiChartEngine.calculate(
      CaseSnapshot(
        caseId: 'ziwei-evidence',
        name: '证据角色',
        gender: CaseGender.female,
        calendarType: CaseCalendarType.lunar,
        birthDateTime: DateTime(2024, 1, 1),
      ),
    );
    const question = DivinationQuestion(
      rawText: '请综合解读',
      topic: 'general',
      intent: DivinationQuestionIntent.general,
    );
    final evidence = ZiweiEvidenceBuilder.build(result, question);
    expect(evidence.methodId, 'ziwei');
    expect(
      evidence.calculationFacts.map((e) => e.label),
      containsAll(['命身与五行局', '命宫星曜', '生年四化', '大限']),
    );
    expect(
      evidence.limitations.map((e) => e.detail).join(),
      allOf(contains('庙旺'), contains('流年流月'), contains('AI 不得自行补全')),
    );
  });
}
