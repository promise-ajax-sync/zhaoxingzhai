import 'package:lunar/lunar.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

class ZiweiPalacePosition {
  const ZiweiPalacePosition({
    required this.index,
    required this.name,
    required this.stem,
    required this.branch,
    required this.isLife,
    required this.isBody,
  });
  final int index;
  final String name;
  final String stem;
  final String branch;
  final bool isLife;
  final bool isBody;
  String get ganzhi => '$stem$branch';
  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'stem': stem,
    'branch': branch,
    'ganzhi': ganzhi,
    'isLife': isLife,
    'isBody': isBody,
  };
}

class ZiweiFoundationResult {
  const ZiweiFoundationResult({
    required this.subject,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.timeBranch,
    required this.lifeBranch,
    required this.bodyBranch,
    required this.fiveElementBureau,
    required this.bureauNumber,
    required this.palaces,
  });
  final CaseSnapshot subject;
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final String timeBranch;
  final String lifeBranch;
  final String bodyBranch;
  final String fiveElementBureau;
  final int bureauNumber;
  final List<ZiweiPalacePosition> palaces;
  Map<String, dynamic> toJson() => {
    'subject': subject.toJson(),
    'lunarYear': lunarYear,
    'lunarMonth': lunarMonth,
    'lunarDay': lunarDay,
    'timeBranch': timeBranch,
    'lifeBranch': lifeBranch,
    'bodyBranch': bodyBranch,
    'fiveElementBureau': fiveElementBureau,
    'bureauNumber': bureauNumber,
    'palaces': palaces.map((e) => e.toJson()).toList(),
  };
}

abstract final class ZiweiFoundationEngine {
  static const branches = [
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
    '子',
    '丑',
  ];
  static const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  static const palaceNames = [
    '命宫',
    '兄弟宫',
    '夫妻宫',
    '子女宫',
    '财帛宫',
    '疾厄宫',
    '迁移宫',
    '交友宫',
    '官禄宫',
    '田宅宫',
    '福德宫',
    '父母宫',
  ];

  static ZiweiFoundationResult calculate(CaseSnapshot subject) {
    final lunar = _lunar(subject);
    final month = lunar.getMonth().abs();
    final timeIndex = _timeIndex(subject.birthDateTime.hour);
    final lifeIndex = _mod(month - 1 - timeIndex, 12);
    final bodyIndex = _mod(month - 1 + timeIndex, 12);
    final yearStem = lunar.getYearGan();
    final firstStem = _firstMonthStem(yearStem);
    final palaceStems = List.generate(
      12,
      (i) => stems[(stems.indexOf(firstStem) + i) % 10],
    );
    final palaces = List.generate(12, (offset) {
      final index = _mod(lifeIndex - offset, 12);
      return ZiweiPalacePosition(
        index: index,
        name: palaceNames[offset],
        stem: palaceStems[index],
        branch: branches[index],
        isLife: offset == 0,
        isBody: index == bodyIndex,
      );
    });
    final life = palaces.first;
    final bureau = _bureau(LunarUtil.NAYIN[life.ganzhi] ?? '');
    return ZiweiFoundationResult(
      subject: subject,
      lunarYear: lunar.getYear(),
      lunarMonth: lunar.getMonth(),
      lunarDay: lunar.getDay(),
      timeBranch: LunarUtil.ZHI[timeIndex + 1],
      lifeBranch: branches[lifeIndex],
      bodyBranch: branches[bodyIndex],
      fiveElementBureau: bureau.$1,
      bureauNumber: bureau.$2,
      palaces: List.unmodifiable(palaces),
    );
  }

  static Lunar _lunar(CaseSnapshot subject) {
    final value = subject.birthDateTime;
    if (subject.calendarType == CaseCalendarType.lunar) {
      return Lunar.fromYmdHms(
        value.year,
        subject.isLeapMonth ? -value.month : value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
      );
    }
    return Solar.fromYmdHms(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    ).getLunar();
  }

  static int _timeIndex(int hour) => ((hour + 1) ~/ 2) % 12;
  static int _mod(int value, int divisor) =>
      (value % divisor + divisor) % divisor;

  static String _firstMonthStem(String yearStem) => switch (yearStem) {
    '甲' || '己' => '丙',
    '乙' || '庚' => '戊',
    '丙' || '辛' => '庚',
    '丁' || '壬' => '壬',
    '戊' || '癸' => '甲',
    _ => throw ArgumentError('无法识别生年天干：$yearStem'),
  };

  static (String, int) _bureau(String nayin) {
    if (nayin.endsWith('水')) return ('水二局', 2);
    if (nayin.endsWith('木')) return ('木三局', 3);
    if (nayin.endsWith('金')) return ('金四局', 4);
    if (nayin.endsWith('土')) return ('土五局', 5);
    if (nayin.endsWith('火')) return ('火六局', 6);
    throw StateError('无法根据命宫纳音确定五行局：$nayin');
  }
}
