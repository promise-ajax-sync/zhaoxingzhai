import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('历史记录'), centerTitle: true),
      body: !repository.isLoaded
          ? const AppLoadingIndicator(message: '读取本地记录...')
          : AppPageContainer(
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (repository.records.isEmpty)
                    const AppEmptyState(
                      icon: Icons.history,
                      title: '还没有占卜记录',
                      subtitle: '完成一次小六壬或塔罗占卜后，结果会自动保存到这里。',
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
            _formatTime(record.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
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
