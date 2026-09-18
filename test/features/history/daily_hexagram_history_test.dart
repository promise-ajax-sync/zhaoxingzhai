import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/features/history/data/daily_hexagram_history.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

void main() {
  DivinationHistoryRecord record(int version, Map<String, dynamic> payload) =>
      DivinationHistoryRecord(
        id: 'daily-$version',
        type: 'daily-hexagram',
        title: '每日一卦',
        summary: '测试',
        createdAt: DateTime(2026, 9, 17),
        payload: payload,
        algorithmId: 'daily-hexagram',
        algorithmVersion: version,
        schemaVersion: '1',
      );

  const qian = {
    'name': '乾为天',
    'symbol': '☰☰',
    'description': '元亨利贞',
    'upper': '乾',
    'lower': '乾',
  };
  const kun = {
    'name': '坤为地',
    'symbol': '☷☷',
    'description': '元亨，利牝马之贞',
    'upper': '坤',
    'lower': '坤',
  };

  test('兼容 v1 单卦历史且不按新规则重算', () {
    final details = DailyHexagramHistoryDetails.tryParse(
      record(1, {'dateKey': '2026-09-17', 'hexagram': qian}),
    );

    expect(details, isNotNull);
    expect(details!.original.name, '乾为天');
    expect(details.changed, isNull);
    expect(details.yaos, isEmpty);
    expect(details.compatibilityNotice, contains('仅展示原始单卦'));
  });

  test('兼容 v2 三卦和动爻但不伪造取用规则', () {
    final details = DailyHexagramHistoryDetails.tryParse(
      record(2, {
        'original': qian,
        'changed': kun,
        'inter': qian,
        'yaos': [9, 7, 7, 7, 7, 7],
        'movingLines': [
          {'position': 1, 'name': '初爻', 'type': '老阳', 'text': '潜龙勿用'},
        ],
      }),
    );

    expect(details!.changed?.name, '坤为地');
    expect(details.movingLines.single.text, '潜龙勿用');
    expect(details.takingSummary, isNull);
    expect(details.compatibilityNotice, contains('不使用 v3 规则重新解释'));
  });

  test('完整恢复 v3 取用规则', () {
    final details = DailyHexagramHistoryDetails.tryParse(
      record(3, {
        'original': qian,
        'changed': kun,
        'inter': qian,
        'yaos': [9, 9, 9, 9, 9, 9],
        'coinThrows': List.generate(
          6,
          (_) => {
            'coins': [3, 3, 3],
            'total': 9,
          },
        ),
        'takingRule': {
          'summary': '六爻皆动，乾坤卦取用九或用六。',
          'primaryTexts': ['见群龙无首，吉'],
          'secondaryTexts': <String>[],
        },
        'interpretation': {
          'id': 'daily-hexagram.local-reading',
          'version': 1,
          'traditionalOverview': '传统概览',
          'situation': '当前处境',
          'innerContext': '内在条件',
          'trend': '变化趋势',
          'pace': '行动节奏',
          'riskReminder': '风险提醒',
        },
      }),
    );

    expect(details!.takingSummary, contains('用九或用六'));
    expect(details.primaryTexts, ['见群龙无首，吉']);
    expect(details.coinThrows, hasLength(6));
    expect(details.coinThrows.first, [3, 3, 3]);
    expect(details.interpretation?.version, 1);
    expect(details.interpretation?.trend, '变化趋势');
    expect(details.isLegacy, isFalse);
  });

  test('损坏或非每日一卦记录安全降级', () {
    expect(
      DailyHexagramHistoryDetails.tryParse(record(3, {'original': 'bad'})),
      isNull,
    );
    final other = DivinationHistoryRecord(
      id: 'tarot',
      type: 'tarot',
      title: '塔罗',
      summary: '测试',
      createdAt: DateTime(2026),
      payload: const {},
      algorithmId: 'tarot',
      algorithmVersion: 1,
      schemaVersion: '1',
    );
    expect(DailyHexagramHistoryDetails.tryParse(other), isNull);
  });
}
