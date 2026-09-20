/// 案例页：案例的列表、选择、新建与编辑。
///
/// 案例与历史是两个独立概念——这里只管理「可以拿去算什么」，
/// 不展示任何占卜结果。
library;

import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/cases/case_selection.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';

class CasesPage extends StatefulWidget {
  const CasesPage({
    super.key,
    required this.repository,
    required this.selection,
  });

  final CaseRepository repository;
  final CaseSelectionController selection;

  @override
  State<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onChanged);
    widget.selection.addListener(_onChanged);
    widget.repository.ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant CasesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_onChanged);
      widget.repository.addListener(_onChanged);
      widget.repository.ensureLoaded();
    }
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_onChanged);
      widget.selection.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onChanged);
    widget.selection.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final draft = await showDialog<CaseProfile>(
      context: context,
      builder: (context) => const _CaseEditorDialog(),
    );
    if (draft == null || !mounted) return;
    final saved = await widget.repository.add(draft);
    widget.selection.select(saved.id);
  }

  Future<void> _edit(CaseProfile profile) async {
    final draft = await showDialog<CaseProfile>(
      context: context,
      builder: (context) => _CaseEditorDialog(initial: profile),
    );
    if (draft == null || !mounted) return;
    await widget.repository.update(draft);
  }

  Future<void> _confirmDelete(CaseProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除角色？'),
        content: Text(
          '将删除「${profile.name}」。\n'
          '已经保存的历史记录不受影响，它们保存的是当时的快照。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.repository.delete(profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;

    if (!repository.isLoaded) {
      return const AppLoadingIndicator(message: '读取本地角色...');
    }

    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeading(
            title: '角色',
            subtitle: '角色是可反复使用的个人资料，历史记录保存的是当时的资料快照',
            trailing: FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('新建角色'),
            ),
          ),
          if (repository.loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space4),
              child: Text(
                '部分角色读取失败：${repository.loadError}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (repository.cases.isEmpty)
            const AppEmptyState(
              icon: Icons.book_outlined,
              title: '还没有角色',
              subtitle: '新建一个角色后，排盘、合盘等需要出生资料的功能就能直接引用它。',
            )
          else
            ...repository.cases.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space3),
                child: _CaseCard(
                  profile: profile,
                  selected: widget.selection.selectedId == profile.id,
                  onSelect: () => widget.selection.select(
                    widget.selection.selectedId == profile.id
                        ? null
                        : profile.id,
                  ),
                  onEdit: () => _edit(profile),
                  onDelete: () => _confirmDelete(profile),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.profile,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CaseProfile profile;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return AppCard(
      onTap: onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? accent : null,
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: '编辑角色',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: '删除角色',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Text(profile.summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppTheme.space2),
          Wrap(
            spacing: AppTheme.space2,
            children: [
              _Chip(label: profile.gender.label),
              _Chip(label: profile.timezoneId),
              if (profile.hasLocation) const _Chip(label: '含经纬度'),
            ],
          ),
          if (profile.note.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space2),
            Text(profile.note, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// 案例编辑对话框。
///
/// 新建与编辑共用；返回 `null` 表示取消。
class _CaseEditorDialog extends StatefulWidget {
  const _CaseEditorDialog({this.initial});

  final CaseProfile? initial;

  @override
  State<_CaseEditorDialog> createState() => _CaseEditorDialogState();
}

class _CaseEditorDialogState extends State<_CaseEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late final TextEditingController _placeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _timezoneController;

  late CaseGender _gender;
  late CaseCalendarType _calendarType;
  late bool _isLeapMonth;
  late DateTime _birthDateTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _noteController = TextEditingController(text: initial?.note ?? '');
    _placeController = TextEditingController(text: initial?.placeName ?? '');
    _longitudeController = TextEditingController(
      text: initial?.longitude?.toString() ?? '',
    );
    _latitudeController = TextEditingController(
      text: initial?.latitude?.toString() ?? '',
    );
    _timezoneController = TextEditingController(
      text: initial?.timezoneId ?? CaseSnapshot.defaultTimezoneId,
    );
    _gender = initial?.gender ?? CaseGender.unspecified;
    _calendarType = initial?.calendarType ?? CaseCalendarType.solar;
    _isLeapMonth = initial?.isLeapMonth ?? false;
    _birthDateTime = initial?.birthDateTime ?? DateTime(1990, 1, 1, 12);
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _noteController,
      _placeController,
      _longitudeController,
      _latitudeController,
      _timezoneController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _birthDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _birthDateTime.hour,
        _birthDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_birthDateTime),
    );
    if (picked == null) return;
    setState(() {
      _birthDateTime = DateTime(
        _birthDateTime.year,
        _birthDateTime.month,
        _birthDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写角色名称')));
      return;
    }

    double? readCoordinate(String raw) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      return double.tryParse(text);
    }

    final place = _placeController.text.trim();
    final timezoneId = _timezoneController.text.trim().isEmpty
        ? CaseSnapshot.defaultTimezoneId
        : _timezoneController.text.trim();

    final draft = (widget.initial == null)
        ? CaseProfile.create(
            name: name,
            gender: _gender,
            calendarType: _calendarType,
            birthDateTime: _birthDateTime,
            isLeapMonth: _isLeapMonth,
            timezoneId: timezoneId,
            longitude: readCoordinate(_longitudeController.text),
            latitude: readCoordinate(_latitudeController.text),
            placeName: place.isEmpty ? null : place,
            note: _noteController.text.trim(),
          )
        : widget.initial!.copyWith(
            name: name,
            gender: _gender,
            calendarType: _calendarType,
            birthDateTime: _birthDateTime,
            isLeapMonth: _isLeapMonth,
            timezoneId: timezoneId,
            longitude: readCoordinate(_longitudeController.text),
            latitude: readCoordinate(_latitudeController.text),
            placeName: place.isEmpty ? null : place,
            note: _noteController.text.trim(),
            updatedAt: DateTime.now(),
          );

    Navigator.pop(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    String two(int value) => value.toString().padLeft(2, '0');
    final dateLabel =
        '${_birthDateTime.year}-${two(_birthDateTime.month)}-${two(_birthDateTime.day)}';
    final timeLabel =
        '${two(_birthDateTime.hour)}:${two(_birthDateTime.minute)}';

    return AlertDialog(
      title: Text(isEdit ? '编辑角色' : '新建角色'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '姓名或事项称谓',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppTheme.space3),
              SegmentedButton<CaseGender>(
                segments: CaseGender.values
                    .map(
                      (item) => ButtonSegment<CaseGender>(
                        value: item,
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
                selected: {_gender},
                onSelectionChanged: (value) =>
                    setState(() => _gender = value.first),
              ),
              const SizedBox(height: AppTheme.space3),
              SegmentedButton<CaseCalendarType>(
                segments: CaseCalendarType.values
                    .map(
                      (item) => ButtonSegment<CaseCalendarType>(
                        value: item,
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
                selected: {_calendarType},
                onSelectionChanged: (value) =>
                    setState(() => _calendarType = value.first),
              ),
              const SizedBox(height: AppTheme.space3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(dateLabel),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(timeLabel),
                    ),
                  ),
                ],
              ),
              if (_calendarType == CaseCalendarType.lunar)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('闰月'),
                  value: _isLeapMonth,
                  onChanged: (value) => setState(() => _isLeapMonth = value),
                ),
              const SizedBox(height: AppTheme.space3),
              TextField(
                controller: _timezoneController,
                decoration: const InputDecoration(
                  labelText: '时区',
                  hintText: 'Asia/Shanghai',
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              TextField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: '出生地',
                  hintText: '仅供展示，可留空',
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: '经度',
                        hintText: '东经为正',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Expanded(
                    child: TextField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: '纬度',
                        hintText: '北纬为正',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                '求真太阳时需要经纬度；八字、紫微等术式会用到。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.space3),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '可留空',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
