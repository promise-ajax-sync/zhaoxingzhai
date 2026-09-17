import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  final fixedNow = DateTime(2026, 9, 17, 10, 30);

  CaseProfile sample() => CaseProfile.create(
    name: '张三',
    gender: CaseGender.male,
    birthDateTime: DateTime(1990, 5, 1, 8, 30),
    timezoneId: 'Asia/Shanghai',
    longitude: 116.4074,
    latitude: 39.9042,
    placeName: '北京',
    note: '测试备注',
    now: fixedNow,
  );

  test('新建案例会生成标识与时间戳', () {
    final profile = sample();

    expect(profile.id, startsWith('case:'));
    expect(profile.createdAt, fixedNow);
    expect(profile.updatedAt, fixedNow);
    expect(profile.hasLocation, isTrue);
  });

  test('序列化后原样读回', () {
    final profile = sample();
    final decoded = CaseProfile.fromJson(profile.toJson());

    expect(decoded.id, profile.id);
    expect(decoded.name, profile.name);
    expect(decoded.gender, profile.gender);
    expect(decoded.calendarType, profile.calendarType);
    expect(decoded.birthDateTime, profile.birthDateTime);
    expect(decoded.timezoneId, profile.timezoneId);
    expect(decoded.longitude, profile.longitude);
    expect(decoded.latitude, profile.latitude);
    expect(decoded.placeName, profile.placeName);
    expect(decoded.note, profile.note);
  });

  test('缺省字段有安全回退', () {
    final decoded = CaseProfile.fromJson(<String, dynamic>{
      'name': '李四',
      'birthDateTime': DateTime(2000, 1, 1).toIso8601String(),
    });

    expect(decoded.gender, CaseGender.unspecified);
    expect(decoded.calendarType, CaseCalendarType.solar);
    expect(decoded.timezoneId, 'Asia/Shanghai');
    expect(decoded.isLeapMonth, isFalse);
    expect(decoded.hasLocation, isFalse);
    expect(decoded.note, isEmpty);
  });

  test('缺少必需字段的数据被视为损坏而不是崩溃', () {
    expect(
      CaseProfile.tryFromJson(<String, dynamic>{'name': '无时间'}),
      isNull,
    );
    expect(
      CaseProfile.tryFromJson(<String, dynamic>{
        'birthDateTime': DateTime(2000).toIso8601String(),
      }),
      isNull,
    );
  });

  test('copyWith 保留标识与创建时间', () {
    final profile = sample();
    final updated = profile.copyWith(
      name: '张三改名',
      updatedAt: DateTime(2026, 10, 1),
    );

    expect(updated.id, profile.id);
    expect(updated.createdAt, profile.createdAt);
    expect(updated.updatedAt, DateTime(2026, 10, 1));
    expect(updated.name, '张三改名');
    expect(profile.name, '张三');
  });

  test('快照是值拷贝，不受原案例后续修改影响', () {
    final profile = sample();
    final snapshot = profile.toSnapshot();

    profile.copyWith(name: '李四', birthDateTime: DateTime(2001, 2, 3));

    expect(snapshot.name, '张三');
    expect(snapshot.birthDateTime, DateTime(1990, 5, 1, 8, 30));
    expect(snapshot.caseId, profile.id);
    expect(snapshot.hasLocation, isTrue);
  });

  test('快照序列化后原样读回', () {
    final snapshot = sample().toSnapshot();
    final decoded = CaseSnapshot.fromJson(snapshot.toJson());

    expect(decoded.caseId, snapshot.caseId);
    expect(decoded.name, snapshot.name);
    expect(decoded.birthDateTime, snapshot.birthDateTime);
    expect(decoded.longitude, snapshot.longitude);
  });

  test('快照字段缺失时取缺省值而不回退到当前案例', () {
    final decoded = CaseSnapshot.fromJson(<String, dynamic>{});

    expect(decoded.caseId, isEmpty);
    expect(decoded.name, isEmpty);
    expect(decoded.gender, CaseGender.unspecified);
    expect(decoded.timezoneId, 'Asia/Shanghai');
    expect(decoded.displayName, '未命名案例');
    expect(decoded.hasLocation, isFalse);
  });

  test('摘要包含历法口径与出生时间', () {
    final summary = sample().summary;

    expect(summary, contains('公历'));
    expect(summary, contains('1990-05-01 08:30'));
    expect(summary, contains('北京'));
  });
}
