/// 真太阳时转换
///
/// 真太阳时计算工具。
/// 统一处理公历/农历、闰月、时区、中国历史夏令时、跨日与时辰索引
library;

import 'dart:math' as math;

import 'civil_time.dart';
import 'china_dst.dart';
import 'date_utils.dart';
import 'date_validation.dart';

/// 公历日期时间字段（与 CivilDateTimeParts 相同）
typedef SolarDateTimeParts = CivilDateTimeParts;

/// 真太阳时结果
class TrueSolarTimeResult {
  final SolarDateTimeParts correctedTime;
  final double longitudeCorrectionMinutes;
  final double equationOfTimeMinutes;
  final double totalCorrectionMinutes;

  const TrueSolarTimeResult({
    required this.correctedTime,
    required this.longitudeCorrectionMinutes,
    required this.equationOfTimeMinutes,
    required this.totalCorrectionMinutes,
  });
}

/// 真太阳时转换输入
class TrueSolarTimeConversionInput {
  /// 不带时区偏移的当地钟表时间，如 1990-05-15T10:30:00
  final String localDateTime;

  /// 出生地或观测地经度，东经为正、西经为负
  final double longitude;

  /// 当地标准时区，默认 UTC+8；支持小数时区
  final double? timezone;

  /// IANA 历史时区，如 America/New_York；用于按当地日期解析历史 UTC 偏移
  final String? timeZoneId;

  /// 是否按中国 1986-1991 历史规则自动还原夏令时，默认 false
  final bool? applyChinaDst;

  const TrueSolarTimeConversionInput({
    required this.localDateTime,
    required this.longitude,
    this.timezone,
    this.timeZoneId,
    this.applyChinaDst,
  });
}

/// 真太阳时转换结果
class TrueSolarTimeConversionResult extends TrueSolarTimeResult {
  final SolarDateTimeParts clockTime;
  final String clockDateTime;
  final SolarDateTimeParts standardTime;
  final String standardDateTime;
  final String correctedDateTime;
  final double longitude;
  final double timezone;
  final String? timeZoneId;
  final double standardMeridian;
  final bool crossesDate;
  final ChinaDstResult chinaDst;
  final ShichenResult shichen;

  const TrueSolarTimeConversionResult({
    required super.correctedTime,
    required super.longitudeCorrectionMinutes,
    required super.equationOfTimeMinutes,
    required super.totalCorrectionMinutes,
    required this.clockTime,
    required this.clockDateTime,
    required this.standardTime,
    required this.standardDateTime,
    required this.correctedDateTime,
    required this.longitude,
    required this.timezone,
    this.timeZoneId,
    required this.standardMeridian,
    required this.crossesDate,
    required this.chinaDst,
    required this.shichen,
  });
}

/// 中国夏令时结果
class ChinaDstResult {
  final bool inDst;
  final int offsetMinutes;
  final bool ambiguous;
  final bool nonexistent;
  final bool requested;
  final bool applied;

  const ChinaDstResult({
    required this.inDst,
    required this.offsetMinutes,
    required this.ambiguous,
    required this.nonexistent,
    required this.requested,
    required this.applied,
  });
}

/// 时辰结果
class ShichenResult {
  final int index;
  final String branch;
  final String name;

  const ShichenResult({
    required this.index,
    required this.branch,
    required this.name,
  });
}

/// 出生历法钟表时间输入
class BirthCalendarClockTimeInput {
  final String dateType; // 'solar' | 'lunar'
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final bool isLeapMonth;

  const BirthCalendarClockTimeInput({
    required this.dateType,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    this.second = 0,
    this.isLeapMonth = false,
  });
}

/// 真太阳出生时间输入
class TrueSolarBirthTimeInput extends BirthCalendarClockTimeInput {
  final double longitude;
  final double? timezone;
  final String? timeZoneId;
  final bool? applyChinaDst;

  const TrueSolarBirthTimeInput({
    required super.dateType,
    required super.year,
    required super.month,
    required super.day,
    required super.hour,
    required super.minute,
    super.second,
    super.isLeapMonth,
    required this.longitude,
    this.timezone,
    this.timeZoneId,
    this.applyChinaDst,
  });
}

/// 真太阳出生时间结果
class TrueSolarBirthTimeResult extends TrueSolarTimeConversionResult {
  final String inputDateType;
  final bool isLeapMonth;
  final SolarDateTimeParts solarClockTime;
  final String solarClockDateTime;
  final int timeIndex;

