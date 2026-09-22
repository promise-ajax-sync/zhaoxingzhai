import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/history/data/daily_hexagram_history.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/data/meihua_history.dart';
import 'package:zhaoxingzhai/features/history/data/history_sync_state.dart';

class HistoryPage extends StatefulWidget {
  final DivinationHistoryRepository repository;

  const HistoryPage({super.key, required this.repository});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _typeFilter;
  String? _roleFilter;

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
    _searchController.dispose();
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
    final allRecords = repository.records;
    final roleNames =
        allRecords
            .expand(_recordRoleNames)
            .where((name) => name.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final typeIds = allRecords.map((record) => record.type).toSet().toList()
      ..sort();
    final effectiveTypeFilter = typeIds.contains(_typeFilter)
        ? _typeFilter
        : null;
    final effectiveRoleFilter = roleNames.contains(_roleFilter)
        ? _roleFilter
        : null;
    final query = _searchController.text.trim().toLowerCase();
    final records = allRecords
        .where((record) {
          if (effectiveTypeFilter != null &&
              record.type != effectiveTypeFilter) {
            return false;
          }
          final names = _recordRoleNames(record);
          if (effectiveRoleFilter != null &&
              !names.contains(effectiveRoleFilter)) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final searchable = [
            record.typeLabel,
            record.title,
            record.summary,
            ...names,
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);

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
            subtitle: '本地优先保存并后台同步，最多保留 100 条',
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
          if (allRecords.isNotEmpty) ...[
            AppCard(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      key: const ValueKey('history-search'),
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: '搜索历史',
                        hintText: '标题、摘要或角色名称',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'history-type-filter-${effectiveTypeFilter ?? 'all'}',
                      ),
                      initialValue: effectiveTypeFilter ?? '',
                      decoration: const InputDecoration(labelText: '术式'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('全部术式')),
                        for (final type in typeIds)
                          DropdownMenuItem(
                            value: type,
                            child: Text(
                              allRecords
                                  .firstWhere((item) => item.type == type)
                                  .typeLabel,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () => _typeFilter = value == null || value.isEmpty
                            ? null
                            : value,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'history-role-filter-${effectiveRoleFilter ?? 'all'}',
                      ),
                      initialValue: effectiveRoleFilter ?? '',
                      decoration: const InputDecoration(labelText: '角色'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('全部角色')),
                        for (final name in roleNames)
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (value) => setState(
                        () => _roleFilter = value == null || value.isEmpty
                            ? null
                            : value,
                      ),
                    ),
                  ),
                  if (query.isNotEmpty ||
                      effectiveTypeFilter != null ||
                      effectiveRoleFilter != null)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _typeFilter = null;
                        _roleFilter = null;
                      }),
                      icon: const Icon(Icons.clear),
                      label: const Text('清除筛选'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space4),
          ],
          if (repository.records.isEmpty)
            const AppEmptyState(
              icon: Icons.history,
              title: '还没有占卜记录',
              subtitle: '完成一次占卜后，结果会自动保存到这里。',
            )
          else if (records.isEmpty)
            const AppEmptyState(
              icon: Icons.search_off,
              title: '没有匹配的历史记录',
              subtitle: '可以调整关键词、术式或角色筛选条件。',
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space3),
                child: _HistoryRecordCard(
                  record: record,
                  syncState: repository.syncStateFor(record.id),
                  onDelete: () => repository.delete(record.id),
                  onRetry: () => repository.retrySync(record.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static List<String> _recordRoleNames(DivinationHistoryRecord record) {
    final names = <String>[
      if (record.caseSnapshot != null) record.caseSnapshot!.displayName,
    ];
    final secondRaw = record.payload['secondCaseSnapshot'];
    if (secondRaw is Map) {
      final name = secondRaw['name'];
      if (name is String && name.trim().isNotEmpty) {
        names.add(name.trim());
      }
    }
    return names.toSet().toList(growable: false);
  }
}

class _HistoryRecordCard extends StatelessWidget {
  final DivinationHistoryRecord record;
  final HistorySyncState syncState;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const _HistoryRecordCard({
    required this.record,
    required this.syncState,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isTarot = record.type == 'tarot';
    final hasDetails =
        record.type == 'daily-hexagram' ||
        record.type == 'meihua' ||
        record.type == 'liuyao' ||
        record.type == 'bazi' ||
        record.type == 'ziwei';

    return AppCard(
      onTap: hasDetails
          ? () => switch (record.type) {
              'meihua' => _showMeihuaDetails(context, record),
              'liuyao' => _showLiuyaoDetails(context, record),
              'bazi' => _showBaziDetails(context, record),
              'ziwei' => _showZiweiDetails(context, record),
              _ => _showDailyHexagramDetails(context, record),
            }
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
          const SizedBox(height: AppTheme.space2),
          Row(
            children: [
              Icon(_syncIcon(syncState.status), size: 16),
              const SizedBox(width: AppTheme.space1),
              Text(
                _syncLabel(syncState.status),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (syncState.status == HistorySyncStatus.failed) ...[
                const SizedBox(width: AppTheme.space2),
                TextButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ],
          ),
          if (record.aiInterpretation != null) ...[
            const SizedBox(height: AppTheme.space2),
            Row(
              children: [
                Icon(
                  record.aiInterpretation!.usedFallback
                      ? Icons.offline_bolt_outlined
                      : Icons.auto_awesome,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.space1),
                Text(
                  record.aiInterpretation!.usedFallback
                      ? '已保存本地 AI 降级解读'
                      : '已保存 AI 解读 · ${record.aiInterpretation!.modelId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              record.aiInterpretation!.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (hasDetails) ...[
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

  static String _syncLabel(HistorySyncStatus status) => switch (status) {
    HistorySyncStatus.localOnly => '仅本地',
    HistorySyncStatus.pending => '等待同步',
    HistorySyncStatus.syncing => '正在同步',
    HistorySyncStatus.synced => '已同步',
    HistorySyncStatus.failed => '同步失败',
    HistorySyncStatus.pendingDelete => '等待删除同步',
  };

  static IconData _syncIcon(HistorySyncStatus status) => switch (status) {
    HistorySyncStatus.localOnly => Icons.phone_android_outlined,
    HistorySyncStatus.pending => Icons.schedule_outlined,
    HistorySyncStatus.syncing => Icons.sync,
    HistorySyncStatus.synced => Icons.cloud_done_outlined,
    HistorySyncStatus.failed => Icons.cloud_off_outlined,
    HistorySyncStatus.pendingDelete => Icons.delete_outline,
  };

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

  Future<void> _showMeihuaDetails(
    BuildContext context,
    DivinationHistoryRecord record,
  ) async {
    final details = MeihuaHistoryDetails.tryParse(record);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('梅花易数 · ${record.algorithmLabel}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: details == null
                ? const Text('这条历史记录的数据不完整，无法恢复卦盘。原始摘要仍保留在历史列表中。')
                : _MeihuaHistoryContent(details: details),
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

  Future<void> _showLiuyaoDetails(
    BuildContext context,
    DivinationHistoryRecord record,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('六爻排盘 · ${record.algorithmLabel}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: _LiuyaoHistoryContent(payload: record.payload),
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

  Future<void> _showBaziDetails(
    BuildContext context,
    DivinationHistoryRecord record,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('四柱八字 · ${record.algorithmLabel}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: _BaziHistoryContent(payload: record.payload),
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

  Future<void> _showZiweiDetails(
    BuildContext context,
    DivinationHistoryRecord record,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('紫微斗数 · ${record.algorithmLabel}'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: _ZiweiHistoryContent(payload: record.payload),
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

class _ZiweiHistoryContent extends StatelessWidget {
  const _ZiweiHistoryContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final foundation = payload['foundation'] is Map
        ? Map<String, dynamic>.from(payload['foundation'] as Map)
        : const <String, dynamic>{};
    final palaces = payload['palaces'] is List
        ? (payload['palaces'] as List).whereType<Map>().toList()
        : const <Map>[];
    final limits = payload['limits'] is Map
        ? Map<String, dynamic>.from(payload['limits'] as Map)
        : const <String, dynamic>{};
    final decades = limits['decades'] is List
        ? (limits['decades'] as List).whereType<Map>().toList()
        : const <Map>[];
    final relations = payload['relations'] is List
        ? (payload['relations'] as List).whereType<Map>().toList()
        : const <Map>[];
    final lifeRelations = _lifeRelations(relations);
    final decadeTransformations = payload['decadeTransformations'] is List
        ? (payload['decadeTransformations'] as List).whereType<Map>().toList()
        : const <Map>[];
    final annual = payload['annual'] is Map
        ? Map<String, dynamic>.from(payload['annual'] as Map)
        : const <String, dynamic>{};
    if (palaces.isEmpty) return const Text('这条紫微历史记录的数据不完整。');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '生年：${payload['yearStem'] ?? ''}${payload['yearBranch'] ?? ''} · '
          '命宫${foundation['lifeBranch'] ?? '未记录'} · '
          '身宫${foundation['bodyBranch'] ?? '未记录'} · '
          '${foundation['fiveElementBureau'] ?? '未记录'}',
        ),
        const SizedBox(height: AppTheme.space3),
        for (final palace in palaces) ...[
          Text(
            '${palace['name'] ?? ''}（${palace['ganzhi'] ?? palace['branch'] ?? ''}）：'
            '${_starNames(palace['stars'])}',
          ),
          const SizedBox(height: AppTheme.space2),
        ],
        const Divider(),
        if (lifeRelations != null) ...[
          Text(_relationSummary(lifeRelations)),
          const SizedBox(height: AppTheme.space2),
        ],
        Text(
          '大限：${limits['directionLabel'] ?? '未记录'} · '
          '${limits['startNominalAge'] ?? '未记录'}岁起限',
        ),
        if (decades.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space2),
          Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space2,
            children: [
              for (final decade in decades)
                Text(
                  '${decade['startNominalAge']}—${decade['endNominalAge']}岁 '
                  '${(decade['palace'] as Map?)?['name'] ?? ''}',
                ),
            ],
          ),
        ],
        if (decadeTransformations.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space3),
          Text('首限四化：${_transformationSummary(decadeTransformations.first)}'),
        ],
        if (annual.isNotEmpty) ...[
          const Divider(height: AppTheme.space5),
          Text(
            '流年：${annual['lunarYear'] ?? '未记录'} 农历年 · '
            '${annual['yearStem'] ?? ''}${annual['yearBranch'] ?? ''} · '
            '虚岁 ${annual['nominalAge'] ?? '未记录'}',
          ),
          Text('流年四化：${_annualTransformations(annual)}'),
        ],
      ],
    );
  }

  static String _starNames(Object? raw) {
    if (raw is! List) return '暂无';
    final names = raw
        .whereType<Map>()
        .map((star) {
          final name = star['name'] ?? '';
          final mutagen = star['mutagen'];
          final brightness = star['brightness'];
          final brightnessLabel = brightness == null ? '' : '（$brightness）';
          return mutagen == null
              ? '$name$brightnessLabel'
              : '$name$brightnessLabel化$mutagen';
        })
        .where((name) => name.isNotEmpty)
        .join('、');
    return names.isEmpty ? '暂无' : names;
  }

  static Map? _lifeRelations(List<Map> relations) {
    for (final relation in relations) {
      final source = relation['source'];
      if (source is Map && source['isLife'] == true) {
        return relation;
      }
    }
    return null;
  }

  static String _relationSummary(Map relation) {
    final trines = relation['trines'] is List
        ? (relation['trines'] as List)
              .whereType<Map>()
              .map((e) => e['name'])
              .whereType<String>()
              .join('、')
        : '';
    final opposite = relation['opposite'] is Map
        ? (relation['opposite'] as Map)['name'] ?? '未记录'
        : '未记录';
    return '命宫三方：$trines；对宫：$opposite';
  }

  static String _transformationSummary(Map transformation) {
    if (transformation['placements'] is! List) return '未记录';
    return (transformation['placements'] as List)
        .whereType<Map>()
        .map((item) {
          final destination = item['destination'] is Map
              ? (item['destination'] as Map)['name'] ?? ''
              : '';
          return '${item['starName'] ?? ''}化${item['mutagen'] ?? ''}入$destination';
        })
        .join('、');
  }

  static String _annualTransformations(Map<String, dynamic> annual) {
    final transformations = annual['transformations'];
    if (transformations is! List) return '未记录';
    final summary = transformations
        .whereType<Map>()
        .map((item) {
          final destination = item['destination'] is Map
              ? (item['destination'] as Map)['name'] ?? ''
              : '';
          return '${item['starName'] ?? ''}化${item['mutagen'] ?? ''}入$destination';
        })
        .join('、');
    return summary.isEmpty ? '未记录' : summary;
  }
}

class _BaziHistoryContent extends StatelessWidget {
  const _BaziHistoryContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final pillars = payload['pillars'] is List
        ? (payload['pillars'] as List).whereType<Map>().toList()
        : const <Map>[];
    final cycles = payload['luckCycles'] is List
        ? (payload['luckCycles'] as List).whereType<Map>().toList()
        : const <Map>[];
    if (pillars.isEmpty) return const Text('这条八字历史记录的数据不完整。');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '四柱：${pillars.map((p) => p['ganzhi'] ?? '${p['gan'] ?? ''}${p['zhi'] ?? ''}').join('  ')}',
        ),
        const SizedBox(height: AppTheme.space2),
        Text('日主：${payload['dayMaster'] ?? '未记录'}'),
        if (payload['usedLunarConversion'] == true) ...[
          const Text('出生历法：农历已转换为公历'),
        ],
        if (payload['usedTrueSolarTime'] == true) ...[
          Text('真太阳时已修正：${payload['trueSolarCorrectionMinutes'] ?? 0} 分钟'),
        ],
        if (payload['taiYuan'] != null ||
            payload['mingGong'] != null ||
            payload['shenGong'] != null)
          Text(
            '胎元：${payload['taiYuan'] ?? '未记录'} · '
            '命宫：${payload['mingGong'] ?? '未记录'} · '
            '身宫：${payload['shenGong'] ?? '未记录'}',
          ),
        if (cycles.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space2),
          const Text('大运：'),
          for (final cycle in cycles)
            Text(
              '${cycle['startAge'] ?? ''}—${cycle['endAge'] ?? ''}岁：${cycle['ganzhi'] ?? ''}',
            ),
        ],
      ],
    );
  }
}

class _LiuyaoHistoryContent extends StatelessWidget {
  const _LiuyaoHistoryContent({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final original = _map(payload['original']);
    final changed = _map(payload['changed']);
    final inter = _map(payload['inter']);
    final opposite = _map(payload['opposite']);
    final reversed = _map(payload['reversed']);
    final calendar = _map(payload['calendar']);
    final advanced = _map(payload['advanced']);
    final lines = payload['lines'] is List
        ? (payload['lines'] as List).whereType<Map>().toList(growable: false)
        : const <Map>[];
    if (original == null || changed == null || lines.length != 6) {
      return const Text('这条历史记录的数据不完整，无法恢复六爻盘。原始摘要仍保留在历史列表中。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${original['symbol'] ?? ''} ${original['name']} → ${changed['name']}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.space2),
        Text(
          '${original['palace']}宫${payload['palaceElement']} · ${payload['palaceStage']} · '
          '世${payload['shiPosition']}应${payload['yingPosition']}',
        ),
        if (payload['focusRelation'] != null)
          Text('观察重点：${payload['focusRelation']}'),
        if (calendar != null)
          Text(
            '${calendar['solarTermMonthGanzhi']}月 ${calendar['dayGanzhi']}日 '
            '${calendar['hourGanzhi']}时 · 旬空${(payload['voidBranches'] as List?)?.join('') ?? ''}',
          ),
        const Divider(height: AppTheme.space5),
        for (final raw in lines.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space2),
            child: Text(
              '${raw['spirit']} · ${raw['relation']} · ${raw['stem']}${raw['branch']}${raw['element']} · '
              '${raw['label']}${raw['isShi'] == true ? ' · 世' : ''}'
              '${raw['isYing'] == true ? ' · 应' : ''}'
              '${raw['isVoid'] == true ? ' · 空' : ''}'
              '${raw['moving'] == true ? ' · 动' : ''}',
            ),
          ),
        const Divider(height: AppTheme.space5),
        Text(
          '互卦：${inter?['name'] ?? '未保存'} · 错卦：${opposite?['name'] ?? '未保存'} · '
          '综卦：${reversed?['name'] ?? '未保存'}',
        ),
        const Divider(height: AppTheme.space5),
        if (advanced == null)
          const Text('这是六爻 v1 历史：保留基础纳甲、六亲、六神与世应，不使用 v2 高级规则重新计算。')
        else ...[
          Text('旺衰与冲合', style: Theme.of(context).textTheme.titleMedium),
          for (final item in _maps(advanced['lineAnalyses']))
            Text(
              '${item['position']}爻：${(item['tags'] as List?)?.join(' · ') ?? ''}',
            ),
          if (_strings(advanced['combinations']).isNotEmpty)
            Text('六合：${_strings(advanced['combinations']).join('；')}'),
          if (_strings(advanced['clashes']).isNotEmpty)
            Text('六冲：${_strings(advanced['clashes']).join('；')}'),
          if (_strings(advanced['threeHarmony']).isNotEmpty)
            Text('三合：${_strings(advanced['threeHarmony']).join('；')}'),
          if (_maps(advanced['hiddenSpirits']).isNotEmpty)
            Text(
              '伏神与飞神：${_maps(advanced['hiddenSpirits']).map((item) => '${item['position']}爻伏${item['relation']}${item['stem']}${item['branch']}${item['element']}，飞${item['flyingRelation']}${item['flyingBranch']}').join('；')}',
            ),
          if (advanced['focusSummary'] is String)
            Text(advanced['focusSummary'] as String),
        ],
        if ((payload['question'] as String?)?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.space3),
          Text('占问：${payload['question']}'),
        ],
      ],
    );
  }

  static Map<String, dynamic>? _map(Object? raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : null;

  static List<Map<String, dynamic>> _maps(Object? raw) => raw is List
      ? raw
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList(growable: false)
      : const [];

  static List<String> _strings(Object? raw) =>
      raw is List ? raw.whereType<String>().toList(growable: false) : const [];
}

class _MeihuaHistoryContent extends StatelessWidget {
  const _MeihuaHistoryContent({required this.details});

  final MeihuaHistoryDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          details.methodLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.space3),
        _HistoricalHexagram(label: '本卦', value: details.original),
        _HistoricalHexagram(label: '互卦', value: details.inter),
        _HistoricalHexagram(label: '变卦', value: details.changed),
        const Divider(height: AppTheme.space5),
        Text('${details.movingLine.name}：${details.movingLine.text}'),
        Text('体卦：${details.tiGua.name} · ${details.tiGua.element}'),
        Text('用卦：${details.yongGua.name} · ${details.yongGua.element}'),
        Text('体用关系：${details.relation}'),
        if (details.consultationContext != null) ...[
          const Divider(height: AppTheme.space5),
          Text('占问背景', style: Theme.of(context).textTheme.titleMedium),
          Text('分类：${details.consultationContext!.topicLabel}'),
          if (details.consultationContext!.question.isNotEmpty)
            Text('占问：${details.consultationContext!.question}'),
          if (details.consultationContext!.observation.isNotEmpty)
            Text('物象：${details.consultationContext!.observation}'),
          if (details.consultationContext!.soundSource.isNotEmpty)
            Text('声音来源：${details.consultationContext!.soundSource}'),
          if (details.consultationContext!.directionNote.isNotEmpty)
            Text('方位说明：${details.consultationContext!.directionNote}'),
        ],
        if (details.calculation['lunarYearGanzhi'] != null) ...[
          const Divider(height: AppTheme.space5),
          Text(
            '农历${details.calculation['lunarYearGanzhi']}年 '
            '${details.calculation['month']}月${details.calculation['day']}日 · '
            '${details.calculation['timeZhi']}时',
          ),
          Text(
            '上卦${details.calculation['upperTrigramIndex']}、'
            '下卦${details.calculation['lowerTrigramIndex']}、'
            '动爻${details.calculation['movingYaoIndex']}',
          ),
        ],
        if (details.randomSamples.isNotEmpty) ...[
          const Divider(height: AppTheme.space5),
          Text('随机轨迹已保存：${details.randomSamples.length} 个样本'),
        ],
        if (details.interpretation != null) ...[
          const Divider(height: AppTheme.space5),
          Text(
            '保存时的现代白话解读 · v${details.interpretation!.version}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '问题回应（${details.interpretation!.questionIntentLabel}）：${details.interpretation!.directAnswer}',
          ),
          Text('判断依据：${details.interpretation!.evidenceSummary}'),
          if (details.interpretation!.evidence.counterEvidence.isNotEmpty)
            Text(
              '反证：${details.interpretation!.evidence.counterEvidence.map((item) => item.detail).join('；')}',
            ),
          if (details.interpretation!.evidence.limitations.isNotEmpty)
            Text(
              '限制：${details.interpretation!.evidence.limitations.map((item) => item.detail).join('；')}',
            ),
          Text('传统概览：${details.interpretation!.traditionalOverview}'),
          Text('当前处境：${details.interpretation!.situation}'),
          Text('内部过程：${details.interpretation!.process}'),
          Text('变化趋势：${details.interpretation!.trend}'),
          Text(
            '${details.interpretation!.topicLabel}提示：${details.interpretation!.topicGuidance}',
          ),
          Text('行动建议：${details.interpretation!.action}'),
          Text('风险提醒：${details.interpretation!.riskReminder}'),
        ],
      ],
    );
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
        if (details.coinThrows.length == 6) ...[
          const SizedBox(height: AppTheme.space2),
          Text(
            '三钱记录：${details.coinThrows.map((coins) => coins.join('+')).join('；')}',
          ),
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
        if (details.interpretation != null) ...[
          const Divider(height: AppTheme.space5),
          Text(
            '保存时的分项解读 · v${details.interpretation!.version}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space2),
          Text('传统概览：${details.interpretation!.traditionalOverview}'),
          Text('当前处境：${details.interpretation!.situation}'),
          Text('内在条件：${details.interpretation!.innerContext}'),
          Text('变化趋势：${details.interpretation!.trend}'),
          Text('行动节奏：${details.interpretation!.pace}'),
          Text('风险提醒：${details.interpretation!.riskReminder}'),
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
