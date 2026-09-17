import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';

/// 日期时辰输入区域
class DateTimeInputSection extends StatelessWidget {
  final DateTime? selectedDate;
  final XiaoliurenRule selectedRule;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<XiaoliurenRule> onRuleChanged;
  final VoidCallback onCalculate;

  const DateTimeInputSection({
    super.key,
    required this.selectedDate,
    required this.selectedRule,
    required this.onDateChanged,
    required this.onRuleChanged,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2636).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9A568).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '请选择占卜时间',
            style: TextStyle(
              color: Color(0xFFE9A568),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '小六壬以时间起课，择一时辰，问一事',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildDateTimePicker(context),
          const SizedBox(height: 24),
          _buildRuleSelector(),
          const SizedBox(height: 32),
          _buildCalculateButton(context),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDateTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F131C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE9A568).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFFE9A568), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate == null ? '点击选择日期和时辰' : _formatDateTime(selectedDate!),
                style: TextStyle(
                  color: selectedDate == null ? Colors.white.withValues(alpha: 0.4) : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '起课规则',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRuleOption(XiaoliurenRule.common, '通行掌诀', '民间常用')),
            const SizedBox(width: 12),
            Expanded(child: _buildRuleOption(XiaoliurenRule.duoneng, '多能鄙事', '古法传承')),
          ],
        ),
      ],
    );
  }

  Widget _buildRuleOption(XiaoliurenRule rule, String title, String subtitle) {
    final isSelected = selectedRule == rule;
    return GestureDetector(
      onTap: () => onRuleChanged(rule),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE9A568).withValues(alpha: 0.15) : const Color(0xFF0F131C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFE9A568) : const Color(0xFFE9A568).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFFE9A568) : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton(BuildContext context) {
    final isEnabled = selectedDate != null;
    return ElevatedButton(
      onPressed: isEnabled ? onCalculate : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE9A568),
        disabledBackgroundColor: const Color(0xFF1E2636),
        foregroundColor: const Color(0xFF0A0D12),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: isEnabled ? 8 : 0,
        shadowColor: const Color(0xFFE9A568).withValues(alpha: 0.5),
      ),
      child: const Text(
        '开始占卜',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour;
    final timeLabel = _getTimeLabel(hour);
    return '${date.year}年${date.month}月${date.day}日 $timeLabel';
  }

  String _getTimeLabel(int hour) {
    if (hour == 23 || hour == 0) return '子时 (23:00-01:00)';
    if (hour >= 1 && hour < 3) return '丑时 (01:00-03:00)';
    if (hour >= 3 && hour < 5) return '寅时 (03:00-05:00)';
    if (hour >= 5 && hour < 7) return '卯时 (05:00-07:00)';
    if (hour >= 7 && hour < 9) return '辰时 (07:00-09:00)';
    if (hour >= 9 && hour < 11) return '巳时 (09:00-11:00)';
    if (hour >= 11 && hour < 13) return '午时 (11:00-13:00)';
    if (hour >= 13 && hour < 15) return '未时 (13:00-15:00)';
    if (hour >= 15 && hour < 17) return '申时 (15:00-17:00)';
    if (hour >= 17 && hour < 19) return '酉时 (17:00-19:00)';
    if (hour >= 19 && hour < 21) return '戌时 (19:00-21:00)';
    return '亥时 (21:00-23:00)';
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE9A568),
              onPrimary: Color(0xFF0A0D12),
              surface: Color(0xFF1E2636),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? now),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFE9A568),
                onPrimary: Color(0xFF0A0D12),
                surface: Color(0xFF1E2636),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        onDateChanged(DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
      }
    }
  }
}
