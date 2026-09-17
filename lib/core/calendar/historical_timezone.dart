/// IANA 历史时区解析
///
/// 通过 Dart 的 DateTime timezone 功能解析当地钟表时刻的历史 UTC 偏移，
/// 并识别 DST 歧义与缺失时刻。
library;

import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'date_validation.dart';

bool _timezoneDatabaseInitialized = false;

void _ensureTimezoneDatabase() {
  if (_timezoneDatabaseInitialized) return;
  timezone_data.initializeTimeZones();
  _timezoneDatabaseInitialized = true;
}

timezone.Location _getLocation(String timeZoneId) {
  _ensureTimezoneDatabase();
  try {
    return timezone.getLocation(timeZoneId);
  } on timezone.LocationNotFoundException {
    throw ArgumentError('无法识别 IANA 时区 $timeZoneId。');
  }
}

double _offsetHours(Duration offset) =>
    double.parse((offset.inSeconds / 3600).toStringAsFixed(6));

bool _sameWallClock(timezone.TZDateTime value, HistoricalTimezoneInput input) {
  return value.year == input.year &&
      value.month == input.month &&
      value.day == input.day &&
      value.hour == input.hour &&
      value.minute == input.minute &&
      value.second == input.second;
}

/// 历史时区输入
class HistoricalTimezoneInput {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final String timeZoneId;
  final double? fixedOffsetHours;

  const HistoricalTimezoneInput({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.timeZoneId,
    this.fixedOffsetHours,
  });
}

/// 历史时区证据
class HistoricalTimezoneEvidence {
  final String key;
  final String timeZoneId;
  final String database;
  final String status; // 'unique' | 'ambiguous'
  final int selectedUtcTimestamp;
  final String selectedUtcDateTime;
  final double resolvedOffsetHours;
  final List<String> possibleUtcDateTimes;
  final List<double> possibleOffsetsHours;
  final double? fixedOffsetHours;
  final bool ambiguityResolvedByFixedOffset;
  final bool offsetConflict;
  final List<String> diagnostics;
  final String source;
  final String promptText;

  const HistoricalTimezoneEvidence({
    required this.key,
    required this.timeZoneId,
    required this.database,
    required this.status,
    required this.selectedUtcTimestamp,
    required this.selectedUtcDateTime,
    required this.resolvedOffsetHours,
    required this.possibleUtcDateTimes,
    required this.possibleOffsetsHours,
    this.fixedOffsetHours,
    required this.ambiguityResolvedByFixedOffset,
    required this.offsetConflict,
    required this.diagnostics,
    required this.source,
    required this.promptText,
  });
}

/// 读取指定真实瞬时点在时区中的历史 UTC 偏移（小时）
///
double getHistoricalTimezoneOffsetAt(DateTime date, String timeZoneId) {
  if (timeZoneId.trim().isEmpty) {
    throw ArgumentError('IANA 时区名不能为空。');
  }

  final location = _getLocation(timeZoneId.trim());
  final local = timezone.TZDateTime.from(date.toUtc(), location);
  return _offsetHours(local.timeZoneOffset);
}

