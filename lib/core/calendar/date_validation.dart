/// 日期验证工具
///
/// 提供日期有效性检查、时间戳创建等基础功能
library;

/// 验证钟表时间是否有效（24小时制）
bool isValidClockTime(int hour, int minute, int second) {
  return hour >= 0 &&
      hour <= 23 &&
      minute >= 0 &&
      minute <= 59 &&
      second >= 0 &&
      second <= 59;
}

/// 获取公历月份的天数
int daysInGregorianMonth(int year, int month) {
  if (month < 1 || month > 12) {
    throw ArgumentError('月份必须在 1-12 之间');
  }

  const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  if (month == 2 && isLeapYear(year)) {
    return 29;
  }

  return daysInMonth[month - 1];
}

/// 判断是否为闰年
bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

/// 创建 UTC 时间戳（毫秒）
/// month 参数为 0-11（JavaScript 风格）
int createUtcTimestamp(
  int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
) {
  return DateTime.utc(
    year,
    month + 1,
    day,
    hour,
    minute,
    second,
  ).millisecondsSinceEpoch;
}

/// 验证公历日期
void validateSolarDate(int year, int month, int day) {
  if (year < 1900 || year > 2100) {
    throw ArgumentError('年份需在 1900-2100 之间。');
  }
  if (month < 1 || month > 12) {
    throw ArgumentError('月份需在 1-12 之间。');
  }
  if (day < 1) {
    throw ArgumentError('日期不能小于 1。');
  }

  final maxDay = daysInGregorianMonth(year, month);
  if (day > maxDay) {
    throw ArgumentError('日期需在 1-$maxDay 之间。');
  }
}

/// 验证时间部分
void validateTimePart(int hour, int minute, int second) {
  if (hour < 0 || hour > 23) {
    throw ArgumentError('小时需在 0-23 之间。');
  }
  if (minute < 0 || minute > 59) {
    throw ArgumentError('分钟需在 0-59 之间。');
  }
  if (second < 0 || second > 59) {
    throw ArgumentError('秒需在 0-59 之间。');
  }
}

/// 获取出生日期验证消息（如果有效返回 null）
String? getBirthDateValidationMessage({
  required int year,
  required int month,
  required int day,
  required String dateType, // 'solar' | 'lunar'
  bool? isLeapMonth,
}) {
  if (dateType != 'solar' && dateType != 'lunar') {
    return 'dateType 必须是 solar 或 lunar。';
  }

  if (year < 1900 || year > 2100) {
    return '年份需在 1900-2100 之间。';
  }

  if (month < 1 || month > 12) {
    return '月份需在 1-12 之间。';
  }

  if (day < 1) {
    return '日期不能小于 1。';
  }

  if (dateType == 'solar') {
    try {
      validateSolarDate(year, month, day);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // 农历验证需要 lunar 库
  // 这里先简化处理
  if (day > 30) {
    return '农历日期不能大于 30。';
  }

  return null;
}

/// 获取公历月份的天数（别名）
int daysInSolarMonth(int year, int month) => daysInGregorianMonth(year, month);
