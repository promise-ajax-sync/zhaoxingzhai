import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_service.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/interpretation/meihua_interpretation.dart';
import 'package:zhaoxingzhai/core/models/meihua_consultation_context.dart';
import 'package:zhaoxingzhai/core/models/divination_question.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/widgets/ai_interpretation_card.dart';

class MeihuaPage extends StatefulWidget {
  const MeihuaPage({
    super.key,
    this.onResult,
    this.onResultWithContext,
    this.routedDraft,
    this.aiService,
    this.answerStyle,
    this.onAiResponse,
  });

  final ValueListenable<RoutedDivinationDraft?>? routedDraft;
  final AiInterpretationService? aiService;
  final String Function()? answerStyle;
  final Future<void> Function(
    MeihuaResult result,
    AiInterpretationResponse response,
  )?
  onAiResponse;

  /// 保留单参数回调，兼容旧调用方以及热重载前已创建的 Widget 实例。
  final Future<void> Function(MeihuaResult result)? onResult;

  /// 新调用方使用此回调，同时保存占问背景。
  final Future<void> Function(
    MeihuaResult result,
    MeihuaConsultationContext context,
  )?
  onResultWithContext;

  @override
  State<MeihuaPage> createState() => _MeihuaPageState();
}

class _MeihuaPageState extends State<MeihuaPage> {
  static const _branches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  final _numberController = TextEditingController(text: '123');
  final _seedController = TextEditingController();
  final _soundController = TextEditingController(text: '3');
  final _characterController = TextEditingController(text: '西林');
  final _characterValuesController = TextEditingController(text: '7,8');
  final _questionController = TextEditingController();
  final _observationController = TextEditingController();
  final _soundSourceController = TextEditingController();
  final _directionNoteController = TextEditingController();
  String _direction = 'south';
  String _objectType = 'fire';
  String _topic = 'general';
  MeihuaMethod _method = MeihuaMethod.time;
  String _hourBranch = '辰';
  DateTime _dateTime = DateTime.now();
  MeihuaResult? _result;
  MeihuaConsultationContext? _resultContext;
  Object? _error;
  Object? _loadError;
  bool _loading = true;
  bool _calculating = false;
  bool _aiLoading = false;
  AiInterpretationResponse? _aiResponse;
  Object? _aiError;
  RoutedDivinationDraft? _lastRoutedDraft;

