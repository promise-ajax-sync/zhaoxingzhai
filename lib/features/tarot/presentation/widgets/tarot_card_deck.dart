/// 塔罗牌堆展示和抽牌动画
library;

import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';

class TarotCardDeck extends StatelessWidget {
  final bool isDrawing;
  final VoidCallback onDraw;

  const TarotCardDeck({
    super.key,
    required this.isDrawing,
    required this.onDraw,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // 牌堆动画
          AnimatedContainer(
            duration: AppTheme.motionBase,
            curve: Curves.easeInOut,
            width: isDrawing ? 200 : 180,
            height: isDrawing ? 300 : 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 底层牌（阴影效果）
                ...List.generate(3, (index) {
                  return Positioned(
                    top: index * 4.0,
                    child: Transform.rotate(
                      angle: (index - 1) * 0.02,
                      child: _buildCard(context, opacity: 0.3 + (index * 0.2)),
                    ),
                  );
                }),

                // 顶层牌
                if (isDrawing)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: AppTheme.motionSlow,
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -100 * value),
                        child: Transform.rotate(
                          angle: 0.5 * value,
                          child: Opacity(opacity: 1 - value, child: child),
                        ),
                      );
                    },
                    child: _buildCard(context),
                  )
                else
                  _buildCard(context),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space6),

          // 抽牌按钮
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton.icon(
              key: const ValueKey('tarot-draw-cards'),
              onPressed: isDrawing ? null : onDraw,
              icon: isDrawing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isDrawing ? '抽牌中...' : '开始抽牌'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 140,
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 装饰纹理
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: CustomPaint(
                  painter: _CardBackPainter(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),

            // 中心图案
            Center(
              child: Icon(
                Icons.auto_awesome,
                size: 60,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 卡背纹理绘制
class _CardBackPainter extends CustomPainter {
  final Color color;

  _CardBackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 绘制装饰线条
    for (int i = 0; i < 8; i++) {
      final y = size.height / 8 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 0; i < 5; i++) {
      final x = size.width / 5 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 绘制对角线
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      paint..strokeWidth = 0.8,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
