import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/widgets/date_time_input_section.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/widgets/result_display_section.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/widgets/calculating_animation.dart';

/// 小六壬占卜页面
class XiaoliurenPage extends StatefulWidget {
  final Future<void> Function(XiaoliurenData)? onResult;

  const XiaoliurenPage({super.key, this.onResult});

  @override
  State<XiaoliurenPage> createState() => _XiaoliurenPageState();
}

class _XiaoliurenPageState extends State<XiaoliurenPage> {
  DateTime? _selectedDate;
  XiaoliurenRule _selectedRule = XiaoliurenRule.common;
  XiaoliurenData? _result;
  bool _isCalculating = false;

  /// 执行占卜计算
  Future<void> _performDivination() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先选择日期和时辰')));
      return;
    }

    setState(() {
      _isCalculating = true;
      _result = null;
    });

    // 模拟计算过程（增加仪式感）
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final result = generateXiaoliuren(
      rule: _selectedRule,
      customDate: _selectedDate,
    );

    setState(() {
      _result = result;
      _isCalculating = false;
    });

    try {
      await widget.onResult?.call(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('结果已生成，但历史记录保存失败: $error')));
    }
  }

  /// 重置状态
  void _reset() {
    setState(() {
      _selectedDate = null;
      _result = null;
      _isCalculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 外壳（AppShell）已提供顶栏与背景，这里只渲染页面内容。
    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeading(
            title: '小六壬时间起课',
            subtitle: '以农历月日时起课，六宫顺推',
            trailing: _result != null
                ? IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _reset,
                    tooltip: '重新开始',
                  )
                : null,
          ),
          // 如果正在计算，显示动画
          if (_isCalculating)
            const CalculatingAnimation()
          // 如果有结果，显示结果
          else if (_result != null)
            ResultDisplaySection(result: _result!, onReset: _reset)
          // 否则显示输入表单
          else
            DateTimeInputSection(
              selectedDate: _selectedDate,
              selectedRule: _selectedRule,
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
              },
              onRuleChanged: (rule) {
                setState(() => _selectedRule = rule);
              },
              onCalculate: _performDivination,
            ),
        ],
      ),
    );
  }
}
