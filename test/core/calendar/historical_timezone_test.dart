import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/calendar/historical_timezone.dart';

void main() {
  group('IANA 历史时区', () {
    test('上海时区应得到唯一 UTC+8 映射', () {
      final result = resolveHistoricalTimezone(
        const HistoricalTimezoneInput(
          year: 2025,
          month: 1,
          day: 29,
          hour: 0,
          minute: 30,
          second: 0,
          timeZoneId: 'Asia/Shanghai',
        ),
      );

      expect(result.status, 'unique');
      expect(result.resolvedOffsetHours, 8);
      expect(result.selectedUtcDateTime, '2025-01-28T16:30:00.000Z');
    });

    test('纽约秋季回拨应识别两个合法 UTC 时刻', () {
      final result = resolveHistoricalTimezone(
        const HistoricalTimezoneInput(
          year: 2024,
          month: 11,
          day: 3,
          hour: 1,
          minute: 30,
          second: 0,
          timeZoneId: 'America/New_York',
        ),
      );

      expect(result.status, 'ambiguous');
      expect(result.possibleOffsetsHours, containsAll([-4, -5]));
      expect(result.possibleUtcDateTimes, hasLength(2));
      expect(result.resolvedOffsetHours, -4);
    });

    test('固定偏移可以消解纽约回拨歧义', () {
      final result = resolveHistoricalTimezone(
        const HistoricalTimezoneInput(
          year: 2024,
          month: 11,
          day: 3,
          hour: 1,
          minute: 30,
          second: 0,
          timeZoneId: 'America/New_York',
          fixedOffsetHours: -5,
        ),
      );

      expect(result.ambiguityResolvedByFixedOffset, isTrue);
      expect(result.resolvedOffsetHours, -5);
      expect(result.selectedUtcDateTime, '2024-11-03T06:30:00.000Z');
    });

    test('纽约春季跳时中的不存在时刻应拒绝', () {
      expect(
        () => resolveHistoricalTimezone(
          const HistoricalTimezoneInput(
            year: 2024,
            month: 3,
            day: 10,
            hour: 2,
            minute: 30,
            second: 0,
            timeZoneId: 'America/New_York',
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
