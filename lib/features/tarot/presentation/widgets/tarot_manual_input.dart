import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart' as tarot_loader;
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/core/widgets/app_widgets.dart';
import 'package:zhaoxingzhai/features/tarot/tarot_divination.dart';

class TarotManualInput extends StatefulWidget {
  final String spreadType;
  final bool isSubmitting;
  final ValueChanged<List<ManualCardInput>> onSubmit;

  const TarotManualInput({
    super.key,
    required this.spreadType,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<TarotManualInput> createState() => _TarotManualInputState();
}

class _TarotManualInputState extends State<TarotManualInput> {
  late List<int?> _cardIds;
  late List<bool> _reversed;
  String? _errorText;

  tarot_loader.TarotSpread get _spread =>
      tarot_loader.TarotData.spreads[widget.spreadType]!;

  @override
  void initState() {
    super.initState();
    _resetInputs();
  }

  @override
  void didUpdateWidget(covariant TarotManualInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spreadType != widget.spreadType) {
      _resetInputs();
    }
  }

  void _resetInputs() {
    final count = tarot_loader.TarotData.spreads[widget.spreadType]!.cardCount;
    _cardIds = List<int?>.filled(count, null);
    _reversed = List<bool>.filled(count, false);
    _errorText = null;
  }

  void _submit() {
    if (_cardIds.any((id) => id == null)) {
      setState(() => _errorText = '请先录入全部 ${_spread.cardCount} 张牌');
      return;
    }

    final ids = _cardIds.cast<int>();
    if (ids.toSet().length != ids.length) {
      setState(() => _errorText = '同一次牌阵不能重复选择同一张牌');
      return;
    }

    setState(() => _errorText = null);
    widget.onSubmit(
      List.generate(
        ids.length,
        (index) => ManualCardInput(id: ids[index], reversed: _reversed[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = tarot_loader.TarotData.cards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeading(title: '录入实体牌面'),
        Text(
          '按实际抽牌顺序选择牌面，并标记正位或逆位。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTheme.space3),
        ...List.generate(_spread.cardCount, (index) {
          final selectedId = _cardIds[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${index + 1}. ${_spread.positions[index]}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.space3),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '牌面',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        key: ValueKey('manual-card-$index'),
                        value: selectedId,
                        isExpanded: true,
                        hint: const Text('请选择塔罗牌'),
                        items: cards
                            .map(
                              (card) => DropdownMenuItem<int>(
                                value: card.number,
                                child: Text(
                                  '${card.number.toString().padLeft(2, '0')} · ${card.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: widget.isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _cardIds[index] = value;
                                  _errorText = null;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('逆位'),
                    subtitle: Text(_reversed[index] ? '当前记录为逆位' : '当前记录为正位'),
                    value: _reversed[index],
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) {
                            setState(() => _reversed[index] = value);
                          },
                  ),
                ],
              ),
            ),
          );
        }),
        if (_errorText != null) ...[
          Text(
            _errorText!,
            key: const ValueKey('manual-input-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: AppTheme.space3),
        ],
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: widget.isSubmitting ? null : _submit,
            icon: widget.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(widget.isSubmitting ? '生成中...' : '生成手动牌阵'),
          ),
        ),
      ],
    );
  }
}
