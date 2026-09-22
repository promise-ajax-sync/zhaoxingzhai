import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_limits.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CaseSnapshot lunarSubject({
    required String id,
    required int year,
    int month = 1,
    int day = 1,
    int hour = 0,
    CaseGender gender = CaseGender.male,
    bool isLeapMonth = false,
  }) => CaseSnapshot(
    caseId: id,
    name: '紫微回归角色',
    gender: gender,
    calendarType: CaseCalendarType.lunar,
    birthDateTime: DateTime(year, month, day, hour),
    isLeapMonth: isLeapMonth,
  );

  test('阴阳年男女四种组合保持既定大限顺逆', () async {
    final vectors = [
      (
        subject: lunarSubject(
          id: 'yang-male',
          year: 2024,
          gender: CaseGender.male,
        ),
        direction: ZiweiLimitDirection.forward,
      ),
      (
        subject: lunarSubject(
          id: 'yang-female',
          year: 2024,
          gender: CaseGender.female,
        ),
        direction: ZiweiLimitDirection.reverse,
      ),
      (
        subject: lunarSubject(
          id: 'yin-male',
          year: 2025,
          gender: CaseGender.male,
        ),
        direction: ZiweiLimitDirection.reverse,
      ),
      (
        subject: lunarSubject(
          id: 'yin-female',
          year: 2025,
          gender: CaseGender.female,
        ),
        direction: ZiweiLimitDirection.forward,
      ),
    ];

    for (final vector in vectors) {
      final result = await ZiweiChartEngine.calculate(vector.subject);
      expect(
        result.limits.direction,
        vector.direction,
        reason:
            '${result.yearStem}${result.yearBranch}年${vector.subject.gender.label}',
      );
      expect(result.limits.decades, hasLength(12));
    }
  });

  test('子卯午酉四正时覆盖不同命身宫并保持二十八星完整', () async {
    final vectors = <int, String>{0: '子', 6: '卯', 12: '午', 18: '酉'};
    final signatures = <String>{};

    for (final entry in vectors.entries) {
      final result = await ZiweiChartEngine.calculate(
        lunarSubject(id: 'cardinal-${entry.key}', year: 2024, hour: entry.key),
      );
      expect(result.foundation.timeBranch, entry.value);
      expect(result.palaces.expand((e) => e.stars), hasLength(28));
      signatures.add(
        '${result.foundation.lifeBranch}:${result.foundation.bodyBranch}',
      );
    }

    expect(signatures, hasLength(4));
  });

  test('固定农历样本矩阵覆盖水木金土火五种五行局', () async {
    final found = <String, ZiweiChartResult>{};

    for (var month = 1; month <= 12 && found.length < 5; month++) {
      for (final hour in [0, 6, 12, 18]) {
        final result = await ZiweiChartEngine.calculate(
          lunarSubject(
            id: 'bureau-$month-$hour',
            year: 2024,
            month: month,
            hour: hour,
          ),
        );
        found.putIfAbsent(result.foundation.fiveElementBureau, () => result);
      }
    }

    expect(found.keys.toSet(), {'水二局', '木三局', '金四局', '土五局', '火六局'});
    for (final result in found.values) {
      expect(result.limits.startNominalAge, result.foundation.bureauNumber);
      expect(result.palaces, hasLength(12));
      expect(result.palaces.expand((e) => e.stars), hasLength(28));
    }
  });

  test('闰月输入保留负月标记并产出完整可序列化盘面', () async {
    final result = await ZiweiChartEngine.calculate(
      lunarSubject(
        id: 'leap-month-2023',
        year: 2023,
        month: 2,
        day: 1,
        hour: 6,
        isLeapMonth: true,
      ),
    );

    expect(result.foundation.lunarMonth, -2);
    expect(result.foundation.subject.isLeapMonth, isTrue);
    expect(result.palaces, hasLength(12));
    expect(result.palaces.expand((e) => e.stars), hasLength(28));
    expect(result.toJson()['annual'], isA<Map<String, dynamic>>());
  });

  test('23点与次日0点均按子时处理但保留各自日期输入', () async {
    final lateZi = await ZiweiChartEngine.calculate(
      lunarSubject(id: 'late-zi', year: 2024, month: 1, day: 1, hour: 23),
    );
    final earlyZi = await ZiweiChartEngine.calculate(
      lunarSubject(id: 'early-zi', year: 2024, month: 1, day: 2, hour: 0),
    );

    expect(lateZi.foundation.timeBranch, '子');
    expect(earlyZi.foundation.timeBranch, '子');
    expect(lateZi.foundation.lunarDay, 1);
    expect(earlyZi.foundation.lunarDay, 2);
    expect(lateZi.foundation.subject.birthDateTime.hour, 23);
    expect(earlyZi.foundation.subject.birthDateTime.hour, 0);
  });
}
