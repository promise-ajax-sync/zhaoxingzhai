/// 中国夏令时（1986-1991）检测与校正
/// 
/// 中国历史钟表时间修正属于公共日历能力，供八字、紫微、真太阳时等统一复用。
library;

/// 中国夏令时检测结果
class ChinaDstCheckResult {
  /// 输入的钟表时刻是否处于夏令时期间
  final bool inDst;

  /// 应施加的分钟修正（夏令时内为 -60，否则 0）
  final int offsetMinutes;

  /// 是否落在结束日 01:00-02:00 的重复时段
  final bool ambiguous;

  /// 是否落在开始日 02:00-03:00 的不存在时段
  final bool nonexistent;

  const ChinaDstCheckResult({
    required this.inDst,
    required this.offsetMinutes,
    required this.ambiguous,
    required this.nonexistent,
  });
}

/// 夏令时边界 [year, month, day, hour]
typedef _DstBoundary = (int, int, int, int);

/// 夏令时区间
typedef _DstRange = ({_DstBoundary start, _DstBoundary end});

/// 中国实施夏令时的年份
const chinaDstYears = [1986, 1987, 1988, 1989, 1990, 1991];

/// 钟表时刻区间 [start, end)
const _chinaDstRanges = <_DstRange>[
  (start: (1986, 5, 4, 3), end: (1986, 9, 14, 2)),
  (start: (1987, 4, 12, 3), end: (1987, 9, 13, 2)),
  (start: (1988, 4, 10, 3), end: (1988, 9, 11, 2)),
  (start: (1989, 4, 16, 3), end: (1989, 9, 17, 2)),
  (start: (1990, 4, 15, 3), end: (1990, 9, 16, 2)),
  (start: (1991, 4, 14, 3), end: (1991, 9, 15, 2)),
];

const _hourMs = 3600000;

int _toUtcMs(int year, int month, int day, int hour, [int minute = 0]) {
  return DateTime.utc(year, month, day, hour, minute).millisecondsSinceEpoch;
}

/// 检测某个中国历史钟表时刻是否处于夏令时期间
ChinaDstCheckResult checkChinaDst(
  int year,
  int month,
  int day,
  int hour, [
  int minute = 0,
]) {
  const none = ChinaDstCheckResult(
    inDst: false,
    offsetMinutes: 0,
    ambiguous: false,
    nonexistent: false,
  );

  if (!chinaDstYears.contains(year)) {
    return none;
  }

  final t = _toUtcMs(year, month, day, hour, minute);

  for (final range in _chinaDstRanges) {
    if (range.start.$1 != year) continue;

    final startMs = _toUtcMs(range.start.$1, range.start.$2, range.start.$3, range.start.$4);
    final endMs = _toUtcMs(range.end.$1, range.end.$2, range.end.$3, range.end.$4);

    // 不存在时段：开始前 1 小时
    if (t >= startMs - _hourMs && t < startMs) {
      return const ChinaDstCheckResult(
        inDst: true,
        offsetMinutes: -60,
        ambiguous: false,
        nonexistent: true,
      );
    }

    // 夏令时区间
    if (t >= startMs && t < endMs) {
      return ChinaDstCheckResult(
        inDst: true,
        offsetMinutes: -60,
        ambiguous: t >= endMs - _hourMs, // 结束前 1 小时是重复时段
        nonexistent: false,
      );
    }
  }

  return none;
}

/// 按日判断日期是否与中国历史夏令时区间有交集
bool isDateInChinaDstRange(int year, int month, int day) {
  if (!chinaDstYears.contains(year)) {
    return false;
  }

  final dayStart = _toUtcMs(year, month, day, 0);
  final dayEnd = dayStart + 24 * _hourMs;

  for (final range in _chinaDstRanges) {
    if (range.start.$1 != year) continue;

    final startMs = _toUtcMs(range.start.$1, range.start.$2, range.start.$3, 2);
    final endMs = _toUtcMs(range.end.$1, range.end.$2, range.end.$3, range.end.$4);

    if (dayStart < endMs && dayEnd > startMs) {
      return true;
    }
  }

  return false;
}
