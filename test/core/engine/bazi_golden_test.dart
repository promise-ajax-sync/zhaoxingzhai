import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/bazi/bazi_divination.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

CaseSnapshot _subject(Map<String, dynamic> vector) => CaseSnapshot(
  caseId: vector['id'] as String,
  name: vector['name'] as String,
  gender: CaseGender.values.byName(vector['gender'] as String),
  calendarType: CaseCalendarType.values.byName(
    vector['calendarType'] as String,
  ),
  birthDateTime: DateTime.parse(vector['birthDateTime'] as String),
  isLeapMonth: vector['isLeapMonth'] as bool? ?? false,
  longitude: (vector['longitude'] as num?)?.toDouble(),
);

const _vectors = [
  {
    'id': 'golden-solar-spring',
    'name': '公历春季案例',
    'gender': 'male',
    'calendarType': 'solar',
    'birthDateTime': '1990-05-17T14:30:00',
  },
  {
    'id': 'golden-lunar-new-year',
    'name': '农历正月案例',
    'gender': 'female',
    'calendarType': 'lunar',
    'birthDateTime': '2024-01-01T08:00:00',
  },
  {
    'id': 'golden-midnight',
    'name': '子时边界案例',
    'gender': 'male',
    'calendarType': 'solar',
    'birthDateTime': '2000-01-01T23:30:00',
  },
  {
    'id': 'golden-true-solar',
    'name': '真太阳时案例',
    'gender': 'female',
    'calendarType': 'solar',
    'birthDateTime': '1988-08-08T12:00:00',
    'longitude': 105,
  },
];

void main() {
  for (final vector in _vectors) {
    test('八字回归向量 ${vector['id']}', () {
      final subject = _subject(vector);
      final fixedNow = DateTime.utc(2026, 9, 22);
      final first = BaziEngine.calculate(subject, now: fixedNow).toJson();
      final second = BaziEngine.calculate(subject, now: fixedNow).toJson();

      expect(first, equals(second));
      expect(first['algorithm'], containsPair('id', 'bazi'));
      expect(first['algorithm'], containsPair('version', 2));
      expect(first['pillars'], hasLength(4));
      expect(first['luckCycles'], hasLength(8));
      expect(first['subject'], containsPair('caseId', vector['id']));
    });
  }
}
