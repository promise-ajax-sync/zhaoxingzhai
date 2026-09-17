/// 塔罗牌阵选择器
library;

import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart' as tarot_loader;

class TarotSpreadSelector extends StatelessWidget {
  final String selectedSpread;
  final ValueChanged<String> onSpreadChanged;

  const TarotSpreadSelector({
    super.key,
    required this.selectedSpread,
    required this.onSpreadChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spreads = tarot_loader.TarotData.spreads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeading(title: '选择牌阵'),
        ...spreads.entries.map((entry) {
          final key = entry.key;
          final spread = entry.value;
          final isSelected = selectedSpread == key;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: AppCard(
              onTap: () => onSpreadChanged(key),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              child: Row(
                children: [
                  // 选中指示器
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space3),

                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      _getSpreadIcon(key),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),

                  const SizedBox(width: AppTheme.space3),

                  // 文本信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spread.name,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                        const SizedBox(height: AppTheme.space1),
                        Text(
                          spread.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppTheme.space3),

                  // 牌数
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space2,
                      vertical: AppTheme.space1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    ),
                    child: Text(
                      '${spread.cardCount}张',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _getSpreadIcon(String key) {
    switch (key) {
      case 'single':
        return Icons.filter_1;
      case 'three':
        return Icons.filter_3;
      case 'celtic':
        return Icons.grid_view;
      default:
        return Icons.style;
    }
  }
}
