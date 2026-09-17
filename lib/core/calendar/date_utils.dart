/// 时辰（十二时辰）工具
///
/// 完整移植自 mingyu-core/src/calendar/dateUtils.ts
library;

/// 时辰信息
class ShichenPeriod {
  final int index;
  final String branch;      // 地支
  final String name;        // 时辰名称
  final String range;       // 时间范围
  final int hour;           // 代表小时（时段中点）
  final int minute;         // 代表分钟（时段中点）

  const ShichenPeriod({
    required this.index,
    required this.branch,
    required this.name,
    required this.range,
    required this.hour,
    required this.minute,
  });
}

/// 十二时辰目录
/// 子时按排盘口径拆成早子时（00:00-01:00）与晚子时（23:00-24:00）
const shichenPeriods = [
  ShichenPeriod(index: 0, branch: '子', name: '早子时', range: '00:00-01:00', hour: 0, minute: 30),
  ShichenPeriod(index: 1, branch: '丑', name: '丑时', range: '01:00-03:00', hour: 2, minute: 0),
  ShichenPeriod(index: 2, branch: '寅', name: '寅时', range: '03:00-05:00', hour: 4, minute: 0),
  ShichenPeriod(index: 3, branch: '卯', name: '卯时', range: '05:00-07:00', hour: 6, minute: 0),
  ShichenPeriod(index: 4, branch: '辰', name: '辰时', range: '07:00-09:00', hour: 8, minute: 0),
  ShichenPeriod(index: 5, branch: '巳', name: '巳时', range: '09:00-11:00', hour: 10, minute: 0),
  ShichenPeriod(index: 6, branch: '午', name: '午时', range: '11:00-13:00', hour: 12, minute: 0),
  ShichenPeriod(index: 7, branch: '未', name: '未时', range: '13:00-15:00', hour: 14, minute: 0),
  ShichenPeriod(index: 8, branch: '申', name: '申时', range: '15:00-17:00', hour: 16, minute: 0),
  ShichenPeriod(index: 9, branch: '酉', name: '酉时', range: '17:00-19:00', hour: 18, minute: 0),
  ShichenPeriod(index: 10, branch: '戌', name: '戌时', range: '19:00-21:00', hour: 20, minute: 0),
  ShichenPeriod(index: 11, branch: '亥', name: '亥时', range: '21:00-23:00', hour: 22, minute: 0),
  ShichenPeriod(index: 12, branch: '子', name: '晚子时', range: '23:00-24:00', hour: 23, minute: 30),
];

/// 根据索引获取时辰
ShichenPeriod? getShichenByIndex(int index) {
  if (index < 0 || index >= shichenPeriods.length) {
    return null;
  }
  return shichenPeriods[index];
}

/// 根据时钟时间获取时辰索引
/// 返回 -1 表示无效时间
int getTimeIndexFromClock(int hour, [int minute = 0]) {
  if (minute < 0 || minute > 59 || hour < 0 || hour > 24) {
    return -1;
  }

  if (hour == 24) return minute == 0 ? 12 : -1;
  if (hour == 23) return 12;  // 晚子时
  if (hour == 0) return 0;    // 早子时
  return ((hour + 1) / 2).floor();
}

/// 根据时钟时间获取时辰
ShichenPeriod? getShichenFromClock(int hour, [int minute = 0]) {
  return getShichenByIndex(getTimeIndexFromClock(hour, minute));
}