/// 解析历史时区
///
HistoricalTimezoneEvidence resolveHistoricalTimezone(
  HistoricalTimezoneInput input,
) {
  if (input.timeZoneId.trim().isEmpty) {
    throw ArgumentError('IANA 时区名不能为空。');
  }

  final timeZoneId = input.timeZoneId.trim();
  final location = _getLocation(timeZoneId);

  // 先把当地钟表字段表示成 UTC 数值，再使用候选历史偏移反推真实 UTC。
  final wallTimestamp = createUtcTimestamp(
    input.year,
    input.month - 1,
    input.day,
    input.hour,
    input.minute,
    input.second,
  );

  final wallClockDateTime =
      '${input.year.toString().padLeft(4, '0')}-'
      '${input.month.toString().padLeft(2, '0')}-'
      '${input.day.toString().padLeft(2, '0')} '
      '${input.hour.toString().padLeft(2, '0')}:'
      '${input.minute.toString().padLeft(2, '0')}:'
      '${input.second.toString().padLeft(2, '0')}';

  final candidateOffsets = <double>{};
  final wallReference = DateTime.fromMillisecondsSinceEpoch(
    wallTimestamp,
    isUtc: true,
  );
  for (var hours = -36; hours <= 36; hours++) {
    final sampled = timezone.TZDateTime.from(
      wallReference.add(Duration(hours: hours)),
      location,
    );
    candidateOffsets.add(_offsetHours(sampled.timeZoneOffset));
  }

  final matches =
      candidateOffsets
          .map((offset) {
            final timestamp = wallTimestamp - (offset * 3600000).round();
            final utc = DateTime.fromMillisecondsSinceEpoch(
              timestamp,
              isUtc: true,
            );
            final local = timezone.TZDateTime.from(utc, location);
            return (timestamp: timestamp, offset: offset, local: local);
          })
          .where((candidate) => _sameWallClock(candidate.local, input))
          .toList()
        ..sort((first, second) => first.timestamp.compareTo(second.timestamp));

  if (matches.isEmpty) {
    throw ArgumentError(
      '$timeZoneId 的当地钟表时间 $wallClockDateTime 不存在，通常由夏令时跳时造成。',
    );
  }

  ({int timestamp, double offset, timezone.TZDateTime local})? fixedOffsetMatch;
  if (input.fixedOffsetHours != null) {
    for (final candidate in matches) {
      if ((candidate.offset - input.fixedOffsetHours!).abs() <= 1e-6) {
        fixedOffsetMatch = candidate;
        break;
      }
    }
  }
  final selected = fixedOffsetMatch ?? matches.first;
  final offset = selected.offset;
  final utcTimestamp = selected.timestamp;
  final utcDateTime = DateTime.fromMillisecondsSinceEpoch(
    utcTimestamp,
    isUtc: true,
  ).toIso8601String();

  final offsetConflict =
      input.fixedOffsetHours != null && fixedOffsetMatch == null;
  final ambiguityResolvedByFixedOffset =
      matches.length > 1 && fixedOffsetMatch != null;

  final diagnostics = <String>[
    if (matches.length > 1)
      ambiguityResolvedByFixedOffset
          ? '该当地时刻因夏令时回拨对应 ${matches.length} 个 UTC 时刻；已按固定偏移选择 $utcDateTime。'
          : '该当地时刻因夏令时回拨对应 ${matches.length} 个 UTC 时刻；未提供可用于消歧的固定偏移，默认选择较早的 $utcDateTime。'
    else
      '该当地时刻在当前 IANA 时区数据库中只有一个 UTC 对应时刻。',
    if (offsetConflict)
      '输入固定偏移 UTC${input.fixedOffsetHours! >= 0 ? '+' : ''}${input.fixedOffsetHours} '
          '与历史偏移 UTC${offset >= 0 ? '+' : ''}$offset 不一致。',
  ];

  const source = 'IANA 时区规则由 Dart timezone 数据库解析；不使用设备当前时区反推历史偏移';

  return HistoricalTimezoneEvidence(
    key: 'historical-timezone:$timeZoneId:$wallClockDateTime',
    timeZoneId: timeZoneId,
    database: 'Dart timezone 内置 IANA Time Zone Database',
    status: matches.length > 1 ? 'ambiguous' : 'unique',
    selectedUtcTimestamp: utcTimestamp,
    selectedUtcDateTime: utcDateTime,
    resolvedOffsetHours: offset,
    possibleUtcDateTimes: matches
        .map(
          (candidate) => DateTime.fromMillisecondsSinceEpoch(
            candidate.timestamp,
            isUtc: true,
          ).toIso8601String(),
        )
        .toList(),
    possibleOffsetsHours: matches.map((candidate) => candidate.offset).toList(),
    fixedOffsetHours: input.fixedOffsetHours,
    ambiguityResolvedByFixedOffset: ambiguityResolvedByFixedOffset,
    offsetConflict: offsetConflict,
    diagnostics: diagnostics,
    source: source,
    promptText:
        '历史时区证据：$timeZoneId 的当地钟表时间$wallClockDateTime映射为 UTC $utcDateTime，'
        '历史偏移 UTC${offset >= 0 ? '+' : ''}$offset。来源：$source。',
  );
}
