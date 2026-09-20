import 'package:flutter/material.dart';

import 'package:zhaoxingzhai/app/app_view.dart';
import 'package:zhaoxingzhai/core/models/answer_preference.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

/// 顶栏。
///
/// 三段布局对齐参考实现：左侧导航开关 / 返回，中间页面标题或 AI 偏好入口，
/// 右侧案例与记录。首页（[AppView.tools]）的中间位渲染 AI 入口，其余页面渲染标题。
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.view,
    required this.onOpenNav,
    required this.onOpenCases,
    required this.onOpenHistory,
    this.showNavToggle = true,
    this.preference,
    this.onPreferenceChanged,
    this.channelName = '内置 AI',
    this.models = const [],
    this.model,
    this.onModelChanged,
    this.onOpenAiSettings,
    this.accountLabel,
    this.onOpenAccount,
  });

  final AppView view;
  final VoidCallback onOpenNav;
  final VoidCallback onOpenCases;
  final VoidCallback onOpenHistory;

  /// 宽屏侧栏常驻时不显示导航开关。
  final bool showNavToggle;

  /// 非空时中间位渲染 AI 偏好入口；为空则渲染标题。
  final AnswerPreference? preference;
  final ValueChanged<AnswerPreference>? onPreferenceChanged;

  /// AI 渠道与模型；渠道为内置时 [models] 为空，只展示渠道名。
  final String channelName;
  final List<String> models;
  final String? model;
  final ValueChanged<String>? onModelChanged;
  final VoidCallback? onOpenAiSettings;
  final String? accountLabel;
  final VoidCallback? onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: AppTheme.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
      color: AppTheme.topbar(context),
      child: Row(
        children: [
          if (showNavToggle)
            IconButton(
              onPressed: onOpenNav,
              icon: const Icon(Icons.menu, size: 19),
              tooltip: '打开导航',
              visualDensity: VisualDensity.compact,
            )
          else
            const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Center(
              child: preference == null
                  ? Text(
                      view.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                      ),
                    )
                  : _AiPicker(
                      preference: preference!,
                      onPreferenceChanged: onPreferenceChanged,
                      channelName: channelName,
                      models: models,
                      model: model,
                      onModelChanged: onModelChanged,
                      onOpenAiSettings: onOpenAiSettings,
                    ),
            ),
          ),
          _TopBarAction(
            icon: Icons.person_outline,
            label: '添加角色',
            onTap: onOpenCases,
          ),
          _TopBarAction(
            icon: Icons.history,
            label: '记录',
            onTap: onOpenHistory,
            labelVisible: false,
          ),
          if (onOpenAccount != null)
            _TopBarAction(
              icon: accountLabel == null
                  ? Icons.login
                  : Icons.account_circle_outlined,
              label: accountLabel ?? '登录',
              onTap: onOpenAccount!,
              labelVisible: false,
            ),
          const SizedBox(width: AppTheme.space1),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelVisible = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool labelVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
              if (labelVisible) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// AI 偏好入口 + 浮层菜单。
///
/// 浮层用 [Stack] 绝对定位，不参与顶栏布局，因此展开时不会把内容顶下去。
class _AiPicker extends StatefulWidget {
  const _AiPicker({
    required this.preference,
    required this.channelName,
    required this.models,
    this.onPreferenceChanged,
    this.model,
    this.onModelChanged,
    this.onOpenAiSettings,
  });

  final AnswerPreference preference;
  final ValueChanged<AnswerPreference>? onPreferenceChanged;
  final String channelName;
  final List<String> models;
  final String? model;
  final ValueChanged<String>? onModelChanged;
  final VoidCallback? onOpenAiSettings;

  @override
  State<_AiPicker> createState() => _AiPickerState();
}

class _AiPickerState extends State<_AiPicker> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        if (_open)
          Positioned.fill(
            // 覆盖整个顶栏的点击区用于关闭；浮层本身在其上方，不受影响。
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = false),
              child: const SizedBox.expand(),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Trigger(
              open: _open,
              preference: widget.preference,
              model: widget.model ?? widget.channelName,
              onTap: () => setState(() => _open = !_open),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _Menu(
                  preference: widget.preference,
                  onPreferenceChanged: (value) {
                    widget.onPreferenceChanged?.call(value);
                    setState(() => _open = false);
                  },
                  channelName: widget.channelName,
                  models: widget.models,
                  model: widget.model,
                  onModelChanged: widget.onModelChanged,
                  onOpenAiSettings: () {
                    setState(() => _open = false);
                    widget.onOpenAiSettings?.call();
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.open,
    required this.preference,
    required this.model,
    required this.onTap,
  });

  final bool open;
  final AnswerPreference preference;
  final String model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentStrong = theme.colorScheme.secondary;

    return Tooltip(
      message: '${preference.label} · $model',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: AppTheme.motionFast,
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: open ? AppTheme.accentSoft(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: open ? theme.colorScheme.primary : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: open ? accentStrong : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: preference.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: open
                              ? accentStrong
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: '  $model',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textTheme.labelSmall?.color,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: open ? accentStrong : theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.preference,
    required this.channelName,
    required this.models,
    this.onPreferenceChanged,
    this.model,
    this.onModelChanged,
    this.onOpenAiSettings,
  });

  final AnswerPreference preference;
  final ValueChanged<AnswerPreference>? onPreferenceChanged;
  final String channelName;
  final List<String> models;
  final String? model;
  final ValueChanged<String>? onModelChanged;
  final VoidCallback? onOpenAiSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppTheme.motionFast,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.scale(
        scale: 0.96 + 0.04 * t,
        alignment: Alignment.topCenter,
        child: Opacity(opacity: t, child: child),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(AppTheme.space3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceOverlay(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: AppTheme.themeShadow(context),
                blurRadius: 64,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _MenuHeading(title: '解答偏好', hint: '切换表达与推演方式'),
              const SizedBox(height: AppTheme.space2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final option in AnswerPreference.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: option == AnswerPreference.values.last ? 0 : 6,
                        ),
                        child: _PreferenceOption(
                          option: option,
                          active: option == preference,
                          onTap: () => onPreferenceChanged?.call(option),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.space3),
              Divider(color: theme.dividerColor, height: 1),
              const SizedBox(height: 10),
              _MenuHeading(title: 'AI 模型', hint: channelName),
              const SizedBox(height: AppTheme.space2),
              if (models.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: model != null && models.contains(model)
                      ? model
                      : models.first,
                  isDense: true,
                  items: [
                    for (final item in models)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) {
                    if (value != null) onModelChanged?.call(value);
                  },
                )
              else
                Container(
                  height: 34,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    channelName,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.space3),
              OutlinedButton.icon(
                onPressed: onOpenAiSettings,
                icon: const Icon(Icons.auto_awesome, size: 13),
                label: const Text('管理 AI 配置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuHeading extends StatelessWidget {
  const _MenuHeading({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            hint,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.labelSmall?.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreferenceOption extends StatelessWidget {
  const _PreferenceOption({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final AnswerPreference option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentSoft(context)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            if (active)
              Positioned(
                right: -3,
                top: -4,
                child: Icon(
                  Icons.check,
                  size: 13,
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
