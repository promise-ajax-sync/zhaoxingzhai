import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onOpenFeature;

  const HomePage({super.key, required this.onOpenFeature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('兆星斋'), centerTitle: true),
      body: AppPageContainer(
        child: Column(
          children: [
            const AppPageHeading(
              title: '东方术数与占卜工具',
              subtitle: '算法以 mingyu 为基准，交互参考时月东方，结果仅供传统文化研究与休闲参考。',
            ),
            _FeatureCard(
              icon: Icons.nightlight_outlined,
              title: '小六壬时间起课',
              description: '按东八区民用时间、农历月日和十二时辰完成时间起课。',
              badge: '已接入',
              onTap: () => onOpenFeature(1),
            ),
            const SizedBox(height: AppTheme.space4),
            _FeatureCard(
              icon: Icons.style_outlined,
              title: '塔罗占卜',
              description: '包含 78 张牌、18 种牌阵、正逆位与可重放随机轨迹。',
              badge: '已接入',
              onTap: () => onOpenFeature(2),
            ),
            const SizedBox(height: AppTheme.space4),
            const AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.construction_outlined),
                  SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('后续迁移'),
                        SizedBox(height: AppTheme.space2),
                        Text('蓍草、灵签、梅花、六爻等模块将按迁移基线逐项接入。'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space7),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space5),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.accentSoft(context),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      badge,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppTheme.success(context)),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space2),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
