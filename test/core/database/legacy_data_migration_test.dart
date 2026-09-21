import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/database/app_database.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/data/history_sync_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => database.close());

  test('旧角色、服务端映射和待删除队列会完整迁移到 Drift', () async {
    final profile = CaseProfile.create(
      name: '迁移角色',
      gender: CaseGender.female,
      calendarType: CaseCalendarType.lunar,
      birthDateTime: DateTime(1996, 8, 15, 9, 30),
      isLeapMonth: true,
      longitude: 116.4074,
      latitude: 39.9042,
      placeName: '北京',
      note: '旧版本备注',
      now: DateTime(2026, 9, 1),
    );
    SharedPreferences.setMockInitialValues({
      CaseRepository.storageKey: jsonEncode([profile.toJson()]),
      CaseRepository.serverIdsKey: jsonEncode({profile.id: 'server-case-1'}),
      CaseRepository.pendingDeletesKey: jsonEncode({
        'case:deleted': 'server-case-deleted',
      }),
      CaseRepository.serverVersionsKey: jsonEncode({
        profile.id: 3,
        'case:deleted': 5,
      }),
    });

    final repository = CaseRepository(database: database);
    await repository.ensureLoaded();

    expect(repository.loadError, isNull);
    expect(repository.cases, hasLength(1));
    expect(repository.cases.single.toJson(), profile.toJson());
    expect(
      await database.metadataValue('migration.shared_preferences.cases.v1'),
      'done',
    );
    final syncRows = await database.loadCaseSyncStates();
    expect(
      syncRows,
      contains(
        isA<LocalCaseSyncState>()
            .having((row) => row.localId, 'localId', profile.id)
            .having((row) => row.serverId, 'serverId', 'server-case-1'),
      ),
    );
    expect(
      jsonDecode(
        (await database.metadataValue('sync.case_server_versions.v1'))!,
      ),
      {profile.id: 3, 'case:deleted': 5},
    );
    expect(
      syncRows,
      contains(
        isA<LocalCaseSyncState>()
            .having((row) => row.localId, 'localId', 'case:deleted')
            .having(
              (row) => row.pendingDeleteServerId,
              'pendingDeleteServerId',
              'server-case-deleted',
            ),
      ),
    );

    repository.dispose();
  });

  test('旧历史、角色快照和同步状态会迁移且重启后仍可读取', () async {
    final profile = CaseProfile.create(
      name: '历史角色',
      birthDateTime: DateTime(1990, 5, 1, 8, 30),
      now: DateTime(2026, 9, 2),
    );
    final record = DivinationHistoryRecord(
      id: 'legacy-history-1',
      type: 'tarot',
      title: '旧版塔罗记录',
      summary: '保留旧摘要',
      createdAt: DateTime(2026, 9, 2, 12),
      payload: const {'spreadType': 'single'},
      algorithmId: 'tarot',
      algorithmVersion: 1,
      schemaVersion: '1.0.0',
      caseSnapshot: profile.toSnapshot(),
    );
    final syncState = HistorySyncState(
      recordId: record.id,
      status: HistorySyncStatus.pendingDelete,
      serverRecordId: 'server-history-1',
      serverVersion: 4,
      retryCount: 2,
      lastError: '等待恢复网络',
    );
    SharedPreferences.setMockInitialValues({
      DivinationHistoryRepository.storageKey: jsonEncode([record.toJson()]),
      DivinationHistoryRepository.syncStorageKey: jsonEncode([
        syncState.toJson(),
      ]),
    });

    final first = DivinationHistoryRepository(database: database);
    await first.ensureLoaded();

    expect(first.loadError, isNull);
    expect(first.records.single.caseSnapshot!.name, '历史角色');
    expect(
      first.syncStateFor(record.id).status,
      HistorySyncStatus.pendingDelete,
    );
    expect(first.syncStateFor(record.id).serverRecordId, 'server-history-1');
    expect(first.syncStateFor(record.id).serverVersion, 4);
    expect(
      await database.metadataValue('migration.shared_preferences.history.v1'),
      'done',
    );
    first.dispose();

    SharedPreferences.setMockInitialValues({});
    final reloaded = DivinationHistoryRepository(database: database);
    await reloaded.ensureLoaded();

    expect(reloaded.records, hasLength(1));
    expect(reloaded.records.single.toJson(), record.toJson());
    expect(
      reloaded.syncStateFor(record.id).status,
      HistorySyncStatus.pendingDelete,
    );
    expect(reloaded.syncStateFor(record.id).retryCount, 2);
    expect(reloaded.syncStateFor(record.id).serverVersion, 4);

    reloaded.dispose();
  });

  test('迁移标记完成后不会用后来出现的旧缓存覆盖 Drift 数据', () async {
    final original = CaseProfile.create(
      name: '首次迁移',
      birthDateTime: DateTime(1991, 1, 1),
      now: DateTime(2026, 9, 3),
    );
    SharedPreferences.setMockInitialValues({
      CaseRepository.storageKey: jsonEncode([original.toJson()]),
    });
    final first = CaseRepository(database: database);
    await first.ensureLoaded();
    first.dispose();

    final driftOnly = CaseProfile.create(
      name: 'Drift 新数据',
      birthDateTime: DateTime(1992, 2, 2),
      now: DateTime(2026, 9, 4),
    );
    final writer = CaseRepository(database: database);
    await writer.ensureLoaded();
    await writer.add(driftOnly);
    writer.dispose();

    final staleLegacy = CaseProfile.create(
      name: '不应再次导入',
      birthDateTime: DateTime(1993, 3, 3),
      now: DateTime(2026, 9, 5),
    );
    SharedPreferences.setMockInitialValues({
      CaseRepository.storageKey: jsonEncode([staleLegacy.toJson()]),
    });
    final reloaded = CaseRepository(database: database);
    await reloaded.ensureLoaded();

    expect(reloaded.cases.map((item) => item.name), {'首次迁移', 'Drift 新数据'});
    expect(reloaded.findById(staleLegacy.id), isNull);

    reloaded.dispose();
  });
}
