import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/meihua/meihua_divination.dart';
import 'package:zhaoxingzhai/core/shared/result.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/data/meihua_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  test('梅花历史按保存载荷恢复而不重新计算', () {
    final result = MeihuaDivination.time(dateTime: DateTime(2024, 2, 5, 12));
    final record = DivinationHistoryRecord(
      id: 'meihua:test',
      type: 'meihua',
      title: '测试',
      summary: '测试',
      createdAt: result.generatedAt,
      payload: {
        ...result.toJson(),
        'interpretation': {
          'id': 'meihua.local-reading',
          'version': 1,
          'traditionalOverview': '保存时概览',
          'situation': '保存时处境',
          'process': '保存时过程',
          'trend': '保存时趋势',
          'action': '保存时建议',
          'riskReminder': '保存时风险',
        },
        'consultationContext': {
          'question': '是否适合推进合作',
          'observation': '窗外有鸟鸣',
          'soundSource': '东方鸟鸣',
          'directionNote': '面向东南',
        },
      },
      algorithmId: result.algorithm.id,
      algorithmVersion: result.algorithm.version,
      schemaVersion: mingyuSchemaVersion,
    );

    final details = MeihuaHistoryDetails.tryParse(record)!;
    expect(details.original.name, '泽天夬');
    expect(details.changed.name, '泽风大过');
    expect(details.movingLine.position, 1);
    expect(details.calculation['lunarYearGanzhi'], '癸卯');
    expect(details.calculation['solarTermYearGanzhi'], '甲辰');
    expect(details.interpretation?.action, '保存时建议');
    expect(details.consultationContext?.question, '是否适合推进合作');
    expect(details.consultationContext?.soundSource, '东方鸟鸣');
  });

  test('损坏的梅花历史安全降级', () {
    final record = DivinationHistoryRecord(
      id: 'meihua:bad',
      type: 'meihua',
      title: '损坏记录',
      summary: '仍保留摘要',
      createdAt: DateTime(2026),
      payload: const {'original': 'bad'},
      algorithmId: 'meihua',
      algorithmVersion: 1,
      schemaVersion: mingyuSchemaVersion,
    );

    expect(MeihuaHistoryDetails.tryParse(record), isNull);
  });
}
