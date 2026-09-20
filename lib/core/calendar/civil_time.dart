/// 民用时间统一解析
///
/// 统一处理当地钟表时间、固定 UTC 偏移与 IANA 历史时区，
/// 供真太阳时、星盘和天文时间共用。
library;

import 'date_validation.dart';
import 'historical_timezone.dart';

const minFixedTimezoneHours = -12.0;
const maxFixedTimezoneHours = 14.0;
const defaultChinaTimezoneHours = 8.0;
const defaultChinaTimeZoneId = 'Asia/Shanghai';

/// 民用日期时间字段
class CivilDateTimeParts {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;

  const CivilDateTimeParts({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
  });

  @override
  String toString() => formatCivilDateTime(this);
}

/// 民用时区输入
class CivilTimeZoneInput {
  /// 已确认的法定 UTC 偏移；有 IANA 时区时仅用于重复时刻消歧和一致性核验
  final double? timezone;

  /// IANA 历史时区，例如 Asia/Shanghai、America/New_York
  final String? timeZoneId;

  const CivilTimeZoneInput({this.timezone, this.timeZoneId});
}

/// 民用时间解析输入
class CivilTimeResolutionInput {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final double? timezone;
  final String? timeZoneId;

  const CivilTimeResolutionInput({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    this.timezone,
    this.timeZoneId,
  });
}

/// 民用时间解析选项
class CivilTimeResolutionOptions {
  /// 没有提供任何时区时使用的固定偏移；省略表示必须显式提供时区
  final double? defaultTimezone;

  const CivilTimeResolutionOptions({this.defaultTimezone});
}

/// 民用时间解析结果
class CivilTimeResolution {
  final CivilDateTimeParts localTime;
  final String localDateTime;
  final double timezone;
  final String? timeZoneId;
  final HistoricalTimezoneEvidence? timezoneEvidence;
  final String
  timezoneSource; // 'default-fixed-offset' | 'fixed-offset' | 'iana-time-zone'
  final int utcTimestamp;
  final String utcDateTime;

  const CivilTimeResolution({
    required this.localTime,
    required this.localDateTime,
    required this.timezone,
    this.timeZoneId,
    this.timezoneEvidence,
    required this.timezoneSource,
    required this.utcTimestamp,
    required this.utcDateTime,
  });
}

String _pad(int value) => value.toString().padLeft(2, '0');

String formatCivilDateTime(CivilDateTimeParts value) {
  return '${value.year.toString().padLeft(4, '0')}-${_pad(value.month)}-${_pad(value.day)}'
      'T${_pad(value.hour)}:${_pad(value.minute)}:${_pad(value.second)}';
}

/// 将固定 UTC 偏移格式化为 ISO 8601 后缀
String formatFixedTimezoneOffset(double timezone) {
  assertFixedTimezoneHours(timezone);
  final totalSeconds = (timezone.abs() * 3600).round();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final sign = timezone >= 0 ? '+' : '-';
  return '$sign${_pad(hours)}:${_pad(minutes)}${seconds > 0 ? ':${_pad(seconds)}' : ''}';
}

void assertFixedTimezoneHours(double value, [String label = 'timezone']) {
  if (!value.isFinite ||
      value < minFixedTimezoneHours ||
      value > maxFixedTimezoneHours) {
    throw ArgumentError(
      '$label 需在 UTC$minFixedTimezoneHours 到 UTC+$maxFixedTimezoneHours 之间。',
    );
  }
}

/// 将真实瞬时点按固定 UTC 偏移读取为当地钟表字段
CivilDateTimeParts getCivilDateTimeAtFixedOffset(
  DateTime referenceDate, [
  double timezone = defaultChinaTimezoneHours,
]) {
  assertFixedTimezoneHours(timezone);
  final shifted = referenceDate.add(
    Duration(milliseconds: (timezone * 3600000).round()),
  );
  return CivilDateTimeParts(
    year: shifted.year,
    month: shifted.month,
    day: shifted.day,
    hour: shifted.hour,
    minute: shifted.minute,
    second: shifted.second,
  );
}

