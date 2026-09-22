import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_foundation.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_limits.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  ZiweiFoundationResult foundation(CaseGender gender) =>
      ZiweiFoundationEngine.calculate(
        CaseSnapshot(
          caseId: 'limit-${gender.name}',
          name: '大限角色',
          gender: gender,
          calendarType: CaseCalendarType.lunar,
          birthDateTime: DateTime(2024, 1, 1),
        ),
      );

  test('阳男与阴女顺行，阴男与阳女逆行', () {
    expect(
      ZiweiLimitEngine.calculate(
        foundation: foundation(CaseGender.male),
        yearStem: '甲',
      ).direction,
      ZiweiLimitDirection.forward,
    );
    expect(
      ZiweiLimitEngine.calculate(
        foundation: foundation(CaseGender.female),
        yearStem: '乙',
      ).direction,
      ZiweiLimitDirection.forward,
    );
    expect(
      ZiweiLimitEngine.calculate(
        foundation: foundation(CaseGender.male),
        yearStem: '乙',
      ).direction,
      ZiweiLimitDirection.reverse,
    );
    expect(
      ZiweiLimitEngine.calculate(
        foundation: foundation(CaseGender.female),
        yearStem: '甲',
      ).direction,
      ZiweiLimitDirection.reverse,
    );
  });

  test('大限从命宫按五行局数起虚岁并每限十年', () {
    final result = ZiweiLimitEngine.calculate(
      foundation: foundation(CaseGender.male),
      yearStem: '甲',
    );
    final bureau = foundation(CaseGender.male).bureauNumber;
    expect(result.startNominalAge, bureau);
    expect(result.decades, hasLength(12));
    expect(result.decades.first.palace.isLife, isTrue);
    expect(result.decades.first.startNominalAge, bureau);
    expect(result.decades.first.endNominalAge, bureau + 9);
    expect(result.decades[1].startNominalAge, bureau + 10);
    expect(result.decades.map((e) => e.palace.index).toSet(), hasLength(12));
    expect(result.toJson()['ageConvention'], 'nominal-age');
  });

  test('性别未指定时不静默猜测大限顺逆', () {
    final result = ZiweiLimitEngine.calculate(
      foundation: foundation(CaseGender.unspecified),
      yearStem: '甲',
    );
    expect(result.direction, ZiweiLimitDirection.undetermined);
    expect(result.decades, isEmpty);
  });
}
