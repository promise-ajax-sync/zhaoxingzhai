import 'package:lunar/lunar.dart';

List<String> _unique(Iterable<String> values) =>
    List.unmodifiable(values.where((value) => value.trim().isNotEmpty).toSet());

final Map<String, List<AlmanacMonthCell>> _monthGridCache = {};
final Map<String, TraditionalAlmanacDay> _dayCache = {};

class AlmanacMonthCell {
  const AlmanacMonthCell({
    required this.date,
    required this.lunarLabel,
    required this.solarTerm,
    required this.festival,
  });

  factory AlmanacMonthCell.fromDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final solarTerm = lunar.getJieQi();
    final festivals = _unique([
      ...solar.getFestivals(),
      ...lunar.getFestivals(),
    ]);
    final festival = festivals.isEmpty ? null : festivals.first;
    return AlmanacMonthCell(
      date: date,
      lunarLabel: solarTerm.isNotEmpty
          ? solarTerm
          : festival ??
                (lunar.getDay() == 1
                    ? '${lunar.getMonthInChinese()}月'
                    : lunar.getDayInChinese()),
      solarTerm: solarTerm.isEmpty ? null : solarTerm,
      festival: festival,
    );
  }

  final DateTime date;
  final String lunarLabel;
  final String? solarTerm;
  final String? festival;

  bool get isSpecial => solarTerm != null || festival != null;
}

List<AlmanacMonthCell> buildAlmanacMonthGrid(int year, int month) {
  final key = '$year-$month';
  final cached = _monthGridCache[key];
  if (cached != null) {
    return cached;
  }
  final firstDay = DateTime(year, month);
  final start = firstDay.subtract(Duration(days: firstDay.weekday % 7));
  final result = List<AlmanacMonthCell>.unmodifiable(
    List.generate(
      42,
      (index) => AlmanacMonthCell.fromDate(start.add(Duration(days: index))),
      growable: false,
    ),
  );
  if (_monthGridCache.length >= 24) {
    _monthGridCache.clear();
  }
  _monthGridCache[key] = result;
  return result;
}

TraditionalAlmanacDay getTraditionalAlmanacDay(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  final key = '${date.year}-${date.month}-${date.day}';
  final cached = _dayCache[key];
  if (cached != null) {
    return cached;
  }
  final result = TraditionalAlmanacDay.fromDate(date);
  if (_dayCache.length >= 120) {
    _dayCache.clear();
  }
  _dayCache[key] = result;
  return result;
}

class AlmanacTimePeriod {
  const AlmanacTimePeriod({
    required this.label,
    required this.range,
    required this.ganZhi,
    required this.heavenlyGod,
    required this.luck,
    required this.clash,
    required this.sha,
    required this.naYin,
    required this.yi,
    required this.ji,
  });

  final String label;
  final String range;
  final String ganZhi;
  final String heavenlyGod;
  final String luck;
  final String clash;
  final String sha;
  final String naYin;
  final List<String> yi;
  final List<String> ji;
}

class TraditionalAlmanacDay {
  const TraditionalAlmanacDay({
    required this.date,
    required this.weekday,
    required this.lunarDate,
    required this.zodiac,
    required this.yearGanzhi,
    required this.monthGanzhi,
    required this.dayGanzhi,
    required this.solarTerm,
    required this.previousSolarTerm,
    required this.nextSolarTerm,
    required this.solarFestivals,
    required this.lunarFestivals,
    required this.dayNaYin,
    required this.fetalGod,
    required this.timePeriods,
    required this.yi,
    required this.ji,
    required this.auspiciousGods,
    required this.inauspiciousSpirits,
    required this.dutyOfficer,
    required this.heavenlyGod,
    required this.heavenlyGodLuck,
    required this.mansion,
    required this.mansionLuck,
    required this.clash,
    required this.sha,
    required this.pengzu,
    required this.joyDirection,
    required this.wealthDirection,
    required this.fortuneDirection,
  });

