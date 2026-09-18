import 'package:lunar/lunar.dart';

import 'civil_time.dart';
import 'date_utils.dart';
import 'historical_timezone.dart';

/// 术式共享的中国民用时间历法快照。
///
/// 农历年以正月初一换年；节气干支另行保存，不能代替农历年支入数。
class DivinationCalendarSnapshot {
  const DivinationCalendarSnapshot({
    required this.instant,
    required this.civilTime,
    required this.timeZoneId,
    required this.timezoneOffsetMinutes,
    required this.lunarYearGanzhi,
    required this.lunarYearBranch,
    required this.lunarMonth,
    required this.lunarDay,
    required this.isLeapMonth,
    required this.hourBranch,
    required this.hourBranchIndex,
    required this.solarTermYearGanzhi,
    required this.solarTermMonthGanzhi,
    required this.dayGanzhi,
    required this.hourGanzhi,
  });

  final DateTime instant;
  final DateTime civilTime;
  final String timeZoneId;
  final int timezoneOffsetMinutes;
  final String lunarYearGanzhi;
  final String lunarYearBranch;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final String hourBranch;
  final int hourBranchIndex;
  final String solarTermYearGanzhi;
  final String solarTermMonthGanzhi;
  final String dayGanzhi;
  final String hourGanzhi;

  Map<String, dynamic> toJson() => {
    'instant': instant.toUtc().toIso8601String(),
    'civilTime': _formatCivil(civilTime),
    'timeZoneId': timeZoneId,
    'timezoneOffsetMinutes': timezoneOffsetMinutes,
    'lunarYearGanzhi': lunarYearGanzhi,
    'lunarYearBranch': lunarYearBranch,
    'lunarMonth': lunarMonth,
    'lunarDay': lunarDay,
    'isLeapMonth': isLeapMonth,
    'hourBranch': hourBranch,
    'hourBranchIndex': hourBranchIndex,
    'solarTermYearGanzhi': solarTermYearGanzhi,
    'solarTermMonthGanzhi': solarTermMonthGanzhi,
    'dayGanzhi': dayGanzhi,
    'hourGanzhi': hourGanzhi,
    'yearBoundary': '农历正月初一换年',
    'dayBoundary': '当地民用时间00:00换日',
    'leapMonthRule': '闰月沿用同名月序',
  };

  /// [value] 为 UTC 时表示真实瞬时点；为本地时间时，其字段被解释为
  /// [timeZoneId] 的当地民用钟表时间，避免设备时区改变计算结果。
  static DivinationCalendarSnapshot chinaCivil(
    DateTime value, {
    String timeZoneId = defaultChinaTimeZoneId,
  }) {
    late final DateTime instant;
    late final DateTime civil;
    late final int offsetMinutes;

    if (value.isUtc) {
      instant = value;
      final offsetHours = getHistoricalTimezoneOffsetAt(value, timeZoneId);
      offsetMinutes = (offsetHours * 60).round();
      civil = value.add(Duration(minutes: offsetMinutes));
    } else {
      final resolved = resolveCivilTime(
        CivilTimeResolutionInput(
          year: value.year,
          month: value.month,
          day: value.day,
          hour: value.hour,
          minute: value.minute,
          second: value.second,
          timeZoneId: timeZoneId,
        ),
      );
      instant = DateTime.fromMillisecondsSinceEpoch(
        resolved.utcTimestamp,
        isUtc: true,
      );
      offsetMinutes = (resolved.timezone * 60).round();
      civil = DateTime.utc(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      );
    }

    final lunar = Solar.fromDate(civil).getLunar();
    final hour = getShichenFromClock(civil.hour, civil.minute);
    if (hour == null) {
      throw ArgumentError('无法识别当地民用时间对应的时辰。');
    }
    final lunarYearGanzhi = lunar.getYearInGanZhi();
    if (lunarYearGanzhi.length < 2) {
      throw StateError('无法识别农历年干支：$lunarYearGanzhi');
    }

    return DivinationCalendarSnapshot(
      instant: instant,
      civilTime: civil,
      timeZoneId: timeZoneId,
      timezoneOffsetMinutes: offsetMinutes,
      lunarYearGanzhi: lunarYearGanzhi,
      lunarYearBranch: lunarYearGanzhi.substring(1, 2),
      lunarMonth: lunar.getMonth().abs(),
      lunarDay: lunar.getDay(),
      isLeapMonth: lunar.getMonth() < 0,
      hourBranch: hour.branch,
      hourBranchIndex: (hour.index % 12) + 1,
      solarTermYearGanzhi: lunar.getYearInGanZhiExact(),
      solarTermMonthGanzhi: lunar.getMonthInGanZhiExact(),
      dayGanzhi: lunar.getDayInGanZhiExact(),
      hourGanzhi: lunar.getTimeInGanZhi(),
    );
  }

  static String _formatCivil(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
}
