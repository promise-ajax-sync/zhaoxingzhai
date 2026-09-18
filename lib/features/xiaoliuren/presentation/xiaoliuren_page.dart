import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/rules.dart';
import 'package:zhaoxingzhai/core/interpretation/xiaoliuren_interpretation.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/widgets/date_time_input_section.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/widgets/result_display_section.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/widgets/calculating_animation.dart';

/// 小六壬占卜页面
class XiaoliurenPage extends StatefulWidget {
  final Future<void> Function(XiaoliurenData)? onResult;
  final Future<void> Function(XiaoliurenData, DivinationQuestion)?
  onResultWithQuestion;
  final ValueListenable<RoutedDivinationDraft?>? routedDraft;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final DateTime? initialDate;
  final Future<void> Function(
    XiaoliurenData result,
    AiInterpretationResponse response,
  )? onAiResponse;

  const XiaoliurenPage({
    super.key,
    this.onResult,
    this.onResultWithQuestion,
    this.routedDraft,
    this.aiService,
    this.answerStyle,
    this.initialDate,
    this.onAiResponse,
  });

  @override
  State<XiaoliurenPage> createState() => _XiaoliurenPageState();
}

class _XiaoliurenPageState extends State<XiaoliurenPage> {
  DateTime? _selectedDate;
  XiaoliurenRule _selectedRule = XiaoliurenRule.common;
  XiaoliurenData? _result;
  bool _isCalculating = false;
  final _questionController = TextEditingController();
  String _topic = 'general';
  RoutedDivinationDraft? _lastRoutedDraft;
  bool _aiLoading = false;
  AiInterpretationResponse? _aiResponse;
  Object? _aiError;
  int _aiRequestGeneration = 0;

  DivinationQuestion get _question => DivinationQuestion.parse(
    _questionController.text.trim(),
    topic: _topic,
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _applyRoutedDraft(widget.routedDraft?.value, notify: false);
    widget.routedDraft?.addListener(_onRoutedDraftChanged);
  }

  @override
  void didUpdateWidget(covariant XiaoliurenPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routedDraft != widget.routedDraft) {
      oldWidget.routedDraft?.removeListener(_onRoutedDraftChanged);
      widget.routedDraft?.addListener(_onRoutedDraftChanged);
      _applyRoutedDraft(widget.routedDraft?.value);
    }
  }

  @override
  void dispose() {
    widget.routedDraft?.removeListener(_onRoutedDraftChanged);
    _questionController.dispose();
    super.dispose();
  }

  void _onRoutedDraftChanged() => _applyRoutedDraft(widget.routedDraft?.value);

  void _applyRoutedDraft(RoutedDivinationDraft? draft, {bool notify = true}) {
    if (draft == null ||
        draft.tool != DivinationTool.xiaoliuren ||
        identical(draft, _lastRoutedDraft)) {
      return;
    }
    _lastRoutedDraft = draft;
    void apply() {
      _questionController.text = draft.question;
      _topic = DivinationQuestion.inferTopic(draft.question);
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }
  }

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
      _clearAiReading();
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
      if (widget.onResultWithQuestion != null) {
        await widget.onResultWithQuestion!(result, _question);
      } else {
        await widget.onResult?.call(result);
      }
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
      _clearAiReading();
    });
  }

  void _clearAiReading() {
    _aiRequestGeneration++;
    _aiLoading = false;
    _aiResponse = null;
    _aiError = null;
  }

  Future<void> _requestAiReading() async {
    final result = _result;
    final service = widget.aiService;
    if (result == null || service == null) {
      return;
    }
    final question = _question;
    final reading = XiaoliurenInterpretation.build(result, question: question);
    final generation = ++_aiRequestGeneration;
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final response = await service.interpret(
        AiInterpretationRequest(
          question: question,
          evidence: reading.evidence,
          localAnswer: reading.directAnswer,
          methodLabel: '小六壬',
          answerStyle: widget.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (mounted && generation == _aiRequestGeneration) {
        setState(() => _aiResponse = response);
        await widget.onAiResponse?.call(result, response);
      }
    } catch (error) {
      if (mounted && generation == _aiRequestGeneration) {
        setState(() => _aiError = error);
      }
    } finally {
      if (mounted && generation == _aiRequestGeneration) {
        setState(() => _aiLoading = false);
      }
    }
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
          AppCard(
            child: TextField(
              key: const ValueKey('xiaoliuren-question-input'),
              controller: _questionController,
              onChanged: (value) => setState(() {
                _topic = DivinationQuestion.inferTopic(value);
              }),
              decoration: const InputDecoration(
                labelText: '占问问题',
                hintText: '例如：这件事近期会不会成功？',
                helperText: '问题会用于生成针对性回应，不参与起课计算',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          // 如果正在计算，显示动画
          if (_isCalculating)
            const CalculatingAnimation()
          // 如果有结果，显示结果
          else if (_result != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResultDisplaySection(
                  result: _result!,
                  question: _question,
                  onReset: _reset,
                ),
                if (widget.aiService != null) ...[
                  const AppSectionHeading(title: 'AI 深度解读'),
                  AiInterpretationCard(
                    response: _aiResponse,
                    loading: _aiLoading,
                    error: _aiError,
                    onRequest: _requestAiReading,
                    loadingText: '正在结合问题、起课规则和三宫结果生成解读…',
                    idleText: 'AI 将使用当前问题和已经计算完成的小六壬证据继续解读，不会重新起课。',
                    actionKey: const ValueKey('xiaoliuren-ai-reading'),
                  ),
                ],
              ],
            )
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
