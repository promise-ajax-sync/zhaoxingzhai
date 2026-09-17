/// 案例：一个可被反复引用的占卜主体。
///
/// 案例不是一次占卜记录，而是「这是谁／这是哪件事」的输入主体。
/// 排盘、合盘、个人历、姓名与数字等术式都以它为输入；
/// 两人合盘要求至少两个不同案例。
///
/// 对应参考实现的 `caseProfile`，但字段与校验为本项目独立定义。
library;

import 'package:flutter/foundation.dart';
import 'package:zhaoxingzhai/core/shared/result.dart';

/// 性别。紫微顺逆布大运、八宅命卦等术式需要区分。
enum CaseGender {
  male('男'),
  female('女'),
  unspecified('未指定');

  const CaseGender(this.label);

  final String label;
}

/// 出生时间的录入口径。
enum CaseCalendarType {
  solar('公历'),
  lunar('农历');

  const CaseCalendarType(this.label);

  final String label;
}

/// 计算当时的案例副本。
///
/// 存在的意义是**切断与当前案例的关联**：历史记录保存快照而不是案例标识，
/// 因此修改或删除当前案例都不会改变旧历史。
///
/// 反序列化时若字段缺失一律取缺省值，**绝不回退到当前案例补齐**——
/// 那会让旧历史被后来的资料静默篡改。
@immutable
class CaseSnapshot {
  const CaseSnapshot({
    required this.caseId,
    required this.name,
    required this.gender,
    required this.calendarType,
    required this.birthDateTime,
    this.isLeapMonth = false,
    this.timezoneId = defaultTimezoneId,
    this.longitude,
    this.latitude,
    this.placeName,
  });

  static const String defaultTimezoneId = 'Asia/Shanghai';

  final String caseId;
  final String name;
  final CaseGender gender;
  final CaseCalendarType calendarType;

  /// 出生时间的墙上时间部分，按 [timezoneId] 解释。
  final DateTime birthDateTime;
  final bool isLeapMonth;
  final String timezoneId;

  /// 出生地经度（东经为正），真太阳时需要。
  final double? longitude;

  /// 出生地纬度（北纬为正）。
  final double? latitude;

  /// 出生地名称，仅供展示。
  final String? placeName;

  bool get hasLocation => longitude != null && latitude != null;

  String get displayName => name.trim().isEmpty ? '未命名案例' : name;

  /// 案例资料签名，用于排盘缓存失效与结果身份。
  ///
  /// 只有影响计算的字段参与；备注等纯展示字段不参与。
  String get stableHash => hashStableValue(toJson());

  Map<String, dynamic> toJson() => {
    'caseId': caseId,
    'name': name,
    'gender': gender.name,
    'calendarType': calendarType.name,
    'birthDateTime': birthDateTime.toIso8601String(),
    'isLeapMonth': isLeapMonth,
    'timezoneId': timezoneId,
    if (longitude != null) 'longitude': longitude,
    if (latitude != null) 'latitude': latitude,
    if (placeName != null) 'placeName': placeName,
  };

