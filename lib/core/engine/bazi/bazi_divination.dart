import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/calendar/civil_time.dart';
import 'package:zhaoxingzhai/core/calendar/divination_calendar_snapshot.dart';
import 'package:zhaoxingzhai/core/calendar/true_solar_time.dart';
import 'package:zhaoxingzhai/core/models/algorithm_metadata.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

enum BaziElement { wood, fire, earth, metal, water }

extension BaziElementLabel on BaziElement {
  String get label => const ['木', '火', '土', '金', '水'][index];
}

class BaziPillar {
  const BaziPillar({
    required this.name,
    required this.ganzhi,
    required this.wuxing,
    required this.nayin,
    required this.stemTenGod,
    required this.hiddenStems,
    required this.hiddenTenGods,
    required this.lifeStage,
  });

  final String name;
  final String ganzhi;
  final String wuxing;
  final String nayin;
  final String stemTenGod;
  final List<String> hiddenStems;
  final List<String> hiddenTenGods;
  final String lifeStage;

  Map<String, dynamic> toJson() => {
    'name': name,
    'ganzhi': ganzhi,
    'wuxing': wuxing,
    'nayin': nayin,
    'stemTenGod': stemTenGod,
    'hiddenStems': hiddenStems,
    'hiddenTenGods': hiddenTenGods,
    'lifeStage': lifeStage,
  };
}

class BaziLuckCycle {
  const BaziLuckCycle({
    required this.startAge,
    required this.endAge,
    required this.startYear,
    required this.endYear,
    required this.ganzhi,
  });

  final int startAge;
  final int endAge;
  final int startYear;
  final int endYear;
  final String ganzhi;

  Map<String, dynamic> toJson() => {
    'startAge': startAge,
    'endAge': endAge,
    'startYear': startYear,
    'endYear': endYear,
    'ganzhi': ganzhi,
  };
}

class BaziResult {
  const BaziResult({
    required this.generatedAt,
    required this.subject,
    required this.inputCivilTime,
    required this.solarCivilTime,
    required this.calculationTime,
    required this.usedLunarConversion,
    required this.usedTrueSolarTime,
    required this.trueSolarCorrectionMinutes,
    required this.calendar,
    required this.pillars,
    required this.dayMaster,
    required this.elementCounts,
    required this.forwardLuck,
    required this.luckStart,
    required this.luckCycles,
    required this.taiYuan,
    required this.mingGong,
    required this.shenGong,
    required this.algorithm,
  });

  final DateTime generatedAt;
  final CaseSnapshot subject;
  final DateTime inputCivilTime;
  final DateTime solarCivilTime;
  final DateTime calculationTime;
  final bool usedLunarConversion;
  final bool usedTrueSolarTime;
  final double? trueSolarCorrectionMinutes;
  final DivinationCalendarSnapshot calendar;
  final List<BaziPillar> pillars;
  final String dayMaster;
  final Map<BaziElement, int> elementCounts;
  final bool forwardLuck;
  final String luckStart;
  final List<BaziLuckCycle> luckCycles;
  final String taiYuan;
  final String mingGong;
  final String shenGong;
  final AlgorithmDescriptor algorithm;

  Map<String, dynamic> toJson() => {
    'algorithm': algorithm.toJson(),
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'subject': subject.toJson(),
    'inputCivilTime': inputCivilTime.toIso8601String(),
    'solarCivilTime': solarCivilTime.toIso8601String(),
    'calculationTime': calculationTime.toIso8601String(),
    'usedLunarConversion': usedLunarConversion,
    'usedTrueSolarTime': usedTrueSolarTime,
    'trueSolarCorrectionMinutes': trueSolarCorrectionMinutes,
    'calendar': calendar.toJson(),
    'pillars': pillars.map((p) => p.toJson()).toList(),
    'dayMaster': dayMaster,
    'elementCounts': {
      for (final item in elementCounts.entries) item.key.label: item.value,
    },
    'forwardLuck': forwardLuck,
    'luckStart': luckStart,
    'luckCycles': luckCycles.map((c) => c.toJson()).toList(),
    'taiYuan': taiYuan,
    'mingGong': mingGong,
    'shenGong': shenGong,
  };
}

abstract final class BaziEngine {
  static const _elements = {
    '木': BaziElement.wood,
    '火': BaziElement.fire,
    '土': BaziElement.earth,
    '金': BaziElement.metal,
    '水': BaziElement.water,
  };

