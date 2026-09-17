import 'package:flutter/material.dart';

import 'package:zhaoxingzhai/app/app_view.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

/// 首页（对话优先）。
///
/// 对齐参考实现的默认态：今日运势条 → 品牌 hero → 输入区 → 免责声明。
/// 对话与会话列表尚未接入，输入区目前只接收问题并在本地回显。
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenFeature});

  final ValueChanged<AppView> onOpenFeature;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _tool = '梅花易数';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记录问题：$question（对话能力尚未接入）'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.pageContent,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? AppTheme.space6 : AppTheme.space4,
                  vertical: AppTheme.space5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FortuneStrip(onTap: () => widget.onOpenFeature(AppView.fortune)),
                    SizedBox(height: wide ? AppTheme.space9 : AppTheme.space7),
                    _Hero(onOpenMeritBox: () {}),
                    SizedBox(height: wide ? AppTheme.space8 : AppTheme.space7),
                    _Composer(
                      controller: _controller,
                      tool: _tool,
                      onToolChanged: (value) => setState(() => _tool = value),
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: AppTheme.space5),
                    Text(
                      '生成内容完全基于 AI 模型的胡言乱语，不构成任何形式建议',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.labelSmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 今日运势条：图标 + 标题 + 摘要 + 色点 + 箭头。
class _FortuneStrip extends StatelessWidget {
  const _FortuneStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space3,
            vertical: AppTheme.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '今日运势',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.06,
                        color: theme.textTheme.labelSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '尚未接入：接入后显示当日渐卦与宜忌提要',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
                decoration: BoxDecoration(
                  color: AppTheme.auspice(context, AuspiceLevel.smallGood),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 15,
                color: theme.textTheme.labelSmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 品牌 hero：标识 + 双色标题 + 功德箱胶囊。
class _Hero extends StatelessWidget {
  const _Hero({required this.onOpenMeritBox});

  final VoidCallback onOpenMeritBox;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = AppTheme.heroGradient(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.themeShadow(context),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            '兆',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 9),
        // 「探索未来」用正文色，「解读术数」用品牌渐变裁切。
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '探索未来',
              style: TextStyle(
                fontFamily: 'Noto Serif SC',
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                height: 1.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
            _GradientText(
              text: '解读术数',
              colors: gradient,
              style: const TextStyle(
                fontFamily: 'Noto Serif SC',
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                height: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Material(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          child: InkWell(
            onTap: onOpenMeritBox,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.themeShadow(context),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 14, color: Colors.white),
                  SizedBox(width: 7),
                  Text(
                    '功德箱',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 用 [ShaderMask] 把渐变裁进文字，等价于 CSS 的 `background-clip: text`。
class _GradientText extends StatelessWidget {
  const _GradientText({
    required this.text,
    required this.colors,
    required this.style,
  });

  final String text;
  final List<Color> colors;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        stops: const [0, 0.48, 1],
        begin: const Alignment(-1, -0.4),
        end: const Alignment(1, 0.4),
      ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

/// 输入区：浮动卡片 + 工具条 + 发送按钮。
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.tool,
    required this.onToolChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String tool;
  final ValueChanged<String> onToolChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.themeShadow(context).withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 8,
            maxLength: 10000,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: '写下问题，交给$tool',
              hintStyle: TextStyle(
                color: theme.textTheme.labelSmall?.color,
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              _Chip(
                icon: Icons.add,
                label: tool,
                trailing: Icons.keyboard_arrow_down,
                onTap: () {},
              ),
              const SizedBox(width: AppTheme.space2),
              _Chip(
                icon: Icons.chat_bubble_outline,
                label: '问题灵感',
                onTap: () {},
              ),
              const SizedBox(width: AppTheme.space2),
              _Chip(
                icon: Icons.description_outlined,
                label: '补充信息',
                onTap: () {},
              ),
              const Spacer(),
              Material(
                color: theme.colorScheme.secondary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onSubmit,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            'Enter 发送 · Shift + Enter 换行',
            style: TextStyle(
              fontSize: 10,
              color: theme.textTheme.labelSmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodySmall?.color;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                Icon(trailing, size: 13, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
