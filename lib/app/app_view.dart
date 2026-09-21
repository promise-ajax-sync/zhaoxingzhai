import 'package:flutter/material.dart';

/// 应用入口视图。
///
/// 对齐参考实现的 15 个视图：13 个工具入口 + 案例 + 设置。
/// 尚未实现数据的入口统一渲染占位页（见 [PlaceholderPage]）。
enum AppView {
  tools('首页', Icons.grid_view_outlined, Icons.grid_view),
  charts('梅花易数', Icons.filter_vintage_outlined, Icons.filter_vintage),
  compatibility('基础关系合盘', Icons.favorite_border, Icons.favorite),
  oracle('灵签', Icons.article_outlined, Icons.article),
  xiaoliuren('小六壬', Icons.nightlight_outlined, Icons.nightlight),
  dailyHexagram('每日一卦', Icons.monetization_on_outlined, Icons.monetization_on),
  liuyao('六爻排盘', Icons.view_agenda_outlined, Icons.view_agenda),
  fortune('今日运势', Icons.wb_sunny_outlined, Icons.wb_sunny),
  almanac('传统黄历', Icons.calendar_month_outlined, Icons.calendar_month),
  fengshui('居家风水', Icons.home_outlined, Icons.home),
  tarot('西方占卜', Icons.auto_awesome_outlined, Icons.auto_awesome),
  nameNumber('姓名与数字', Icons.menu_book_outlined, Icons.menu_book),
  zhuge('诸葛神数', Icons.receipt_long_outlined, Icons.receipt_long),
  kongming('孔明神卦', Icons.change_history_outlined, Icons.change_history),
  cases('角色', Icons.book_outlined, Icons.book),
  settings('设置', Icons.settings_outlined, Icons.settings);

  const AppView(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// 侧栏 / 底部导航的分组。
enum AppNavGroup { primary, tools, secondary }

extension AppViewNav on AppView {
  AppNavGroup get navGroup => switch (this) {
    AppView.tools => AppNavGroup.primary,
    AppView.cases || AppView.settings => AppNavGroup.secondary,
    _ => AppNavGroup.tools,
  };
}