  @override
  void initState() {
    super.initState();
    _applyRoutedDraft(widget.routedDraft?.value, notify: false);
    widget.routedDraft?.addListener(_onRoutedDraftChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant MeihuaPage oldWidget) {
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
    _seedController.dispose();
    _soundController.dispose();
    _characterController.dispose();
    _characterValuesController.dispose();
    _questionController.dispose();
    _observationController.dispose();
    _soundSourceController.dispose();
    _directionNoteController.dispose();
    super.dispose();
  }

  void _onRoutedDraftChanged() => _applyRoutedDraft(widget.routedDraft?.value);

  void _applyRoutedDraft(RoutedDivinationDraft? draft, {bool notify = true}) {
    if (draft == null ||
        draft.tool != DivinationTool.meihua ||
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
      await HexagramData.load();
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _cast() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _calculating = true;
      _error = null;
    });
    try {
      final result = switch (_method) {
        MeihuaMethod.time => MeihuaDivination.time(dateTime: _dateTime),
        MeihuaMethod.number => MeihuaDivination.number(
          number: int.parse(_numberController.text.trim()),
          hourBranch: _hourBranch,
        ),
        MeihuaMethod.sound => MeihuaDivination.sound(
          soundCount: int.parse(_soundController.text.trim()),
          hourBranch: _hourBranch,
        ),
        MeihuaMethod.character => MeihuaDivination.character(
          text: _characterController.text.trim(),
          strokeCounts: _characterController.text.trim().runes.length <= 3
              ? _integerList(_characterValuesController.text)
              : null,
          traditionalTones:
              _characterController.text.trim().runes.length >= 4 &&
                  _characterController.text.trim().runes.length <= 10
              ? _integerList(_characterValuesController.text)
              : null,
        ),
        MeihuaMethod.direction => MeihuaDivination.direction(
          direction: _direction,
          objectType: _objectType,
          hourBranch: _hourBranch,
        ),
        MeihuaMethod.random => MeihuaDivination.random(
          seed: _seedController.text.trim().isEmpty
              ? null
              : _seedController.text.trim(),
        ),
      };
      if (!mounted) return;
      final consultationContext = _consultationContext();
      setState(() {
        _result = result;
        _resultContext = consultationContext;
        _aiResponse = null;
        _aiError = null;
      });
      if (widget.onResultWithContext != null) {
        await widget.onResultWithContext!(result, consultationContext);
      } else {
        await widget.onResult?.call(result);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _requestAiReading() async {
    final result = _result;
    final context = _resultContext;
    final service = widget.aiService;
    if (result == null || context == null || service == null) {
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final interpretation = MeihuaInterpretation.build(
        result,
        topic: context.topic,
        question: DivinationQuestion.parse(
          context.question,
          topic: context.topic,
        ),
      );
      final response = await service.interpret(
        AiInterpretationRequest(
          question: DivinationQuestion.parse(
            context.question,
            topic: context.topic,
          ),
          evidence: interpretation.evidence,
          localAnswer: interpretation.directAnswer,
          methodLabel: '梅花易数',
          answerStyle: widget.answerStyle?.call() ?? 'balanced',
        ),
      );
      if (mounted) {
        setState(() => _aiResponse = response);
      }
      await widget.onAiResponse?.call(result, response);
    } catch (error) {
      if (mounted) {
        setState(() => _aiError = error);
      }
    } finally {
      if (mounted) {
        setState(() => _aiLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (value == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(
        value.year,
        value.month,
        value.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (value == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        value.hour,
        value.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoadingIndicator(message: '加载卦象数据...');
    if (_loadError != null) {
      return AppPageContainer(
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: '梅花易数加载失败',
          subtitle: _loadError.toString(),
        ),
      );
    }

    return AppPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeading(
            title: '梅花易数',
            subtitle: '时间、数字、声音、文字、方位与随机起卦 · 主互变与体用关系',
          ),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              for (final option in const [
                (MeihuaMethod.time, '时间'),
                (MeihuaMethod.number, '数字'),
                (MeihuaMethod.sound, '声音'),
                (MeihuaMethod.character, '文字'),
                (MeihuaMethod.direction, '方位'),
                (MeihuaMethod.random, '随机'),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: _method == option.$1,
                  onSelected: (_) => setState(() => _method = option.$1),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          _contextCard(),
          const SizedBox(height: AppTheme.space4),
          _inputCard(),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.space3),
            Text(
              '无法起卦：$_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppTheme.space4),
          FilledButton.icon(
            key: const ValueKey('meihua-cast'),
            onPressed: _calculating ? null : _cast,
            icon: _calculating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_calculating ? '正在起卦' : '开始起卦'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTheme.space5),
            _MeihuaResultView(
              result: _result!,
              consultationContext: _resultContext,
            ),
            if (widget.aiService != null) ...[
              const SizedBox(height: AppTheme.space5),
              const AppSectionHeading(title: 'AI 深度解读'),
              AiInterpretationCard(
                response: _aiResponse,
                loading: _aiLoading,
                error: _aiError,
                onRequest: _requestAiReading,
                loadingText: '正在结合问题和梅花卦盘生成解读…',
                idleText: _resultContext?.question.trim().isEmpty == true
                    ? '未填写具体问题，AI 将依据本次梅花卦盘生成通用解读。'
                    : 'AI 将基于当前问题和已经计算完成的梅花卦盘继续解读，不会重新起卦。',
                actionKey: const ValueKey('meihua-ai-reading'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _inputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: switch (_method) {
          MeihuaMethod.time => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('北京时间', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.space3),
              Wrap(
                spacing: AppTheme.space3,
                runSpacing: AppTheme.space3,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_dateLabel(_dateTime)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_timeLabel(_dateTime)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _dateTime = DateTime.now()),
                    child: const Text('使用当前时间'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space2),
              const Text('按农历年支、农历月日和民用时支取数；00:00 换日。'),
            ],
          ),
          MeihuaMethod.number => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '正整数',
                    hintText: '例如 123',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              DropdownButton<String>(
                value: _hourBranch,
                items: [
                  for (final branch in _branches)
                    DropdownMenuItem(value: branch, child: Text('$branch时')),
                ],
                onChanged: (value) => setState(() => _hourBranch = value!),
              ),
            ],
          ),
          MeihuaMethod.sound => Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _soundController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '声音次数',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              _branchDropdown(),
            ],
          ),
          MeihuaMethod.character => Column(
            children: [
              TextField(
                controller: _characterController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '文字（1至100字）',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_characterController.text.trim().runes.length <= 10) ...[
                const SizedBox(height: AppTheme.space3),
                TextField(
                  controller: _characterValuesController,
                  decoration: InputDecoration(
                    labelText:
                        _characterController.text.trim().runes.length <= 3
                        ? '笔画数（逗号分隔；单字填左右部首）'
                        : '平上去入数值（1/2/3/4，逗号分隔）',
                    helperText:
                        _characterController.text.trim().runes.length <= 3
                        ? '每项须为正整数'
                        : '采用传统平上去入，不是普通话声调',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          MeihuaMethod.direction => Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space3,
            children: [
              DropdownButton<String>(
                value: _direction,
                items: const [
                  DropdownMenuItem(value: 'northwest', child: Text('西北')),
                  DropdownMenuItem(value: 'west', child: Text('西')),
                  DropdownMenuItem(value: 'south', child: Text('南')),
                  DropdownMenuItem(value: 'east', child: Text('东')),
                  DropdownMenuItem(value: 'southeast', child: Text('东南')),
                  DropdownMenuItem(value: 'north', child: Text('北')),
                  DropdownMenuItem(value: 'northeast', child: Text('东北')),
                  DropdownMenuItem(value: 'southwest', child: Text('西南')),
                ],
                onChanged: (value) => setState(() => _direction = value!),
              ),
              DropdownButton<String>(
                value: _objectType,
                items: const [
                  DropdownMenuItem(value: 'heaven', child: Text('天象')),
                  DropdownMenuItem(value: 'lake', child: Text('泽物')),
                  DropdownMenuItem(value: 'fire', child: Text('火物')),
                  DropdownMenuItem(value: 'thunder', child: Text('雷动')),
                  DropdownMenuItem(value: 'wind', child: Text('风木')),
                  DropdownMenuItem(value: 'water', child: Text('水物')),
                  DropdownMenuItem(value: 'mountain', child: Text('山石')),
                  DropdownMenuItem(value: 'earth', child: Text('地土')),
                ],
                onChanged: (value) => setState(() => _objectType = value!),
              ),
              _branchDropdown(),
            ],
          ),
          MeihuaMethod.random => TextField(
            controller: _seedController,
            decoration: const InputDecoration(
              labelText: '固定种子（可选）',
              hintText: '留空使用系统随机；填写后可复现',
              border: OutlineInputBorder(),
            ),
          ),
        },
      ),
    );
  }

  Widget _contextCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('占问背景（可选）', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<String>(
            initialValue: _topic,
            decoration: const InputDecoration(
              labelText: '占问分类',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('综合事项')),
              DropdownMenuItem(value: 'career', child: Text('事业工作')),
              DropdownMenuItem(value: 'relationship', child: Text('感情关系')),
              DropdownMenuItem(value: 'wealth', child: Text('财运经营')),
              DropdownMenuItem(value: 'health', child: Text('健康状态')),
              DropdownMenuItem(value: 'study', child: Text('学业考试')),
            ],
            onChanged: (value) => setState(() => _topic = value!),
          ),
          const SizedBox(height: AppTheme.space3),
          TextField(
            key: const ValueKey('meihua-question-input'),
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: '占问主题',
              hintText: '例如：这项合作接下来如何推进？',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          TextField(
            controller: _observationController,
            decoration: const InputDecoration(
              labelText: '所见物象或现场情况',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _soundSourceController,
                  decoration: const InputDecoration(
                    labelText: '声音来源',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: TextField(
                  controller: _directionNoteController,
                  decoration: const InputDecoration(
                    labelText: '方位说明',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  MeihuaConsultationContext _consultationContext() => MeihuaConsultationContext(
    question: _questionController.text.trim(),
    observation: _observationController.text.trim(),
    soundSource: _soundSourceController.text.trim(),
    directionNote: _directionNoteController.text.trim(),
    topic: _topic,
  );

  Widget _branchDropdown() => DropdownButton<String>(
    value: _hourBranch,
    items: [
      for (final branch in _branches)
        DropdownMenuItem(value: branch, child: Text('$branch时')),
    ],
    onChanged: (value) => setState(() => _hourBranch = value!),
  );

  static List<int> _integerList(String value) => value
      .split(RegExp(r'[,，\s]+'))
      .where((item) => item.isNotEmpty)
      .map(int.parse)
      .toList();

  static String _dateLabel(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static String _timeLabel(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _MeihuaResultView extends StatelessWidget {
  const _MeihuaResultView({required this.result, this.consultationContext});

  final MeihuaResult result;
  final MeihuaConsultationContext? consultationContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(result.methodLabel, style: Theme.of(context).textTheme.titleLarge),
        if (consultationContext != null && !consultationContext!.isEmpty) ...[
          const SizedBox(height: AppTheme.space3),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '本次占问背景',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('分类：${consultationContext!.topicLabel}'),
                  if (consultationContext!.question.isNotEmpty)
                    Text('占问：${consultationContext!.question}'),
                  if (consultationContext!.observation.isNotEmpty)
                    Text('物象：${consultationContext!.observation}'),
                  if (consultationContext!.soundSource.isNotEmpty)
                    Text('声音来源：${consultationContext!.soundSource}'),
                  if (consultationContext!.directionNote.isNotEmpty)
                    Text('方位说明：${consultationContext!.directionNote}'),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.space3),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 720
                ? (constraints.maxWidth - AppTheme.space3 * 2) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: AppTheme.space3,
              runSpacing: AppTheme.space3,
              children: [
                _HexagramCard(
                  label: '本卦',
                  value: result.original,
                  width: width,
                ),
                _HexagramCard(label: '互卦', value: result.inter, width: width),
                _HexagramCard(label: '变卦', value: result.changed, width: width),
              ],
            );
          },
        ),
        const AppSectionHeading(title: '动爻与体用'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${result.movingYaoName}：${result.movingYaoCi}'),
                const Divider(height: AppTheme.space5),
                Text('体卦：${result.tiGua.name} · ${result.tiGua.element}'),
                Text('用卦：${result.yongGua.name} · ${result.yongGua.element}'),
                Text('体用关系：${result.tiYongRelation}'),
              ],
            ),
          ),
        ),
        if (result.method == MeihuaMethod.time) ...[
          const AppSectionHeading(title: '历法与取数'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Text(
                '农历${result.calculation['lunarYearGanzhi']}年 '
                '${result.calculation['month']}月${result.calculation['day']}日 · '
                '${result.calculation['timeZhi']}时\n'
                '年支序${result.calculation['yearZhiIndex']}，'
                '时支序${result.calculation['timeZhiIndex']}；'
                '上卦${result.upperTrigramIndex}、下卦${result.lowerTrigramIndex}、'
                '动爻${result.movingYaoIndex}\n'
                '节气干支年：${result.calculation['solarTermYearGanzhi']}（仅作历法证据，不参与年支取数）',
              ),
            ),
          ),
        ],
        const AppSectionHeading(title: '现代白话解读'),
        _MeihuaInterpretationView(
          interpretation: MeihuaInterpretation.build(
            result,
            topic: consultationContext?.topic ?? 'general',
            question: DivinationQuestion.parse(
              consultationContext?.question ?? '',
              topic: consultationContext?.topic ?? 'general',
            ),
          ),
        ),
      ],
    );
  }
}

class _MeihuaInterpretationView extends StatelessWidget {
  const _MeihuaInterpretationView({required this.interpretation});

  final MeihuaInterpretation interpretation;

  @override
  Widget build(BuildContext context) {
    final sections = [
      (
        '问题回应 · ${interpretation.questionIntentLabel}',
        interpretation.directAnswer,
      ),
      ('判断依据', interpretation.evidenceSummary),
      (
        '反证与边界',
        [
          ...interpretation.evidence.counterEvidence,
          ...interpretation.evidence.limitations,
        ].map((item) => '${item.label}：${item.detail}').join('\n'),
      ),
      ('传统概览', interpretation.traditionalOverview),
      ('当前处境', interpretation.situation),
      ('内部过程', interpretation.process),
      ('变化趋势', interpretation.trend),
      ('${interpretation.topicLabel}提示', interpretation.topicGuidance),
      ('行动建议', interpretation.action),
      ('风险提醒', interpretation.riskReminder),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < sections.length; index++) ...[
              Text(
                sections[index].$1,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.space1),
              Text(sections[index].$2),
              if (index != sections.length - 1)
                const Divider(height: AppTheme.space5),
            ],
            const SizedBox(height: AppTheme.space3),
            Text(
              '本地解释版本：${interpretation.id} v${interpretation.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HexagramCard extends StatelessWidget {
  const _HexagramCard({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final Hexagram value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppTheme.space2),
              Text(
                value.symbol,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text(value.name, style: Theme.of(context).textTheme.titleMedium),
              Text('上${value.upper}下${value.lower}'),
            ],
          ),
        ),
      ),
    );
  }
}
