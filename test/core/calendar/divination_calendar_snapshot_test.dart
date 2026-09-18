import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/calendar/divination_calendar_snapshot.dart';

void main() {
  group('术式历法快照', () {
    test('立春后春节前保留农历卯年，同时保存甲辰节气干支年', () {
      final snapshot = DivinationCalendarSnapshot.chinaCivil(
        DateTime(2024, 2, 5, 12),
      );

      expect(snapshot.lunarYearGanzhi, '癸卯');
      expect(snapshot.lunarYearBranch, '卯');
      expect(snapshot.lunarMonth, 12);
      expect(snapshot.lunarDay, 26);
      expect(snapshot.hourBranch, '午');
      expect(snapshot.solarTermYearGanzhi, '甲辰');
    });

    test('春节零点切换农历年，23时子时不提前换日', () {
      final before = DivinationCalendarSnapshot.chinaCivil(
        DateTime(2024, 2, 9, 23, 30),
      );
      final after = DivinationCalendarSnapshot.chinaCivil(
        DateTime(2024, 2, 10, 0, 30),
      );

      expect(before.lunarYearGanzhi, '癸卯');
      expect(before.lunarMonth, 12);
      expect(before.lunarDay, 30);
      expect(before.hourBranch, '子');
      expect(after.lunarYearGanzhi, '甲辰');
      expect(after.lunarMonth, 1);
      expect(after.lunarDay, 1);
      expect(after.hourBranch, '子');
    });

    test('UTC瞬时点按Asia Shanghai转换为当地民用时间', () {
      final snapshot = DivinationCalendarSnapshot.chinaCivil(
        DateTime.utc(2024, 2, 5, 4),
      );

      expect(snapshot.civilTime.hour, 12);
      expect(snapshot.timezoneOffsetMinutes, 480);
      expect(snapshot.lunarDay, 26);
      expect(snapshot.hourBranch, '午');
    });
  });
}
