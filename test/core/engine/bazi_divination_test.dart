import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/bazi/bazi_divination.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  test('公历角色生成完整四柱、藏干、起运和大运', () {
    final result = BaziEngine.calculate(
      CaseSnapshot(
        caseId: 'solar',
        name: '测试角色',
        gender: CaseGender.male,
        calendarType: CaseCalendarType.solar,
        birthDateTime: DateTime(1990, 5, 17, 14, 30),
      ),
      now: DateTime(2026, 9, 22),
    );
    expect(result.pillars, hasLength(4));
    expect(result.pillars[2].name, '日柱');
    expect(result.pillars.every((p) => p.hiddenStems.isNotEmpty), isTrue);
    expect(result.elementCounts.values.fold(0, (a, b) => a + b), 8);
    expect(result.luckCycles, hasLength(8));
    expect(result.luckStart, isNotEmpty);
    expect(result.algorithm.version, 2);
  });

  test('农历出生资料会先转换为公历', () {
    final result = BaziEngine.calculate(
      CaseSnapshot(
        caseId: 'lunar',
        name: '农历角色',
        gender: CaseGender.female,
        calendarType: CaseCalendarType.lunar,
        birthDateTime: DateTime(2024, 1, 1, 8),
      ),
    );
    expect(result.usedLunarConversion, isTrue);
    expect(result.solarCivilTime, DateTime(2024, 2, 10, 8));
  });

  test('有经度时使用真太阳时参与排盘', () {
    final result = BaziEngine.calculate(
      CaseSnapshot(
        caseId: 'solar-time',
        name: '经度角色',
        gender: CaseGender.male,
        calendarType: CaseCalendarType.solar,
        birthDateTime: DateTime(2000, 1, 1, 12),
        longitude: 105,
      ),
    );
    expect(result.usedTrueSolarTime, isTrue);
    expect(result.trueSolarCorrectionMinutes, isNotNull);
    expect(result.calculationTime, isNot(result.solarCivilTime));
    expect(result.toJson()['pillars'], hasLength(4));
  });
}
