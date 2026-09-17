import 'package:flutter/material.dart';

import 'package:zhaoxingzhai/app/app_view.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';

/// 尚未接入数据的入口占位页。
///
/// 导航骨架先按参考实现铺满 15 个入口，逐个术式接入时用真实页面替换掉
/// 对应的 [PlaceholderPage]，导航结构本身不需要再改。
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.view});

  final AppView view;

  @override
  Widget build(BuildContext context) {
    return AppPageContainer(
      child: AppEmptyState(
        icon: view.icon,
        title: '${view.label} 尚未接入',
        subtitle: '算法与数据迁移完成后在此渲染。',
      ),
    );
  }
}
