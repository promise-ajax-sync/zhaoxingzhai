import 'package:lunar/lunar.dart';

class AlmanacSelectionActivity {
  const AlmanacSelectionActivity({
    required this.id,
    required this.label,
    required this.keywords,
  });

  final String id;
  final String label;
  final List<String> keywords;
}

const almanacSelectionActivities = <AlmanacSelectionActivity>[
  AlmanacSelectionActivity(id: 'marriage', label: '结婚嫁娶', keywords: ['嫁娶']),
  AlmanacSelectionActivity(id: 'move', label: '搬家入宅', keywords: ['入宅', '移徙']),
  AlmanacSelectionActivity(
    id: 'business',
    label: '开业开市',
    keywords: ['开市', '开业'],
  ),
  AlmanacSelectionActivity(id: 'travel', label: '出行远行', keywords: ['出行']),
  AlmanacSelectionActivity(
    id: 'construction',
    label: '装修动土',
    keywords: ['修造', '动土'],
  ),
  AlmanacSelectionActivity(
    id: 'worship',
    label: '祭祀祈福',
    keywords: ['祭祀', '祈福'],
  ),
  AlmanacSelectionActivity(
    id: 'contract',
    label: '签约交易',
    keywords: ['交易', '立券'],
  ),
  AlmanacSelectionActivity(id: 'wealth', label: '求财纳财', keywords: ['纳财']),
  AlmanacSelectionActivity(id: 'study', label: '入学求学', keywords: ['入学']),
  AlmanacSelectionActivity(
    id: 'medical',
    label: '求医治病',
    keywords: ['求医', '治病'],
  ),
  AlmanacSelectionActivity(id: 'burial', label: '安葬祭扫', keywords: ['安葬']),
];

const almanacZodiacs = <String>[
  '鼠',
  '牛',
  '虎',
  '兔',
  '龙',
  '蛇',
  '马',
  '羊',
  '猴',
  '鸡',
  '狗',
  '猪',
];

class AlmanacSelectionResult {
  const AlmanacSelectionResult({
    required this.date,
    required this.weekday,
    required this.lunarDate,
    required this.dayGanZhi,
    required this.clash,
    required this.clashZodiac,
    required this.matchedYi,
    required this.yi,
    required this.ji,
    required this.solarTerm,
    required this.festivals,
  });

  final DateTime date;
  final String weekday;
  final String lunarDate;
  final String dayGanZhi;
  final String clash;
  final String clashZodiac;
  final List<String> matchedYi;
  final List<String> yi;
  final List<String> ji;
  final String? solarTerm;
  final List<String> festivals;

  String get dateLabel => '${date.month}月${date.day}日';
}

List<AlmanacSelectionResult> findAlmanacDates({
  required DateTime startDate,
  required int days,
  required AlmanacSelectionActivity activity,
  String? excludedZodiac,
}) {
  if (days < 1 || days > 90) {
    throw ArgumentError.value(days, 'days', '查询天数必须在 1 到 90 之间');
  }
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final results = <AlmanacSelectionResult>[];
  for (var offset = 0; offset < days; offset++) {
    final date = start.add(Duration(days: offset));
    if (date.isBefore(DateTime(1900)) || date.isAfter(DateTime(2100, 12, 31))) {
      continue;
    }
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final yi = List<String>.unmodifiable(lunar.getDayYi());
    final ji = List<String>.unmodifiable(lunar.getDayJi());
    final matchedYi = yi
        .where(
          (item) => activity.keywords.any(
            (keyword) => item.contains(keyword) || keyword.contains(item),
          ),
        )
        .toList(growable: false);
    final conflictsWithJi = ji.any(
      (item) => activity.keywords.any(
        (keyword) => item.contains(keyword) || keyword.contains(item),
      ),
    );
    final clashZodiac = lunar.getDayChongShengXiao();
    if (matchedYi.isEmpty ||
        conflictsWithJi ||
        yi.contains('诸事不宜') ||
        (excludedZodiac != null && clashZodiac == excludedZodiac)) {
      continue;
    }
    final solarTerm = lunar.getJieQi();
    final festivals = <String>{
      ...solar.getFestivals(),
      ...lunar.getFestivals(),
    }.toList(growable: false);
    results.add(
      AlmanacSelectionResult(
        date: date,
        weekday: '星期${solar.getWeekInChinese()}',
        lunarDate: '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}',
        dayGanZhi: lunar.getDayInGanZhiExact(),
        clash: lunar.getDayChongDesc(),
        clashZodiac: clashZodiac,
        matchedYi: List.unmodifiable(matchedYi),
        yi: yi,
        ji: ji,
        solarTerm: solarTerm.isEmpty ? null : solarTerm,
        festivals: List.unmodifiable(festivals),
      ),
    );
  }
  return List.unmodifiable(results);
}
