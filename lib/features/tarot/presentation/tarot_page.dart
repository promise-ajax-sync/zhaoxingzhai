/// 塔罗占卜页面
/// 塔罗占卜页面。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/interpretation/tarot_interpretation.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart' as tarot_loader;
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';

import 'widgets/tarot_spread_selector.dart';
import 'widgets/tarot_card_deck.dart';
import 'widgets/tarot_manual_input.dart';
import 'widgets/tarot_result_display.dart';

enum _TarotInputMode { automatic, manual }

class TarotPage extends StatefulWidget {
  final Future<void> Function()? loadData;
  final Future<void> Function(TarotDrawResult)? onResult;
  final Future<void> Function(TarotDrawResult, DivinationQuestion)?
  onResultWithQuestion;
  final ValueListenable<RoutedDivinationDraft?>? routedDraft;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    TarotDrawResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  const TarotPage({
    super.key,
    this.loadData,
    this.onResult,
    this.onResultWithQuestion,
    this.routedDraft,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  @override
  State<TarotPage> createState() => _TarotPageState();
}

class _TarotPageState extends State<TarotPage> {
  bool _isLoading = true;
  bool _isDrawing = false;
  String? _loadError;
  String _selectedSpread = 'single';
  _TarotInputMode _inputMode = _TarotInputMode.automatic;
  TarotDrawResult? _result;
  final _questionController = TextEditingController();
  String _topic = 'general';
  RoutedDivinationDraft? _lastRoutedDraft;
  bool _aiLoading = false;
  AiInterpretationResponse? _aiResponse;
  Object? _aiError;
  int _aiRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _applyRoutedDraft(widget.routedDraft?.value, notify: false);
    widget.routedDraft?.addListener(_onRoutedDraftChanged);
    _initTarot();
  }

  @override
  void didUpdateWidget(covariant TarotPage oldWidget) {
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
        draft.tool != DivinationTool.tarot ||
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

  DivinationQuestion get _question =>
      DivinationQuestion.parse(_questionController.text.trim(), topic: _topic);

  Future<void> _initTarot() async {
    if (!_isLoading || _loadError != null) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      await (widget.loadData ?? tarot_loader.TarotData.load)();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _drawCards() async {
    setState(() {
      _isDrawing = true;
      _result = null;
      _clearAiReading();
    });

    // 动画延迟
    await Future.delayed(AppTheme.motionSlow);
    if (!mounted) return;

    try {
      final tarot = TarotDivination();
      final result = _selectedSpread == 'single'
          ? tarot.drawSingle()
          : tarot.drawSpread(_selectedSpread);

      if (!mounted) return;
      setState(() {
        _result = result;
        _isDrawing = false;
      });
      await _saveResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDrawing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('抽牌失败: $e')));
    }
  }

  Future<void> _submitManualCards(List<ManualCardInput> cards) async {
    setState(() {
      _isDrawing = true;
      _result = null;
      _clearAiReading();
    });

    try {
      final result = TarotDivination().drawManual(_selectedSpread, cards);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isDrawing = false;
      });
      await _saveResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDrawing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('录牌失败: $e')));
    }
  }

  void _reset() {
    setState(() {
      _result = null;
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
    final reading = TarotInterpretation.build(result, question: question);
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
          methodLabel: '塔罗',
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

  Future<void> _saveResult(TarotDrawResult result) async {
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

  @override
  Widget build(BuildContext context) {
    // 外壳（AppShell）已提供顶栏与背景，这里只渲染页面内容。
    return _isLoading
        ? const AppLoadingIndicator(message: '加载塔罗牌...')
        : _loadError != null
        ? _buildLoadError(context)
        : AppPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 页面标题
                AppPageHeading(
                  title: '塔罗占卜',
                  subtitle: '基于韦特体系的传统塔罗占卜',
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
                    key: const ValueKey('tarot-question-input'),
                    controller: _questionController,
                    onChanged: (value) => setState(() {
                      _topic = DivinationQuestion.inferTopic(value);
                    }),
                    decoration: InputDecoration(
                      labelText: '占问主题',
                      hintText: '写下希望牌阵重点回应的问题',
                      helperText: '当前分类：${_topicLabel(_topic)}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.space4),

                // 如果还没有结果，显示抽牌界面
                if (_result == null) ...[
                  SegmentedButton<_TarotInputMode>(
                    segments: const [
                      ButtonSegment(
                        value: _TarotInputMode.automatic,
                        icon: Icon(Icons.auto_awesome),
                        label: Text('自动抽牌'),
                      ),
                      ButtonSegment(
                        value: _TarotInputMode.manual,
                        icon: Icon(Icons.edit_note),
                        label: Text('手动录牌'),
                      ),
                    ],
                    selected: {_inputMode},
                    onSelectionChanged: _isDrawing
                        ? null
                        : (selection) {
                            setState(() => _inputMode = selection.first);
                          },
                  ),

                  const SizedBox(height: AppTheme.space5),

                  // 牌阵选择
                  TarotSpreadSelector(
                    selectedSpread: _selectedSpread,
                    onSpreadChanged: (spread) {
                      setState(() => _selectedSpread = spread);
                    },
                  ),

                  const SizedBox(height: AppTheme.space5),

                  if (_inputMode == _TarotInputMode.automatic)
                    TarotCardDeck(isDrawing: _isDrawing, onDraw: _drawCards)
                  else
                    TarotManualInput(
                      key: ValueKey('manual-$_selectedSpread'),
                      spreadType: _selectedSpread,
                      isSubmitting: _isDrawing,
                      onSubmit: _submitManualCards,
                    ),

                  const SizedBox(height: AppTheme.space4),

                  // 提示文本
                  AppCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.space3),
                        Expanded(
                          child: Text(
                            _inputMode == _TarotInputMode.automatic
                                ? '集中注意力，想着你的问题，然后点击「开始抽牌」'
                                : '手动录牌用于记录实体牌结果；牌面不可重复，顺序须与牌位一致。',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 如果有结果，显示结果
                if (_result != null) ...[
                  TarotResultDisplay(result: _result!, question: _question),
                  if (widget.aiService != null) ...[
                    const AppSectionHeading(title: 'AI 深度解读'),
                    AiInterpretationCard(
                      response: _aiResponse,
                      loading: _aiLoading,
                      error: _aiError,
                      onRequest: _requestAiReading,
                      loadingText: '正在结合问题、牌阵、牌位和正逆位生成解读…',
                      idleText: _question.rawText.isEmpty
                          ? '未填写具体问题，AI 将依据本次牌阵、牌位和正逆位生成通用解读。'
                          : 'AI 将使用当前问题和已抽取的牌阵证据继续解读，不会重新抽牌。',
                      actionKey: const ValueKey('tarot-ai-reading'),
                    ),
                    const SizedBox(height: AppTheme.space5),
                  ],
                ],
              ],
            ),
          );
  }

  static String _topicLabel(String topic) => switch (topic) {
    'relationship' => '感情关系',
    'career' => '事业工作',
    'wealth' => '财运经营',
    'health' => '健康状态',
    'study' => '学业考试',
    _ => '综合事项',
  };

  Widget _buildLoadError(BuildContext context) {
    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeading(title: '塔罗数据加载失败', subtitle: '未能读取本地牌面与牌阵数据'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppTheme.space3),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.space4),
                ElevatedButton.icon(
                  key: const ValueKey('retry-tarot-load'),
                  onPressed: _initTarot,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新加载'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
