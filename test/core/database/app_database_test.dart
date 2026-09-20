import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('角色与历史记录可以独立写入 Drift', () async {
    final now = DateTime(2026, 9, 20, 12);
    await database.replaceCases([
      LocalCasesCompanion.insert(
        id: 'role-1',
        profileJson: '{"id":"role-1","name":"小明"}',
        updatedAt: now,
      ),
    ]);
    await database.replaceHistoryRecords([
      LocalHistoryRecordsCompanion.insert(
        id: 'record-1',
        recordJson: '{"id":"record-1"}',
        createdAt: now,
      ),
    ]);

    final roles = await database.loadCases();
    final records = await database.loadHistoryRecords();

    expect(roles.single.id, 'role-1');
    expect(records.single.id, 'record-1');
  });

  test('数据迁移标记可以覆盖更新', () async {
    await database.setMetadataValue('migration', 'pending');
    await database.setMetadataValue('migration', 'done');

    expect(await database.metadataValue('migration'), 'done');
  });
}
