import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';

/// 结果展示区域
class ResultDisplaySection extends StatelessWidget {
  final XiaoliurenData result;
  final VoidCallback onReset;

  const ResultDisplaySection({
    super.key,
    required this.result,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 主断区域
        _buildMainResult(),
        const SizedBox(height: 20),

        // 三宫展示
        _buildThreePalaces(),
        const SizedBox(height: 20),

        // 计算过程
        _buildCalculationProcess(),
        const SizedBox(height: 32),

        // 重新占卜按钮
        _buildResetButton(),
      ],
    );
  }

  Widget _buildMainResult() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE9A568).withValues(alpha: 0.2),
            const Color(0xFF1E2636).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9A568),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '卦象',
            style: TextStyle(
              color: Color(0xFFE9A568),
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.primary.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            result.primary.verse,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThreePalaces() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2636).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9A568).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '三宫推演',
            style: TextStyle(
              color: const Color(0xFFE9A568).withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPalaceCard('月宫', result.sequence['month']!)),
              const SizedBox(width: 12),
              Expanded(child: _buildPalaceCard('日宫', result.sequence['day']!)),
              const SizedBox(width: 12),
              Expanded(child: _buildPalaceCard('时宫', result.sequence['hour']!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPalaceCard(String label, XiaoliurenPalaceDetail palace) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9A568).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            palace.name,
            style: const TextStyle(
              color: Color(0xFFE9A568),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationProcess() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2636).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9A568).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate,
                color: Color(0xFFE9A568),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '推演过程',
                style: TextStyle(
                  color: const Color(0xFFE9A568).withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProcessStep('农历月', result.lunarMonth.toString()),
          _buildProcessStep('农历日', result.lunarDay.toString()),
          _buildProcessStep('时辰', result.hourLabel),
          const Divider(
            color: Color(0xFFE9A568),
            thickness: 1,
            height: 24,
          ),
          _buildProcessStep('月宫', result.sequence['month']!.name, isHighlight: true),
          _buildProcessStep('日宫', result.sequence['day']!.name, isHighlight: true),
          _buildProcessStep('时宫', result.sequence['hour']!.name, isHighlight: true),
          const SizedBox(height: 8),
          Text(
            '起课规则：${result.rule == XiaoliurenRule.common ? "通行掌诀" : "多能鄙事"}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? const Color(0xFFE9A568) : Colors.white.withValues(alpha: 0.7),
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? const Color(0xFFE9A568) : Colors.white,
              fontSize: isHighlight ? 18 : 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton(
      onPressed: onReset,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE9A568),
        side: const BorderSide(
          color: Color(0xFFE9A568),
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: const Text(
        '重新占卜',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
