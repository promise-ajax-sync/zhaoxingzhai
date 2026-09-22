import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_foundation.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  test('紫微基础盘生成十二宫、命身宫和五行局', () {
    final result = ZiweiFoundationEngine.calculate(
      CaseSnapshot(
        caseId: 'ziwei-1',
        name: '测试角色',
        gender: CaseGender.male,
        calendarType: CaseCalendarType.solar,
        birthDateTime: DateTime(1990, 5, 17, 12),
      ),
    );
    expect(result.palaces, hasLength(12));
    expect(result.palaces.map((e) => e.name).toSet(), hasLength(12));
    expect(result.palaces.where((e) => e.isLife), hasLength(1));
    expect(result.palaces.where((e) => e.isBody), hasLength(1));
    expect(result.bureauNumber, inInclusiveRange(2, 6));
    expect(result.fiveElementBureau, endsWith('局'));
  });

  test('命宫按生月顺数并按时支逆数，身宫按时支顺数', () {
    final midnight = ZiweiFoundationEngine.calculate(
      CaseSnapshot(
        caseId: 'ziwei-2',
        name: '子时',
        gender: CaseGender.female,
        calendarType: CaseCalendarType.lunar,
        birthDateTime: DateTime(2024, 1, 1, 0),
      ),
    );
    expect(midnight.lifeBranch, '寅');
    expect(midnight.bodyBranch, '寅');
    expect(midnight.timeBranch, '子');
  });

  test('十二宫从命宫起逆向排布且地支不重复', () {
    final result = ZiweiFoundationEngine.calculate(
      CaseSnapshot(
        caseId: 'ziwei-3',
        name: '排宫',
        gender: CaseGender.male,
        calendarType: CaseCalendarType.lunar,
        birthDateTime: DateTime(2024, 6, 15, 8),
      ),
    );
    expect(result.palaces.first.name, '命宫');
    expect(result.palaces[1].name, '兄弟宫');
    expect(result.palaces.map((e) => e.branch).toSet(), hasLength(12));
    expect(result.toJson()['palaces'], hasLength(12));
  });
}
