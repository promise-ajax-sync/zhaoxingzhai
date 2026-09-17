/// 塔罗占卜页面
/// 参考 SYDF TarotView.vue
library;

import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart' as tarot_loader;
import 'package:zhaoxingzhai/core/engine/tarot/tarot_divination.dart';

import 'widgets/tarot_spread_selector.dart';
import 'widgets/tarot_card_deck.dart';
import 'widgets/tarot_manual_input.dart';
import 'widgets/tarot_result_display.dart';

enum _TarotInputMode { automatic, manual }

class TarotPage extends StatefulWidget {
  final Future<void> Function()? loadData;
  final Future<void> Function(TarotDrawResult)? onResult;

  const TarotPage({super.key, this.loadData, this.onResult});

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

  @override
  void initState() {
    super.initState();
    _initTarot();
  }

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
    });
  }

  Future<void> _saveResult(TarotDrawResult result) async {
    try {
      await widget.onResult?.call(result);
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
                if (_result != null) ...[TarotResultDisplay(result: _result!)],
              ],
            ),
          );
  }

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
