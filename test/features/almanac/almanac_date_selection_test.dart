import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/features/almanac/domain/almanac_date_selection.dart';

void main() {
  test('择日结果只包含宜目标事项且不同时列入忌项的日期', () {
    final activity = almanacSelectionActivities.firstWhere(
      (item) => item.id == 'travel',
    );

    final results = findAlmanacDates(
      startDate: DateTime(2024, 1, 1),
      days: 90,
      activity: activity,
    );

    expect(results, isNotEmpty);
    for (final result in results) {
      expect(result.matchedYi, isNotEmpty);
      expect(result.yi, contains('出行'));
      expect(result.ji, isNot(contains('出行')));
    }
  });

  test('选择生肖后会排除与该生肖相冲的日期', () {
    final activity = almanacSelectionActivities.firstWhere(
      (item) => item.id == 'worship',
    );

    final results = findAlmanacDates(
      startDate: DateTime(2024, 2, 1),
      days: 90,
      activity: activity,
      excludedZodiac: '龙',
    );

    expect(results, isNotEmpty);
    expect(results.every((result) => result.clashZodiac != '龙'), isTrue);
  });

  test('择日查询限制在一到九十天', () {
    expect(
      () => findAlmanacDates(
        startDate: DateTime(2024, 1, 1),
        days: 91,
        activity: almanacSelectionActivities.first,
      ),
      throwsArgumentError,
    );
  });
}
