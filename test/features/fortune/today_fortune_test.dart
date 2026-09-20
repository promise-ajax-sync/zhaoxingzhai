import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/fortune/domain/today_fortune.dart';

void main() {
  final dragonCase = CaseSnapshot(
    caseId: 'dragon-case',
    name: '测试案例',
    gender: CaseGender.unspecified,
    calendarType: CaseCalendarType.solar,
    birthDateTime: DateTime(2000, 2, 10, 12),
  );

  test('同一日期与案例生成稳定一致的今日运势', () {
    final first = TodayFortune.build(
      DateTime(2024, 2, 10),
      caseSnapshot: dragonCase,
    );
    final second = TodayFortune.build(
      DateTime(2024, 2, 10),
      caseSnapshot: dragonCase,
    );

    expect(first.dateKey, '2024-02-10');
    expect(first.zodiac, '龙');
    expect(first.overallScore, second.overallScore);
    expect(first.headline, second.headline);
    expect(first.luckyColor, second.luckyColor);
    expect(
      first.dimensions.map((item) => item.score),
      second.dimensions.map((item) => item.score),
    );
    expect(first.dimensions, hasLength(5));
    expect(first.evidence.methodId, todayFortuneAlgorithmId);
  });

  test('生肖相冲日期会降低总分并显示风险提示', () {
    TodayFortune? clashing;
    for (var offset = 0; offset < 12; offset++) {
      final result = TodayFortune.build(
        DateTime(2024, 1, 1).add(Duration(days: offset)),
        caseSnapshot: dragonCase,
      );
      if (result.isClashing) {
        clashing = result;
        break;
      }
    }

    expect(clashing, isNotNull);
    expect(clashing!.clashZodiac, '龙');
    expect(clashing.summary, contains('相冲'));
  });

  test('未选择案例时生成通用日运', () {
    final result = TodayFortune.build(DateTime(2024, 5, 1));

    expect(result.zodiac, isNull);
    expect(result.isClashing, isFalse);
    expect(result.evidence.calculationFacts.last.detail, contains('通用日运'));
  });
}
