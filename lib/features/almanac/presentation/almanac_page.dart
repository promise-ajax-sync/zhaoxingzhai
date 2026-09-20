import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/almanac/domain/almanac_date_selection.dart';
import 'package:zhaoxingzhai/features/almanac/domain/traditional_almanac_day.dart';

class AlmanacPage extends StatefulWidget {
  const AlmanacPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<AlmanacPage> createState() => _AlmanacPageState();
}

enum _AlmanacSection { day, hours, selection }

class _AlmanacPageState extends State<AlmanacPage> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  AlmanacSelectionActivity _selectionActivity =
      almanacSelectionActivities.first;
  int _selectionDays = 30;
  String? _selectionZodiac;
  List<AlmanacSelectionResult> _selectionResults = const [];
  bool _hasSearchedDates = false;
  _AlmanacSection _section = _AlmanacSection.day;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _displayedMonth = DateTime(initial.year, initial.month);
  }

  void _selectDate(DateTime value) {
    setState(() {
      _selectedDate = DateTime(value.year, value.month, value.day);
      _displayedMonth = DateTime(value.year, value.month);
    });
  }

  void _moveDay(int offset) {
    final candidate = _selectedDate.add(Duration(days: offset));
    if (candidate.isBefore(DateTime(1900)) ||
        candidate.isAfter(DateTime(2100, 12, 31))) {
      return;
    }
    _selectDate(candidate);
  }

  void _moveMonth(int offset) {
    final candidate = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + offset,
    );
    if (candidate.isBefore(DateTime(1900)) ||
        candidate.isAfter(DateTime(2100, 12))) {
      return;
    }
    final lastDay = DateTime(candidate.year, candidate.month + 1, 0).day;
    final targetDay = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
    _selectDate(DateTime(candidate.year, candidate.month, targetDay));
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      helpText: '选择黄历日期',
    );
    if (value != null && mounted) {
      _selectDate(value);
    }
  }

  void _searchDates() {
    setState(() {
      _selectionResults = findAlmanacDates(
        startDate: _selectedDate,
        days: _selectionDays,
        activity: _selectionActivity,
        excludedZodiac: _selectionZodiac,
      );
      _hasSearchedDates = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = getTraditionalAlmanacDay(_selectedDate);
    final colors = Theme.of(context).colorScheme;
    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeading(
            title: '传统黄历',
            subtitle: '查看公农历、节气、干支、宜忌与传统日课信息',
            trailing: TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('选择日期'),
            ),
          ),
          _MonthCalendar(
            displayedMonth: _displayedMonth,
            selectedDate: _selectedDate,
            onPreviousMonth: () => _moveMonth(-1),
            onNextMonth: () => _moveMonth(1),
            onSelectDate: _selectDate,
          ),
          const SizedBox(height: AppTheme.space4),
          _DateNavigation(
            day: day,
            onPrevious: () => _moveDay(-1),
            onToday: () {
              final now = DateTime.now();
              _selectDate(now);
            },
            onNext: () => _moveDay(1),
          ),
          const SizedBox(height: AppTheme.space4),
          SegmentedButton<_AlmanacSection>(
            key: const ValueKey('almanac-section-selector'),
            segments: const [
              ButtonSegment(
                value: _AlmanacSection.day,
                icon: Icon(Icons.today_outlined),
                label: Text('当日详情'),
              ),
              ButtonSegment(
                value: _AlmanacSection.hours,
                icon: Icon(Icons.schedule_outlined),
                label: Text('十二时辰'),
              ),
              ButtonSegment(
                value: _AlmanacSection.selection,
                icon: Icon(Icons.travel_explore),
                label: Text('传统择日'),
              ),
            ],
            selected: {_section},
            onSelectionChanged: (value) =>
                setState(() => _section = value.first),
          ),
          const SizedBox(height: AppTheme.space4),
          if (_section == _AlmanacSection.day) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final yiCard = _ActivityCard(
                  title: '宜',
                  icon: Icons.check_circle_outline,
                  color: colors.primary,
                  background: colors.primaryContainer.withValues(alpha: 0.34),
                  items: day.yi,
                );
                final jiCard = _ActivityCard(
                  title: '忌',
                  icon: Icons.do_not_disturb_alt_outlined,
                  color: colors.error,
                  background: colors.errorContainer.withValues(alpha: 0.28),
                  items: day.ji,
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: yiCard),
                          const SizedBox(width: 16),
                          Expanded(child: jiCard),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(width: double.infinity, child: yiCard),
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: jiCard),
                        ],
                      );
              },
            ),
            const SizedBox(height: AppTheme.space4),
            _DetailsCard(day: day),
          ],
          if (_section == _AlmanacSection.hours)
            _TimePeriodsCard(periods: day.timePeriods),
          if (_section == _AlmanacSection.selection)
            _DateSelectionCard(
              startDate: _selectedDate,
              activity: _selectionActivity,
              days: _selectionDays,
              zodiac: _selectionZodiac,
              results: _selectionResults,
              hasSearched: _hasSearchedDates,
              onActivityChanged: (value) {
                setState(() {
                  _selectionActivity = value;
                  _hasSearchedDates = false;
                });
              },
              onDaysChanged: (value) {
                setState(() {
                  _selectionDays = value;
                  _hasSearchedDates = false;
                });
              },
              onZodiacChanged: (value) {
                setState(() {
                  _selectionZodiac = value;
                  _hasSearchedDates = false;
                });
              },
              onSearch: _searchDates,
              onSelectDate: _selectDate,
            ),
          const SizedBox(height: AppTheme.space4),
          AppCard(
            color: colors.surfaceContainerLow,
            child: Text(
              '说明：本页依据 lunar 开源历法库展示传统民俗信息，仅供文化研究与日常参考。'
              '宜忌、吉神凶煞等属于传统择日体系，不代表现实结果保证，也不能替代医疗、法律、财务等专业判断。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.displayedMonth,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  @override
  Widget build(BuildContext context) {
    final cells = buildAlmanacMonthGrid(
      displayedMonth.year,
      displayedMonth.month,
    );
    final now = DateTime.now();
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('almanac-previous-month'),
                onPressed: onPreviousMonth,
                tooltip: '上个月',
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${displayedMonth.year}年${displayedMonth.month}月',
                  key: const ValueKey('almanac-month-title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                key: const ValueKey('almanac-next-month'),
                onPressed: onNextMonth,
                tooltip: '下个月',
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in ['日', '一', '二', '三', '四', '五', '六'])
                Expanded(child: Center(child: Text(label))),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: constraints.maxWidth >= 700 ? 1.6 : 1.05,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final cell = cells[index];
                final inMonth = cell.date.month == displayedMonth.month;
                final selected = _sameDate(cell.date, selectedDate);
                final today = _sameDate(cell.date, now);
                return Material(
                  color: selected
                      ? colors.primaryContainer
                      : today
                      ? colors.secondaryContainer.withValues(alpha: 0.55)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: InkWell(
                    key: ValueKey(
                      'almanac-date-${cell.date.year}-${cell.date.month}-${cell.date.day}',
                    ),
                    onTap: () => onSelectDate(cell.date),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${cell.date.day}',
                            style: TextStyle(
                              height: 1.05,
                              fontWeight: selected || today
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: inMonth
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant.withValues(
                                      alpha: 0.45,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cell.lunarLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  height: 1.05,
                                  color: cell.isSpecial
                                      ? colors.primary
                                      : inMonth
                                      ? colors.onSurfaceVariant
                                      : colors.onSurfaceVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelectionCard extends StatelessWidget {
  const _DateSelectionCard({
    required this.startDate,
    required this.activity,
    required this.days,
    required this.zodiac,
    required this.results,
    required this.hasSearched,
    required this.onActivityChanged,
    required this.onDaysChanged,
    required this.onZodiacChanged,
    required this.onSearch,
    required this.onSelectDate,
  });

  final DateTime startDate;
  final AlmanacSelectionActivity activity;
  final int days;
  final String? zodiac;
  final List<AlmanacSelectionResult> results;
  final bool hasSearched;
  final ValueChanged<AlmanacSelectionActivity> onActivityChanged;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String?> onZodiacChanged;
  final VoidCallback onSearch;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleResults = results.take(12).toList(growable: false);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '传统择日参考',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '从当前选中日期开始，按黄历“宜”筛选事项；可排除与你生肖相冲的日期。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<AlmanacSelectionActivity>(
                  key: const ValueKey('almanac-selection-activity'),
                  initialValue: activity,
                  decoration: const InputDecoration(labelText: '择日事项'),
                  items: [
                    for (final item in almanacSelectionActivities)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onActivityChanged(value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<int>(
                  key: const ValueKey('almanac-selection-days'),
                  initialValue: days,
                  decoration: const InputDecoration(labelText: '查询范围'),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('未来 15 天')),
                    DropdownMenuItem(value: 30, child: Text('未来 30 天')),
                    DropdownMenuItem(value: 60, child: Text('未来 60 天')),
                    DropdownMenuItem(value: 90, child: Text('未来 90 天')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onDaysChanged(value);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('almanac-selection-zodiac'),
                  initialValue: zodiac ?? '',
                  decoration: const InputDecoration(labelText: '本人生肖'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('不限生肖')),
                    for (final item in almanacZodiacs)
                      DropdownMenuItem(value: item, child: Text('属$item')),
                  ],
                  onChanged: (value) => onZodiacChanged(
                    value == null || value.isEmpty ? null : value,
                  ),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('almanac-selection-search'),
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('开始筛选'),
              ),
            ],
          ),
          if (hasSearched) ...[
            const Divider(height: 32),
            if (results.isEmpty)
              const _SelectionEmptyState()
            else ...[
              Text(
                '从 ${startDate.year}年${startDate.month}月${startDate.day}日起，'
                '$days 天内找到 ${results.length} 个参考日期',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              for (final result in visibleResults)
                _SelectionResultTile(
                  result: result,
                  onTap: () => onSelectDate(result.date),
                ),
              if (results.length > visibleResults.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '为保持页面清晰，仅展示前 ${visibleResults.length} 个结果。'
                    '可缩小查询范围或选择结果后继续查看当日详情。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SelectionEmptyState extends StatelessWidget {
  const _SelectionEmptyState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
    ),
    child: const Row(
      children: [
        Icon(Icons.event_busy_outlined),
        SizedBox(width: 10),
        Expanded(child: Text('当前范围内没有符合条件的日期，可扩大范围或取消生肖排除。')),
      ],
    ),
  );
}

class _SelectionResultTile extends StatelessWidget {
  const _SelectionResultTile({required this.result, required this.onTap});

  final AlmanacSelectionResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badges = [
      if (result.solarTerm != null) result.solarTerm!,
      ...result.festivals,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          key: ValueKey(
            'almanac-selection-result-${result.date.year}-${result.date.month}-${result.date.day}',
          ),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Text('${result.date.day}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.dateLabel} · ${result.weekday} · '
                        '${result.lunarDate}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '宜：${result.matchedYi.join('、')} · '
                        '${result.dayGanZhi}日 · '
                        '冲${result.clashZodiac} ${result.clash}',
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final badge in badges)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(badge),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateNavigation extends StatelessWidget {
  const _DateNavigation({
    required this.day,
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final TraditionalAlmanacDay day;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('almanac-previous-day'),
              onPressed: onPrevious,
              tooltip: '前一天',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    day.solarDateLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('${day.weekday} · ${day.lunarDate} · ${day.zodiac}年'),
                  if (day.solarTerm != null) ...[
                    const SizedBox(height: 6),
                    Chip(
                      avatar: const Icon(Icons.eco_outlined, size: 16),
                      label: Text('今日节气：${day.solarTerm}'),
                    ),
                  ],
                  if (day.festivals.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final festival in day.festivals)
                          Chip(
                            avatar: Icon(_festivalIcon(festival), size: 16),
                            label: Text(festival),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('almanac-next-day'),
              onPressed: onNext,
              tooltip: '后一天',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: '年柱', value: day.yearGanzhi),
            _InfoChip(label: '月柱', value: day.monthGanzhi),
            _InfoChip(label: '日柱', value: day.dayGanzhi),
            TextButton(onPressed: onToday, child: const Text('回到今天')),
          ],
        ),
      ],
    ),
  );
}

IconData _festivalIcon(String festival) {
  if (festival.contains('春节') ||
      festival.contains('除夕') ||
      festival.contains('元宵')) {
    return Icons.emoji_objects;
  }
  if (festival.contains('中秋') || festival.contains('七夕')) {
    return Icons.nightlight;
  }
  if (festival.contains('端午')) {
    return Icons.sailing;
  }
  if (festival.contains('国庆') ||
      festival.contains('建党') ||
      festival.contains('建军')) {
    return Icons.flag;
  }
  if (festival.contains('劳动')) {
    return Icons.handyman;
  }
  if (festival.contains('儿童')) {
    return Icons.child_care;
  }
  if (festival.contains('教师')) {
    return Icons.school;
  }
  if (festival.contains('妇女') ||
      festival.contains('母亲') ||
      festival.contains('父亲')) {
    return Icons.family_restroom;
  }
  if (festival.contains('植树') ||
      festival.contains('清明') ||
      festival.contains('重阳')) {
    return Icons.park;
  }
  if (festival.contains('情人')) {
    return Icons.favorite_border;
  }
  if (festival.contains('圣诞')) {
    return Icons.card_giftcard;
  }
  if (festival.contains('元旦') || festival.contains('新年')) {
    return Icons.auto_awesome;
  }
  if (festival.contains('青年')) {
    return Icons.groups;
  }
  return Icons.celebration_outlined;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
    ),
    child: Text('$label · $value'),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final List<String> items;

  @override
  Widget build(BuildContext context) => AppCard(
    color: background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items) Chip(label: Text(item)),
            if (items.isEmpty) const Text('无特别记载'),
          ],
        ),
      ],
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.day});
  final TraditionalAlmanacDay day;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('传统日课信息', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _DetailWrap(
          items: [
            ('十二值星', day.dutyOfficer),
            ('天神', '${day.heavenlyGod} · ${day.heavenlyGodLuck}'),
            ('二十八宿', '${day.mansion}宿 · ${day.mansionLuck}'),
            ('日纳音', day.dayNaYin),
            ('胎神方位', day.fetalGod),
            ('冲', day.clash),
            ('煞', day.sha),
            ('喜神方位', day.joyDirection),
            ('财神方位', day.wealthDirection),
            ('福神方位', day.fortuneDirection),
          ],
        ),
        const Divider(height: 32),
        Text('吉神：${day.auspiciousGods.join('、')}'),
        const SizedBox(height: 8),
        Text('凶煞：${day.inauspiciousSpirits.join('、')}'),
        const SizedBox(height: 8),
        Text('彭祖百忌：${day.pengzu}'),
        if (day.solarFestivals.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('公历节日：${day.solarFestivals.join('、')}'),
        ],
        if (day.lunarFestivals.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('农历节日：${day.lunarFestivals.join('、')}'),
        ],
        const Divider(height: 32),
        Text('上一节气：${day.previousSolarTerm}'),
        const SizedBox(height: 8),
        Text('下一节气：${day.nextSolarTerm}'),
      ],
    ),
  );
}