  factory TraditionalAlmanacDay.fromDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final solarTerm = lunar.getJieQi();
    final previousLookupDate = solarTerm.isEmpty
        ? date
        : date.subtract(const Duration(days: 1));
    final nextLookupDate = solarTerm.isEmpty
        ? date
        : date.add(const Duration(days: 1));
    final previousTerm = Solar.fromYmd(
      previousLookupDate.year,
      previousLookupDate.month,
      previousLookupDate.day,
    ).getLunar().getPrevJieQi(true);
    final nextTerm = Solar.fromYmd(
      nextLookupDate.year,
      nextLookupDate.month,
      nextLookupDate.day,
    ).getLunar().getNextJieQi(true);
    const timeRanges = {
      '子': '23:00—01:00',
      '丑': '01:00—03:00',
      '寅': '03:00—05:00',
      '卯': '05:00—07:00',
      '辰': '07:00—09:00',
      '巳': '09:00—11:00',
      '午': '11:00—13:00',
      '未': '13:00—15:00',
      '申': '15:00—17:00',
      '酉': '17:00—19:00',
      '戌': '19:00—21:00',
      '亥': '21:00—23:00',
    };
    final timePeriodsByZhi = <String, AlmanacTimePeriod>{};
    for (final time in lunar.getTimes()) {
      final zhi = time.getZhi();
      timePeriodsByZhi.putIfAbsent(
        zhi,
        () => AlmanacTimePeriod(
          label: '$zhi时',
          range: timeRanges[zhi] ?? '',
          ganZhi: time.getGanZhi(),
          heavenlyGod: time.getTianShen(),
          luck: time.getTianShenLuck(),
          clash: time.getChongDesc(),
          sha: time.getSha(),
          naYin: time.getNaYin(),
          yi: _unique(time.getYi()),
          ji: _unique(time.getJi()),
        ),
      );
    }
    final timePeriods = timeRanges.keys
        .map((zhi) => timePeriodsByZhi[zhi])
        .whereType<AlmanacTimePeriod>()
        .toList(growable: false);
    return TraditionalAlmanacDay(
      date: date,
      weekday: '星期${solar.getWeekInChinese()}',
      lunarDate: '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}',
      zodiac: lunar.getYearShengXiao(),
      yearGanzhi: lunar.getYearInGanZhi(),
      monthGanzhi: lunar.getMonthInGanZhiExact(),
      dayGanzhi: lunar.getDayInGanZhiExact(),
      solarTerm: solarTerm.isEmpty ? null : solarTerm,
      previousSolarTerm:
          '${previousTerm.getName()} · ${previousTerm.getSolar().toYmd()}',
      nextSolarTerm: '${nextTerm.getName()} · ${nextTerm.getSolar().toYmd()}',
      solarFestivals: _unique([
        ...solar.getFestivals(),
        ...solar.getOtherFestivals(),
      ]),
      lunarFestivals: _unique([
        ...lunar.getFestivals(),
        ...lunar.getOtherFestivals(),
      ]),
      dayNaYin: lunar.getDayNaYin(),
      fetalGod: lunar.getDayPositionTai(),
      timePeriods: List.unmodifiable(timePeriods),
      yi: _unique(lunar.getDayYi()),
      ji: _unique(lunar.getDayJi()),
      auspiciousGods: _unique(lunar.getDayJiShen()),
      inauspiciousSpirits: _unique(lunar.getDayXiongSha()),
      dutyOfficer: lunar.getZhiXing(),
      heavenlyGod: lunar.getDayTianShen(),
      heavenlyGodLuck: lunar.getDayTianShenLuck(),
      mansion: lunar.getXiu(),
      mansionLuck: lunar.getXiuLuck(),
      clash: lunar.getDayChongDesc(),
      sha: lunar.getDaySha(),
      pengzu: '${lunar.getPengZuGan()}，${lunar.getPengZuZhi()}',
      joyDirection: lunar.getDayPositionXiDesc(),
      wealthDirection: lunar.getDayPositionCaiDesc(),
      fortuneDirection: lunar.getDayPositionFuDesc(),
    );
  }

  final DateTime date;
  final String weekday;
  final String lunarDate;
  final String zodiac;
  final String yearGanzhi;
  final String monthGanzhi;
  final String dayGanzhi;
  final String? solarTerm;
  final String previousSolarTerm;
  final String nextSolarTerm;
  final List<String> solarFestivals;
  final List<String> lunarFestivals;
  final String dayNaYin;
  final String fetalGod;
  final List<AlmanacTimePeriod> timePeriods;
  final List<String> yi;
  final List<String> ji;
  final List<String> auspiciousGods;
  final List<String> inauspiciousSpirits;
  final String dutyOfficer;
  final String heavenlyGod;
  final String heavenlyGodLuck;
  final String mansion;
  final String mansionLuck;
  final String clash;
  final String sha;
  final String pengzu;
  final String joyDirection;
  final String wealthDirection;
  final String fortuneDirection;

  List<String> get festivals => _unique([...solarFestivals, ...lunarFestivals]);

  String get solarDateLabel => '${date.year}年${date.month}月${date.day}日';
}