  factory CaseSnapshot.fromJson(Map<String, dynamic> json) {
    final birth = json['birthDateTime'] as String?;
    return CaseSnapshot(
      caseId: json['caseId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: CaseGender.values.asNameMap()[json['gender']] ??
          CaseGender.unspecified,
      calendarType: CaseCalendarType.values.asNameMap()[json['calendarType']] ??
          CaseCalendarType.solar,
      birthDateTime:
          birth == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(birth),
      isLeapMonth: json['isLeapMonth'] as bool? ?? false,
      timezoneId: json['timezoneId'] as String? ?? defaultTimezoneId,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      placeName: json['placeName'] as String?,
    );
  }
}

/// 一个案例。
///
/// [birthDateTime] 保存的是**墙上时间**，语义上按 [timezoneId] 解释，
/// 而不是一个已折算好的 UTC 瞬间。这样即使用户日后修正时区，录入的
/// 原始资料也不会被悄悄改写。需要绝对瞬间时再按 [timezoneId] 结合
/// 历史时区库换算，并可进一步求真太阳时。
class CaseProfile {
  const CaseProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.calendarType,
    required this.birthDateTime,
    this.isLeapMonth = false,
    this.timezoneId = CaseSnapshot.defaultTimezoneId,
    this.longitude,
    this.latitude,
    this.placeName,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final CaseGender gender;
  final CaseCalendarType calendarType;
  final DateTime birthDateTime;
  final bool isLeapMonth;
  final String timezoneId;
  final double? longitude;
  final double? latitude;
  final String? placeName;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 新建案例，自动生成标识与时间戳。
  ///
  /// [now] 可注入，便于测试产出确定的标识。
  factory CaseProfile.create({
    required String name,
    CaseGender gender = CaseGender.unspecified,
    CaseCalendarType calendarType = CaseCalendarType.solar,
    required DateTime birthDateTime,
    bool isLeapMonth = false,
    String timezoneId = CaseSnapshot.defaultTimezoneId,
    double? longitude,
    double? latitude,
    String? placeName,
    String note = '',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return CaseProfile(
      id: 'case:${timestamp.microsecondsSinceEpoch}',
      name: name,
      gender: gender,
      calendarType: calendarType,
      birthDateTime: birthDateTime,
      isLeapMonth: isLeapMonth,
      timezoneId: timezoneId,
      longitude: longitude,
      latitude: latitude,
      placeName: placeName,
      note: note,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  bool get hasLocation => longitude != null && latitude != null;

  /// 展示用的一行摘要。
  String get summary {
    final parts = <String>[
      calendarType.label,
      formatBirthDateTime(),
      if (placeName != null && placeName!.isNotEmpty) placeName!,
    ];
    return parts.join(' · ');
  }

  /// 格式化出生时间，供摘要与快照共用。
  String formatBirthDateTime() {
    String two(int value) => value.toString().padLeft(2, '0');
    final leap = isLeapMonth ? '（闰月）' : '';
    return '${birthDateTime.year}-${two(birthDateTime.month)}-'
        '${two(birthDateTime.day)} ${two(birthDateTime.hour)}:'
        '${two(birthDateTime.minute)}$leap';
  }

  CaseProfile copyWith({
    String? name,
    CaseGender? gender,
    CaseCalendarType? calendarType,
    DateTime? birthDateTime,
    bool? isLeapMonth,
    String? timezoneId,
    double? longitude,
    double? latitude,
    String? placeName,
    String? note,
    DateTime? updatedAt,
  }) {
    return CaseProfile(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      calendarType: calendarType ?? this.calendarType,
      birthDateTime: birthDateTime ?? this.birthDateTime,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      timezoneId: timezoneId ?? this.timezoneId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      placeName: placeName ?? this.placeName,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 生成快照。快照是值拷贝，此后修改本案例不影响已生成的快照。
  CaseSnapshot toSnapshot() => CaseSnapshot(
    caseId: id,
    name: name,
    gender: gender,
    calendarType: calendarType,
    birthDateTime: birthDateTime,
    isLeapMonth: isLeapMonth,
    timezoneId: timezoneId,
    longitude: longitude,
    latitude: latitude,
    placeName: placeName,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gender': gender.name,
    'calendarType': calendarType.name,
    'birthDateTime': birthDateTime.toIso8601String(),
    'isLeapMonth': isLeapMonth,
    'timezoneId': timezoneId,
    if (longitude != null) 'longitude': longitude,
    if (latitude != null) 'latitude': latitude,
    if (placeName != null) 'placeName': placeName,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// 反序列化。返回 `null` 表示这条数据损坏，调用方应跳过而不是崩溃。
  static CaseProfile? tryFromJson(Map<String, dynamic> json) {
    try {
      return CaseProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  factory CaseProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw const FormatException('案例缺少姓名');
    }
    final birth = json['birthDateTime'] as String?;
    if (birth == null) {
      throw const FormatException('案例缺少出生时间');
    }
    final createdAtRaw = json['createdAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;
    final createdAt = createdAtRaw == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(createdAtRaw);

    return CaseProfile(
      id: json['id'] as String? ?? 'case:unknown',
      name: name,
      gender: CaseGender.values.asNameMap()[json['gender']] ??
          CaseGender.unspecified,
      calendarType: CaseCalendarType.values.asNameMap()[json['calendarType']] ??
          CaseCalendarType.solar,
      birthDateTime: DateTime.parse(birth),
      isLeapMonth: json['isLeapMonth'] as bool? ?? false,
      timezoneId: json['timezoneId'] as String? ?? CaseSnapshot.defaultTimezoneId,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      placeName: json['placeName'] as String?,
      note: json['note'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAtRaw == null ? createdAt : DateTime.parse(updatedAtRaw),
    );
  }
}