void _validateCivilDateTime(CivilDateTimeParts input) {
  final maxDay = daysInGregorianMonth(input.year, input.month);
  if (input.day < 1 || input.day > maxDay) {
    throw ArgumentError('${input.year}年${input.month}月不存在第${input.day}日。');
  }
  if (!isValidClockTime(input.hour, input.minute, input.second)) {
    throw ArgumentError('当地钟表时间需使用有效的 24 小时时分秒。');
  }
}

String? _normalizeTimeZoneId(String? value) {
  if (value == null) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError('IANA 时区名不能为空。');
  }
  return normalized;
}

/// 将当地钟表时间解析为唯一 UTC 时刻
///
/// 统一口径：IANA 时区优先；同时提供 timezone 时只用于回拨消歧和一致性核验；
/// 不存在的当地时刻、未消解的重复时刻及固定偏移冲突都拒绝继续计算。
CivilTimeResolution resolveCivilTime(
  CivilTimeResolutionInput input, [
  CivilTimeResolutionOptions options = const CivilTimeResolutionOptions(),
]) {
  final localTime = CivilDateTimeParts(
    year: input.year,
    month: input.month,
    day: input.day,
    hour: input.hour,
    minute: input.minute,
    second: input.second,
  );

  _validateCivilDateTime(localTime);

  if (input.timezone != null) {
    assertFixedTimezoneHours(input.timezone!);
  }
  if (options.defaultTimezone != null) {
    assertFixedTimezoneHours(options.defaultTimezone!, '默认 timezone');
  }

  final timeZoneId = _normalizeTimeZoneId(input.timeZoneId);
  final timezoneEvidence = timeZoneId != null
      ? resolveHistoricalTimezone(
          HistoricalTimezoneInput(
            year: localTime.year,
            month: localTime.month,
            day: localTime.day,
            hour: localTime.hour,
            minute: localTime.minute,
            second: localTime.second,
            timeZoneId: timeZoneId,
            fixedOffsetHours: input.timezone,
          ),
        )
      : null;

  if (timezoneEvidence?.status == 'ambiguous' && input.timezone == null) {
    throw ArgumentError(
      '$timeZoneId 的当地钟表时间 ${formatCivilDateTime(localTime)} 存在夏令时回拨歧义，'
      '请同时提供与原始记录一致的 timezone 固定偏移。',
    );
  }

  if (timezoneEvidence?.offsetConflict == true) {
    throw ArgumentError(
      'timezone 固定偏移 UTC${input.timezone! >= 0 ? '+' : ''}${input.timezone} '
      '与 $timeZoneId 在该当地时刻的历史偏移不一致。',
    );
  }

  final timezone =
      timezoneEvidence?.resolvedOffsetHours ??
      input.timezone ??
      options.defaultTimezone;

  if (timezone == null) {
    throw ArgumentError('timezone 与 timeZoneId 至少需要提供一项。');
  }

  final wallTimestamp = createUtcTimestamp(
    localTime.year,
    localTime.month - 1,
    localTime.day,
    localTime.hour,
    localTime.minute,
    localTime.second,
  );

  final utcTimestamp =
      timezoneEvidence?.selectedUtcTimestamp ??
      wallTimestamp - (timezone * 3600000).round();

  return CivilTimeResolution(
    localTime: localTime,
    localDateTime: formatCivilDateTime(localTime),
    timezone: timezone,
    timeZoneId: timeZoneId,
    timezoneEvidence: timezoneEvidence,
    timezoneSource: timeZoneId != null
        ? 'iana-time-zone'
        : input.timezone != null
        ? 'fixed-offset'
        : 'default-fixed-offset',
    utcTimestamp: utcTimestamp,
    utcDateTime: DateTime.fromMillisecondsSinceEpoch(
      utcTimestamp,
      isUtc: true,
    ).toIso8601String(),
  );
}
