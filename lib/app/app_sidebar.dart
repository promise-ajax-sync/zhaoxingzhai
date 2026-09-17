import 'package:flutter/material.dart';

import 'package:zhaoxingzhai/app/app_view.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

/// 侧栏导航。
///
/// 结构对齐参考实现：顶部品牌标识 → 首页 / 术数入口 → 底部案例与设置。
/// 窄屏时同一套组件塞进抽屉，[onClose] 用于让抽屉关闭自身。
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.current,
    required this.onSelect,
    this.onClose,
  });

  final AppView current;
  final ValueChanged<AppView> onSelect;

  /// 非空时在顶部右侧显示关闭按钮（抽屉场景）。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final primary = AppView.values
        .where((v) => v.navGroup == AppNavGroup.primary)
        .toList();
    final tools = AppView.values
        .where((v) => v.navGroup == AppNavGroup.tools)
        .toList();
    final secondary = AppView.values
        .where((v) => v.navGroup == AppNavGroup.secondary)
        .toList();

    return Container(
      width: AppTheme.sidebarWidth,
      color: AppTheme.sidebar(context),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space4,
            AppTheme.space5,
            AppTheme.space4,
            AppTheme.space5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarHeader(onClose: onClose),
              const SizedBox(height: AppTheme.space5),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final view in [...primary, ...tools])
                        _NavTile(
                          view: view,
                          active: view == current,
                          onTap: () => onSelect(view),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              Divider(color: Theme.of(context).dividerColor, height: 1),
              const SizedBox(height: AppTheme.space3),
              for (final view in secondary)
                _NavTile(
                  view: view,
                  active: view == current,
                  onTap: () => onSelect(view),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = AppTheme.heroGradient(context);

    return Row(
      children: [
        // 品牌标识：参考实现用的是图片 logo，这里先用主题渐变底 + 首字，
        // 避免引入尚未迁移的位图资产（见 xiugai.md A15）。
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Text(
            '兆',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '兆星斋',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                ),
              ),
              Text(
                '东方术数',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.18,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 19),
            tooltip: '关闭导航',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.view,
    required this.active,
    required this.onTap,
  });

  final AppView view;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final accentStrong = theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space1),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Material(
            color: active ? AppTheme.accentSoft(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space3,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      active ? view.selectedIcon : view.icon,
                      size: 17,
                      color: active ? accentStrong : theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        view.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active
                              ? accentStrong
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 13,
                      color: active ? accent : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 选中态左侧竖条：贴边 3px，与参考实现一致
          Positioned(
            left: 0,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: AppTheme.motionFast,
              child: Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
