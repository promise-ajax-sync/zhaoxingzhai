import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/engine/xiaoliuren/algorithm.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('历史记录可以持久化、重新读取和删除', () async {
    final createdAt = DateTime(2026, 9, 17, 12, 30);
    final repository = DivinationHistoryRepository();

    await repository.add(
      DivinationHistoryRecord(
        id: 'test:1',
        type: 'tarot',
        title: '单牌指引',
        summary: '当前指引：愚者正位',
        createdAt: createdAt,
        payload: const {'spreadType': 'single'},
      ),
    );

    final reloaded = DivinationHistoryRepository();
    await reloaded.ensureLoaded();

    expect(reloaded.records, hasLength(1));
    expect(reloaded.records.single.title, '单牌指引');
    expect(reloaded.records.single.createdAt, createdAt);

    await reloaded.delete('test:1');
    expect(reloaded.records, isEmpty);

    repository.dispose();
    reloaded.dispose();
  });

  test('相同结果标识会更新并移动到最前而不是重复保存', () async {
    final repository = DivinationHistoryRepository();
    final older = DateTime(2026, 9, 16);
    final newer = DateTime(2026, 9, 17);

    await repository.add(
      DivinationHistoryRecord(
        id: 'same-result',
        type: 'xiaoliuren',
        title: '旧记录',
        summary: '旧摘要',
        createdAt: older,
        payload: const {},
      ),
    );
    await repository.add(
      DivinationHistoryRecord(
        id: 'same-result',
        type: 'xiaoliuren',
        title: '新记录',
        summary: '新摘要',
        createdAt: newer,
        payload: const {},
      ),
    );

    expect(repository.records, hasLength(1));
    expect(repository.records.single.title, '新记录');
    expect(repository.records.single.createdAt, newer);

    repository.dispose();
  });

  test('小六壬结果可以转换为历史记录并保留完整载荷', () async {
    final repository = DivinationHistoryRepository();
    final result = generateXiaoliuren(customDate: DateTime(2026, 9, 17, 12));

    await repository.addXiaoliuren(result);

    expect(repository.records, hasLength(1));
    expect(repository.records.single.type, 'xiaoliuren');
    expect(repository.records.single.title, contains(result.primary.name));
    expect(repository.records.single.payload['meta'], isA<Map>());
    expect(repository.records.single.payload['primary'], isA<Map>());

    repository.dispose();
  });
}
