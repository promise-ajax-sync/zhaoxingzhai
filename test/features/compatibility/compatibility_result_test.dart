import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/compatibility/domain/compatibility_result.dart';

void main() {
  final first = CaseSnapshot(
    caseId: 'a',
    name: '甲方',
    gender: CaseGender.female,
    calendarType: CaseCalendarType.solar,
    birthDateTime: DateTime(1992, 4, 12, 10),
  );
  final second = CaseSnapshot(
    caseId: 'b',
    name: '乙方',
    gender: CaseGender.male,
    calendarType: CaseCalendarType.solar,
    birthDateTime: DateTime(1990, 9, 8, 9),
  );

  test('合盘结果稳定且交换双方顺序不改变分数', () {
    final forward = CompatibilityResult.build(
      first: first,
      second: second,
      relation: CompatibilityRelation.romance,
    );
    final reverse = CompatibilityResult.build(
      first: second,
      second: first,
      relation: CompatibilityRelation.romance,
    );

    expect(forward.score, reverse.score);
    expect(forward.stableId, reverse.stableId);
    expect(forward.strengths, isNotEmpty);
    expect(forward.frictions, isNotEmpty);
    expect(forward.actions, hasLength(3));
    expect(forward.evidence.methodId, compatibilityAlgorithmId);
  });

  test('同一个案例不能与自身合盘', () {
    expect(
      () => CompatibilityResult.build(
        first: first,
        second: first,
        relation: CompatibilityRelation.friendship,
      ),
      throwsArgumentError,
    );
  });
}