  const TrueSolarBirthTimeResult({
    required super.correctedTime,
    required super.longitudeCorrectionMinutes,
    required super.equationOfTimeMinutes,
    required super.totalCorrectionMinutes,
    required super.clockTime,
    required super.clockDateTime,
    required super.standardTime,
    required super.standardDateTime,
    required super.correctedDateTime,
    required super.longitude,
    required super.timezone,
    super.timeZoneId,
    required super.standardMeridian,
    required super.crossesDate,
    required super.chinaDst,
    required super.shichen,
    required this.inputDateType,
    required this.isLeapMonth,
    required this.solarClockTime,
    required this.solarClockDateTime,
    required this.timeIndex,
  });
}

// ==================== 工具函数 ====================

final _localDateTimePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?$',
);

String _pad(int value) => value.toString().padLeft(2, '0');

String formatSolarDateTimeParts(SolarDateTimeParts value) {
  return '${value.year.toString().padLeft(4, '0')}-${_pad(value.month)}-${_pad(value.day)}'
      'T${_pad(value.hour)}:${_pad(value.minute)}:${_pad(value.second)}';
}

SolarDateTimeParts _toDateTimeParts(DateTime date) {
  return CivilDateTimeParts(
    year: date.year,
    month: date.month,
    day: date.day,
    hour: date.hour,
    minute: date.minute,
    second: date.second,
  );
}

SolarDateTimeParts _shiftDateTime(SolarDateTimeParts value, int offsetMinutes) {
  final date = DateTime.utc(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
  ).add(Duration(minutes: offsetMinutes));
  return _toDateTimeParts(date);
}

/// 解析本地日期时间字符串
SolarDateTimeParts parseLocalDateTime(String value) {
  final match = _localDateTimePattern.firstMatch(value.trim());
  if (match == null) {
    throw ArgumentError(
      'localDateTime 需使用 YYYY-MM-DDTHH:mm 或 YYYY-MM-DDTHH:mm:ss 格式，且不要附带时区偏移。',
    );
  }

  final result = CivilDateTimeParts(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
    hour: int.parse(match.group(4)!),
    minute: int.parse(match.group(5)!),
    second: match.group(6) != null ? int.parse(match.group(6)!) : 0,
  );

  validateSolarDate(result.year, result.month, result.day);
  validateTimePart(result.hour, result.minute, result.second);

  return result;
}

/// 获取年内日序
int _getDayOfYear(int year, int month, int day) {
  final current = DateTime.utc(year, month, day);
  final start = DateTime.utc(year, 1, 1);
  return current.difference(start).inDays + 1;
}

/// 计算均时差（分钟）
double calculateEquationOfTimeMinutes(int year, int month, int day) {
  validateSolarDate(year, month, day);
  final dayOfYear = _getDayOfYear(year, month, day);
  final angle = (2 * math.pi * (dayOfYear - 81)) / 364;
  return 9.87 * math.sin(2 * angle) -
      7.53 * math.cos(angle) -
      1.5 * math.sin(angle);
}

/// 计算真太阳时
TrueSolarTimeResult calculateTrueSolarTime(
  SolarDateTimeParts standardTime,
  double longitude, [
  double standardMeridian = 120,
]) {
  validateSolarDate(standardTime.year, standardTime.month, standardTime.day);
  validateTimePart(standardTime.hour, standardTime.minute, standardTime.second);

  if (!longitude.isFinite || longitude < -180 || longitude > 180) {
    throw ArgumentError('经度需在 -180 到 180 之间。');
  }
  if (!standardMeridian.isFinite ||
      standardMeridian < -180 ||
      standardMeridian > 210) {
    throw ArgumentError('标准经线需在 -180 到 210 之间。');
  }

  final equationOfTimeMinutes = calculateEquationOfTimeMinutes(
    standardTime.year,
    standardTime.month,
    standardTime.day,
  );
  final longitudeCorrectionMinutes = (longitude - standardMeridian) * 4;
  final totalCorrectionMinutes =
      equationOfTimeMinutes + longitudeCorrectionMinutes;

  final correctedDate = DateTime.utc(
    standardTime.year,
    standardTime.month,
    standardTime.day,
    standardTime.hour,
    standardTime.minute,
    standardTime.second,
  ).add(Duration(milliseconds: (totalCorrectionMinutes * 60000).round()));

  return TrueSolarTimeResult(
    correctedTime: _toDateTimeParts(correctedDate),
    longitudeCorrectionMinutes: longitudeCorrectionMinutes,
    equationOfTimeMinutes: equationOfTimeMinutes,
    totalCorrectionMinutes: totalCorrectionMinutes,
  );
}