class _TimePeriodsCard extends StatelessWidget {
  const _TimePeriodsCard({required this.periods});

  final List<AlmanacTimePeriod> periods;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('十二时辰', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '展开时辰可查看传统时宜、时忌与冲煞信息。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final (index, period) in periods.indexed)
          ExpansionTile(
            key: ValueKey('almanac-time-$index-${period.label}'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 14),
            title: Text('${period.label} · ${period.ganZhi} · ${period.luck}'),
            subtitle: Text('${period.range} · ${period.heavenlyGod}'),
            children: [
              _DetailWrap(
                items: [
                  ('冲', period.clash),
                  ('煞', period.sha),
                  ('纳音', period.naYin),
                ],
              ),
              const SizedBox(height: 12),
              _TimeActivity(label: '时宜', items: period.yi),
              const SizedBox(height: 8),
              _TimeActivity(label: '时忌', items: period.ji),
            ],
          ),
      ],
    ),
  );
}

class _TimeActivity extends StatelessWidget {
  const _TimeActivity({required this.label, required this.items});

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 42,
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
      Expanded(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in items) Chip(label: Text(item)),
            if (items.isEmpty) const Text('无特别记载'),
          ],
        ),
      ),
    ],
  );
}

class _DetailWrap extends StatelessWidget {
  const _DetailWrap({required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final item in items)
        Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.$1, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(item.$2, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
    ],
  );
}
