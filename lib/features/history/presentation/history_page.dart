import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/history/data/daily_hexagram_history.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

class HistoryPage extends StatefulWidget {
  final DivinationHistoryRepository repository;

  const HistoryPage({super.key, required this.repository});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepositoryChanged);
    widget.repository.ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_onRepositoryChanged);
      widget.repository.addListener(_onRepositoryChanged);
      widget.repository.ensureLoaded();
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录？'),
        content: const Text('此操作会删除当前设备保存的全部占卜记录，且无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.repository.clear();
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;

    // 外壳（AppShell）已提供顶栏与背景，这里只渲染页面内容。
    if (!repository.isLoaded) {
      return const AppLoadingIndicator(message: '读取本地记录...');
    }

    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeading(
            title: '历史记录',
            subtitle: '仅保存在当前设备，最多保留 100 条',
            trailing: repository.records.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空历史记录',
                    onPressed: _confirmClear,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
          ),
          if (repository.loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space4),
              child: Text(
                '部分记录读取失败：${repository.loadError}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (repository.records.isEmpty)
            const AppEmptyState(
              icon: Icons.history,
              title: '还没有占卜记录',
              subtitle: '完成一次占卜后，结果会自动保存到这里。',
            )
          else
            ...repository.records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space3),
                child: _HistoryRecordCard(
                  record: record,
                  onDelete: () => repository.delete(record.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  final DivinationHistoryRecord record;
  final VoidCallback onDelete;

  const _HistoryRecordCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isTarot = record.type == 'tarot';

    return AppCard(
      onTap: record.type == 'daily-hexagram'
          ? () => _showDailyHexagramDetails(context, record)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTarot ? Icons.style_outlined : Icons.nightlight_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space2,
                  vertical: AppTheme.space1,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(record.typeLabel),
              ),
              if (record.caseSnapshot != null) ...[
                const SizedBox(width: AppTheme.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space2,
                    vertical: AppTheme.space1,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 14),
                      const SizedBox(width: AppTheme.space1),
                      Text(record.caseSnapshot!.displayName),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                tooltip: '删除这条记录',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Text(record.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.space2),
          Text(
            record.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.space3),
          Text(
            '${_formatTime(record.createdAt)} · ${record.algorithmLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (record.type == 'daily-hexagram') ...[
            const SizedBox(height: AppTheme.space2),
            Text(
              '点击查看保存时的完整卦盘',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDailyHexagramDetails(
    BuildContext context,
    DivinationHistoryRecord record,
  ) async {
    final details = DailyHexagramHistoryDetails.tryParse(record);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('每日一卦 · ${record.algorithmLabel}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: details == null
                ? const Text('这条历史记录的数据不完整，无法恢复卦盘。原始摘要仍保留在历史列表中。')
                : _DailyHexagramHistoryContent(details: details),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

class _DailyHexagramHistoryContent extends StatelessWidget {
  const _DailyHexagramHistoryContent({required this.details});

  final DailyHexagramHistoryDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (details.dateKey.isNotEmpty) ...[
          Text('起卦日期：${details.dateKey}'),
          const SizedBox(height: AppTheme.space3),
        ],
        Container(
          padding: const EdgeInsets.all(AppTheme.space3),
          decoration: BoxDecoration(
            color: details.isLegacy
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(details.compatibilityNotice),
        ),
        const SizedBox(height: AppTheme.space4),
        _HistoricalHexagram(label: '本卦', value: details.original),
        if (details.changed != null)
          _HistoricalHexagram(label: '变卦', value: details.changed!),
        if (details.inter != null)
          _HistoricalHexagram(label: '互卦', value: details.inter!),
        if (details.yaos.length == 6) ...[
          const Divider(height: AppTheme.space5),
          Text('六爻：${details.yaos.join('、')}（初爻至上爻）'),
        ],
        if (details.takingSummary != null) ...[
          const Divider(height: AppTheme.space5),
          Text('取用规则', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.space2),
          Text(details.takingSummary!),
          for (final text in details.primaryTexts) Text('主取：$text'),
          for (final text in details.secondaryTexts) Text('辅看：$text'),
        ],
        if (details.movingLines.isNotEmpty) ...[
          const Divider(height: AppTheme.space5),
          Text('动爻', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.space2),
          for (final line in details.movingLines)
            Text('${line.name} · ${line.type}：${line.text}'),
        ],
      ],
    );
  }
}

class _HistoricalHexagram extends StatelessWidget {
  const _HistoricalHexagram({required this.label, required this.value});

  final String label;
  final HistoricalHexagramSnapshot value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label · ${value.symbol} ${value.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (value.upper.isNotEmpty || value.lower.isNotEmpty)
            Text('上${value.upper}下${value.lower}'),
          if (value.description.isNotEmpty) Text(value.description),
        ],
      ),
    );
  }
}