/// 面向 API/MCP 的便捷真太阳时换算入口
TrueSolarTimeConversionResult convertTrueSolarTime(
  TrueSolarTimeConversionInput input,
) {
  final clockTime = parseLocalDateTime(input.localDateTime);

  final civilTime = resolveCivilTime(
    CivilTimeResolutionInput(
      year: clockTime.year,
      month: clockTime.month,
      day: clockTime.day,
      hour: clockTime.hour,
      minute: clockTime.minute,
      second: clockTime.second,
      timezone: input.timezone,
      timeZoneId: input.timeZoneId,
    ),
    CivilTimeResolutionOptions(defaultTimezone: defaultChinaTimezoneHours),
  );

  final timeZoneId = civilTime.timeZoneId;
  final timezone = civilTime.timezone;

  if (timeZoneId != null && input.applyChinaDst == true) {
    throw ArgumentError('timeZoneId 已包含历史夏令时规则，不能同时启用 applyChinaDst。');
  }

  final requestedChinaDst = input.applyChinaDst ?? false;
  final chinaDstCheck = requestedChinaDst
      ? checkChinaDst(
          clockTime.year,
          clockTime.month,
          clockTime.day,
          clockTime.hour,
          clockTime.minute,
        )
      : const ChinaDstCheckResult(
          inDst: false,
          offsetMinutes: 0,
          ambiguous: false,
          nonexistent: false,
        );

  if (requestedChinaDst && chinaDstCheck.nonexistent) {
    throw ArgumentError('该中国历史钟表时间处于夏令时跳时缺口，实际并不存在。');
  }

  if (requestedChinaDst && chinaDstCheck.ambiguous) {
    throw ArgumentError(
      '该中国历史钟表时间处于夏令时回拨重复时段，'
      '请改用 timeZoneId=Asia/Shanghai 并提供 timezone 固定偏移消歧。',
    );
  }

  final chinaDstApplied = requestedChinaDst && chinaDstCheck.inDst;
  final standardTime = chinaDstApplied
      ? _shiftDateTime(clockTime, chinaDstCheck.offsetMinutes)
      : clockTime;

  final standardMeridian = timezone * 15;
  final result = calculateTrueSolarTime(
    standardTime,
    input.longitude,
    standardMeridian,
  );

  final shichen = getShichenFromClock(
    result.correctedTime.hour,
    result.correctedTime.minute,
  );
  if (shichen == null) {
    throw ArgumentError('无法根据校正后的真太阳时确定时辰。');
  }

  final clockDateTime = formatSolarDateTimeParts(clockTime);
  final standardDateTime = formatSolarDateTimeParts(standardTime);
  final correctedDateTime = formatSolarDateTimeParts(result.correctedTime);

  final crossesDate =
      clockTime.year != result.correctedTime.year ||
      clockTime.month != result.correctedTime.month ||
      clockTime.day != result.correctedTime.day;

  final chinaDst = ChinaDstResult(
    inDst: chinaDstCheck.inDst,
    offsetMinutes: chinaDstCheck.offsetMinutes,
    ambiguous: chinaDstCheck.ambiguous,
    nonexistent: chinaDstCheck.nonexistent,
    requested: requestedChinaDst,
    applied: chinaDstApplied,
  );

  final shichenResult = ShichenResult(
    index: shichen.index,
    branch: shichen.branch,
    name: shichen.name,
  );

  return TrueSolarTimeConversionResult(
    correctedTime: result.correctedTime,
    longitudeCorrectionMinutes: result.longitudeCorrectionMinutes,
    equationOfTimeMinutes: result.equationOfTimeMinutes,
    totalCorrectionMinutes: result.totalCorrectionMinutes,
    clockTime: clockTime,
    clockDateTime: clockDateTime,
    standardTime: standardTime,
    standardDateTime: standardDateTime,
    correctedDateTime: correctedDateTime,
    longitude: input.longitude,
    timezone: timezone,
    timeZoneId: timeZoneId,
    standardMeridian: standardMeridian,
    crossesDate: crossesDate,
    chinaDst: chinaDst,
    shichen: shichenResult,
  );
}
