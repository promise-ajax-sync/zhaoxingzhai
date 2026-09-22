import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final subject = CaseSnapshot(
    caseId: 'ziwei-annual-2024',
    name: '流年回归角色',
    gender: CaseGender.male,
    calendarType: CaseCalendarType.lunar,
    birthDateTime: DateTime(2024, 1, 1),
  );

  test('甲辰流年采用太岁命宫并生成完整四化', () async {
    final result = await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2024,
    );
    final annual = result.annual;

    expect(annual.yearStem, '甲');
    expect(annual.yearBranch, '辰');
    expect(annual.lifePalace.branch, '辰');
    expect(annual.nominalAge, 1);
    expect(annual.transformations, hasLength(4));
    expect(annual.transformations.map((e) => e.mutagen).toSet(), {
      '禄',
      '权',
      '科',
      '忌',
    });
  });

  test('流年十二宫从太岁宫逆排且宫名和物理宫位均唯一', () async {
    final annual = (await ZiweiChartEngine.calculate(subject)).annual;

    expect(annual.palaces, hasLength(12));
    expect(annual.palaces.first.name, '命宫');
    expect(annual.palaces.first.position.branch, annual.yearBranch);
    expect(annual.palaces.map((e) => e.name).toSet(), hasLength(12));
    expect(annual.palaces.map((e) => e.position.index).toSet(), hasLength(12));
    for (var index = 1; index < annual.palaces.length; index++) {
      expect(
        annual.palaces[index].position.index,
        (annual.palaces[index - 1].position.index + 11) % 12,
      );
    }
  });

  test('虚岁定位童限与相邻大限边界', () async {
    final age1 = (await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2024,
    )).annual;
    final age6 = (await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2029,
    )).annual;
    final age15 = (await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2038,
    )).annual;
    final age16 = (await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2039,
    )).annual;

    expect(age1.activeDecade, isNull);
    expect(age6.nominalAge, 6);
    expect(age6.activeDecade?.order, 1);
    expect(age15.activeDecade?.order, 1);
    expect(age16.activeDecade?.order, 2);
  });

  test('不同流年年干使用不同四化序列', () async {
    final jia = (await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2024,
    )).annual;
    final yi = (await ZiweiChartEngine.calculate(
      subject,
      targetLunarYear: 2025,
    )).annual;

    expect(yi.yearStem, '乙');
    expect(
      yi.transformations.map((e) => e.starName).toList(),
      isNot(jia.transformations.map((e) => e.starName).toList()),
    );
  });

  test('目标流年不得早于出生农历年', () async {
    await expectLater(
      ZiweiChartEngine.calculate(subject, targetLunarYear: 2023),
      throwsA(isA<ArgumentError>()),
    );
  });
}
