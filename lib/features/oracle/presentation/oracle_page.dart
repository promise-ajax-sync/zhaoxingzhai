import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/engine/ssgw/ssgw_divination.dart';
import 'package:zhaoxingzhai/core/interpretation/ssgw_interpretation.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

class OraclePage extends StatefulWidget {
  const OraclePage({
    super.key,
    this.onResult,
    this.onResultWithQuestion,
    this.routedDraft,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  final Future<void> Function(SsgwResult result)? onResult;
  final Future<void> Function(SsgwResult result, DivinationQuestion question)?
  onResultWithQuestion;
  final ValueListenable<RoutedDivinationDraft?>? routedDraft;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    SsgwResult result,
    AiInterpretationResponse response,
  )? onAiResponse;

  @override
  State<OraclePage> createState() => _OraclePageState();
}

class _OraclePageState extends State<OraclePage> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  SsgwResult? _result;
  Object? _loadError;
  bool _loading = true;
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
    _applyRoutedDraft(widget.routedDraft?.value, notify: false);
    widget.routedDraft?.addListener(_onRoutedDraftChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant OraclePage oldWidget) {
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
    _numberController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _onRoutedDraftChanged() => _applyRoutedDraft(widget.routedDraft?.value);

  void _applyRoutedDraft(RoutedDivinationDraft? draft, {bool notify = true}) {
    if (draft == null ||
        draft.tool != DivinationTool.ssgw ||
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

  Future<void> _load() async {
    try {
      await SsgwData.load();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error;
        });
      }
    }
  }

  Future<void> _accept(SsgwResult result) async {
    setState(() {
      _result = result;
      _clearAiReading();
    });
    if (widget.onResultWithQuestion != null) {
      await widget.onResultWithQuestion!(result, _question);
    } else {
      await widget.onResult?.call(result);
    }
  }

  Future<void> _draw() => _accept(SsgwDivination().draw());

  void _clearAiReading() {
    _aiRequestGeneration++;
    _aiLoading = false;
    _aiResponse = null;
    _aiError = null;
  }

  void _reset() {
    setState(() {
      _result = null;
      _clearAiReading();
    });
  }

  Future<void> _requestAiReading() async {
    final result = _result;
    final service = widget.aiService;
    if (result == null || service == null) {
      return;
    }
    final question = _question;
    final reading = SsgwInterpretation.build(result, question: question);
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
          methodLabel: '灵签',
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

  Future<void> _resolve() async {
    final number = int.tryParse(_numberController.text.trim());
    if (number == null || number < 1 || number > 92) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入 1 至 92 的签号')));
      return;
    }
    await _accept(SsgwDivination.resolve(number));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return AppPageContainer(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: '灵签数据加载失败',
          subtitle: _loadError.toString(),
        ),
      );
    }

    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeading(
            title: '三山国王灵签',
            subtitle: '随机抽取或按已有签号查签，共 92 签',
          ),
          AppCard(
            child: TextField(
              key: const ValueKey('ssgw-question-input'),
              controller: _questionController,
              onChanged: (value) => setState(() {
                _topic = DivinationQuestion.inferTopic(value);
              }),
              decoration: const InputDecoration(
                labelText: '求签问题',
                hintText: '写下希望签文重点回应的问题',
                helperText: '问题用于选择最相关的签文栏目，不改变抽签结果',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          if (_result == null) _buildInput(context) else _buildResult(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            key: const ValueKey('ssgw-draw'),
            onPressed: _draw,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('随机抽签'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.space4),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.space3),
                  child: Text('或按签号查询'),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          TextField(
            key: const ValueKey('ssgw-sign-number-input'),
            controller: _numberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '签号（1—92）'),
          ),
          const SizedBox(height: AppTheme.space3),
          OutlinedButton(
            key: const ValueKey('ssgw-resolve'),
            onPressed: _resolve,
            child: const Text('查询签文'),
          ),
        ],
      ),
    ),
  );

  Widget _buildResult(BuildContext context) {
    final result = _result!;
    final sign = result.sign;
    final reading = SsgwInterpretation.build(result, question: _question);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第${sign.number}签',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  sign.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.space4),
                Text(sign.poem, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppTheme.space4),
                Text(sign.story, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        ...sign.details.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value),
            ),
          ),
        ),
        const AppSectionHeading(title: '现代白话解读'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_question.rawText.isNotEmpty) ...[
                  Text('原问题：${_question.rawText}'),
                  const Divider(height: AppTheme.space5),
                ],
                Text(
                  '问题回应 · ${reading.questionIntentLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(reading.directAnswer),
                const Divider(height: AppTheme.space5),
                Text('核心寓意', style: Theme.of(context).textTheme.titleMedium),
                Text(reading.overview),
                const Divider(height: AppTheme.space5),
                Text('当前处境', style: Theme.of(context).textTheme.titleMedium),
                Text(reading.situation),
                const Divider(height: AppTheme.space5),
                Text('行动建议', style: Theme.of(context).textTheme.titleMedium),
                Text(reading.action),
                const Divider(height: AppTheme.space5),
                Text('风险提醒', style: Theme.of(context).textTheme.titleMedium),
                Text(reading.riskReminder),
                const Divider(height: AppTheme.space5),
                Text('判断依据', style: Theme.of(context).textTheme.titleMedium),
                Text(reading.evidence.summary),
                const SizedBox(height: AppTheme.space2),
                for (final item in reading.evidence.supportingEvidence)
                  Text('• ${item.label}：${item.detail}'),
                const SizedBox(height: AppTheme.space2),
                Text(
                  reading.evidence.limitations
                      .map((item) => item.detail)
                      .join('；'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (widget.aiService != null) ...[
          const SizedBox(height: AppTheme.space4),
          const AppSectionHeading(title: 'AI 深度解读'),
          AiInterpretationCard(
            response: _aiResponse,
            loading: _aiLoading,
            error: _aiError,
            onRequest: _requestAiReading,
            loadingText: '正在结合原问题、签诗、典故和分项提示生成解读…',
            idleText: 'AI 将围绕当前问题解读已经抽取的签文，不会重新抽签。',
            actionKey: const ValueKey('ssgw-ai-reading'),
          ),
        ],
        const SizedBox(height: AppTheme.space4),
        OutlinedButton(
          onPressed: _reset,
          child: const Text('重新求签'),
        ),
      ],
    );
  }
}