  static BaziResult calculate(CaseSnapshot subject, {DateTime? now}) {
    final input = subject.birthDateTime;
    final solarCivil = _toSolarCivil(subject);
    final corrected = _applyTrueSolarTime(subject, solarCivil);
    final calculationTime = corrected.$1;
    final solar = Solar.fromYmdHms(
      calculationTime.year,
      calculationTime.month,
      calculationTime.day,
      calculationTime.hour,
      calculationTime.minute,
      calculationTime.second,
    );
    final lunar = solar.getLunar();
    final eightChar = EightChar.fromLunar(lunar)..setSect(2);
    final calendar = DivinationCalendarSnapshot.chinaCivil(
      calculationTime,
      timeZoneId: subject.timezoneId,
    );
    final pillars = [
      _pillar(
        '年柱',
        eightChar.getYear(),
        eightChar.getYearWuXing(),
        eightChar.getYearNaYin(),
        eightChar.getYearShiShenGan(),
        eightChar.getYearHideGan(),
        eightChar.getYearShiShenZhi(),
        eightChar.getYearDiShi(),
      ),
      _pillar(
        '月柱',
        eightChar.getMonth(),
        eightChar.getMonthWuXing(),
        eightChar.getMonthNaYin(),
        eightChar.getMonthShiShenGan(),
        eightChar.getMonthHideGan(),
        eightChar.getMonthShiShenZhi(),
        eightChar.getMonthDiShi(),
      ),
      _pillar(
        '日柱',
        eightChar.getDay(),
        eightChar.getDayWuXing(),
        eightChar.getDayNaYin(),
        eightChar.getDayShiShenGan(),
        eightChar.getDayHideGan(),
        eightChar.getDayShiShenZhi(),
        eightChar.getDayDiShi(),
      ),
      _pillar(
        '时柱',
        eightChar.getTime(),
        eightChar.getTimeWuXing(),
        eightChar.getTimeNaYin(),
        eightChar.getTimeShiShenGan(),
        eightChar.getTimeHideGan(),
        eightChar.getTimeShiShenZhi(),
        eightChar.getTimeDiShi(),
      ),
    ];
    final counts = {for (final e in BaziElement.values) e: 0};
    for (final pillar in pillars) {
      for (final rune in pillar.wuxing.runes) {
        final element = _elements[String.fromCharCode(rune)];
        if (element != null) {
          counts[element] = counts[element]! + 1;
        }
      }
    }
    final gender = subject.gender == CaseGender.female ? 0 : 1;
    final yun = eightChar.getYun(gender, 2);
    final cycles = yun
        .getDaYunBy(9)
        .skip(1)
        .take(8)
        .map(
          (cycle) => BaziLuckCycle(
            startAge: cycle.getStartAge(),
            endAge: cycle.getEndAge(),
            startYear: cycle.getStartYear(),
            endYear: cycle.getEndYear(),
            ganzhi: cycle.getGanZhi(),
          ),
        )
        .toList(growable: false);
    final luckStart =
        '${yun.getStartYear()}年${yun.getStartMonth()}个月${yun.getStartDay()}天${yun.getStartHour()}小时';
    return BaziResult(
      generatedAt: now ?? DateTime.now(),
      subject: subject,
      inputCivilTime: input,
      solarCivilTime: solarCivil,
      calculationTime: calculationTime,
      usedLunarConversion: subject.calendarType == CaseCalendarType.lunar,
      usedTrueSolarTime: corrected.$2 != null,
      trueSolarCorrectionMinutes: corrected.$2,
      calendar: calendar,
      pillars: pillars,
      dayMaster: eightChar.getDayGan(),
      elementCounts: counts,
      forwardLuck: yun.isForward(),
      luckStart: luckStart,
      luckCycles: cycles,
      taiYuan: eightChar.getTaiYuan(),
      mingGong: eightChar.getMingGong(),
      shenGong: eightChar.getShenGong(),
      algorithm: AlgorithmCatalog.bazi,
    );
  }

  static DateTime _toSolarCivil(CaseSnapshot subject) {
    if (subject.calendarType == CaseCalendarType.solar) {
      return subject.birthDateTime;
    }
    final input = subject.birthDateTime;
    final month = subject.isLeapMonth ? -input.month : input.month;
    final solar = Lunar.fromYmdHms(
      input.year,
      month,
      input.day,
      input.hour,
      input.minute,
      input.second,
    ).getSolar();
    return DateTime(
      solar.getYear(),
      solar.getMonth(),
      solar.getDay(),
      solar.getHour(),
      solar.getMinute(),
      solar.getSecond(),
    );
  }

  static (DateTime, double?) _applyTrueSolarTime(
    CaseSnapshot subject,
    DateTime solarCivil,
  ) {
    final longitude = subject.longitude;
    if (longitude == null) return (solarCivil, null);
    final value = convertTrueSolarTime(
      TrueSolarTimeConversionInput(
        localDateTime: formatSolarDateTimeParts(
          CivilDateTimeParts(
            year: solarCivil.year,
            month: solarCivil.month,
            day: solarCivil.day,
            hour: solarCivil.hour,
            minute: solarCivil.minute,
            second: solarCivil.second,
          ),
        ),
        longitude: longitude,
        timeZoneId: subject.timezoneId,
      ),
    );
    final corrected = value.correctedTime;
    return (
      DateTime(
        corrected.year,
        corrected.month,
        corrected.day,
        corrected.hour,
        corrected.minute,
        corrected.second,
      ),
      value.totalCorrectionMinutes,
    );
  }

  static BaziPillar _pillar(
    String name,
    String ganzhi,
    String wuxing,
    String nayin,
    String stemTenGod,
    List<String> hiddenStems,
    List<String> hiddenTenGods,
    String lifeStage,
  ) => BaziPillar(
    name: name,
    ganzhi: ganzhi,
    wuxing: wuxing,
    nayin: nayin,
    stemTenGod: stemTenGod,
    hiddenStems: List.unmodifiable(hiddenStems),
    hiddenTenGods: List.unmodifiable(hiddenTenGods),
    lifeStage: lifeStage,
  );
}
