import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/features/almanac/domain/traditional_almanac_day.dart';

void main() {
  test('春节日期可以生成稳定的公农历与传统日课信息', () {
    final day = TraditionalAlmanacDay.fromDate(DateTime(2024, 2, 10));

    expect(day.solarDateLabel, '2024年2月10日');
    expect(day.weekday, '星期六');
    expect(day.lunarDate, '农历正月初一');
    expect(day.zodiac, '龙');
    expect(day.yearGanzhi, '甲辰');
    expect(day.yi, isNotEmpty);
    expect(day.ji, isNotEmpty);
    expect(day.dutyOfficer, isNotEmpty);
    expect(day.clash, isNotEmpty);
    expect(day.lunarFestivals, contains('春节'));
    expect(day.dayNaYin, isNotEmpty);
    expect(day.fetalGod, isNotEmpty);
    expect(day.timePeriods, hasLength(12));
    expect(day.timePeriods.map((item) => item.label).toSet(), hasLength(12));
    expect(day.timePeriods.first.label, '子时');
    expect(day.timePeriods.first.ganZhi, isNotEmpty);
    expect(day.timePeriods.first.heavenlyGod, isNotEmpty);
  });

  test('公历节日会进入日期详情和月份单元格', () {
    final day = TraditionalAlmanacDay.fromDate(DateTime(2024, 10, 1));
    final cell = AlmanacMonthCell.fromDate(DateTime(2024, 10, 1));

    expect(day.solarFestivals, contains('国庆节'));
    expect(cell.festival, '国庆节');
    expect(cell.lunarLabel, '国庆节');
    expect(cell.isSpecial, isTrue);
  });

  test('节气当天会显示节气并提供前后节气', () {
    final day = TraditionalAlmanacDay.fromDate(DateTime(2024, 3, 20));

    expect(day.solarTerm, '春分');
    expect(day.previousSolarTerm, contains('惊蛰'));
    expect(day.nextSolarTerm, contains('清明'));
  });

  test('月份网格固定生成六周并包含相邻月份日期', () {
    final cells = buildAlmanacMonthGrid(2024, 2);

    expect(cells, hasLength(42));
    expect(cells.first.date, DateTime(2024, 1, 28));
    expect(cells.last.date, DateTime(2024, 3, 9));
    expect(
      cells
          .singleWhere((item) => item.date == DateTime(2024, 2, 10))
          .lunarLabel,
      '春节',
    );
  });
}
