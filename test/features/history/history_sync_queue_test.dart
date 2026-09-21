import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/ai/ai_interpretation_models.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/data/history_cloud_sync.dart';
import 'package:zhaoxingzhai/features/history/data/history_sync_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('新历史先本地保存并在后台标记为已同步', () async {
    final cloud = _FakeCloudSync();
    final repository = DivinationHistoryRepository(cloudSync: cloud);
    final record = _record('record-1');

    await repository.add(record);
    await repository.processPendingSync();
    await _waitFor(
      () =>
          repository.syncStateFor(record.id).status == HistorySyncStatus.synced,
    );

    expect(repository.records.single.id, record.id);
    expect(repository.syncStateFor(record.id).status, HistorySyncStatus.synced);
    expect(
      repository.syncStateFor(record.id).serverRecordId,
      'server-record-1',
    );
    expect(repository.syncStateFor(record.id).serverVersion, 1);
    expect(cloud.syncedRecords, contains(record.id));
    repository.dispose();
  });

  test('同步失败被持久化并可手动重试', () async {
    final cloud = _FakeCloudSync(failuresRemaining: 1);
    final repository = DivinationHistoryRepository(cloudSync: cloud);
    final record = _record('record-2');

    await repository.add(record);
    await repository.processPendingSync();
    await _waitFor(
      () =>
          repository.syncStateFor(record.id).status == HistorySyncStatus.failed,
    );
    expect(repository.syncStateFor(record.id).status, HistorySyncStatus.failed);

    await repository.retrySync(record.id);
    await repository.processPendingSync();
    await _waitFor(
      () =>
          repository.syncStateFor(record.id).status == HistorySyncStatus.synced,
    );
    expect(repository.syncStateFor(record.id).status, HistorySyncStatus.synced);
    repository.dispose();
  });

  test('删除已同步历史会同步服务器删除', () async {
    final cloud = _FakeCloudSync();
    final repository = DivinationHistoryRepository(cloudSync: cloud);
    final record = _record('record-3');
    await repository.add(record);
    await repository.processPendingSync();
    await _waitFor(
      () =>
          repository.syncStateFor(record.id).status == HistorySyncStatus.synced,
    );

    await repository.delete(record.id);
    await repository.processPendingSync();
    await _waitFor(() => cloud.deletedServerIds.isNotEmpty);

    expect(repository.records, isEmpty);
    expect(cloud.deletedServerIds, contains('server-record-3'));
    repository.dispose();
  });

  test('启动时会下载云端历史并标记为已同步', () async {
    final cloudRecord = _record('cloud-record');
    final cloud = _FakeCloudSync(
      fetchedRecords: [
        CloudHistoryRecord(
          serverId: 'server-cloud-record',
          record: cloudRecord,
          version: 3,
        ),
      ],
    );
    final repository = DivinationHistoryRepository(cloudSync: cloud);

    await repository.ensureLoaded();

    expect(repository.records.single.id, cloudRecord.id);
    expect(
      repository.syncStateFor(cloudRecord.id).status,
      HistorySyncStatus.synced,
    );
    expect(
      repository.syncStateFor(cloudRecord.id).serverRecordId,
      'server-cloud-record',
    );
    expect(repository.syncStateFor(cloudRecord.id).serverVersion, 3);
    repository.dispose();
  });

  test('增量同步墓碑会移除另一设备已经删除的历史', () async {
    final record = _record('remote-deleted');
    SharedPreferences.setMockInitialValues({
      DivinationHistoryRepository.storageKey: jsonEncode([record.toJson()]),
      DivinationHistoryRepository.syncStorageKey: jsonEncode([
        HistorySyncState(
          recordId: record.id,
          status: HistorySyncStatus.synced,
          serverRecordId: 'server-remote-deleted',
          serverVersion: 2,
        ).toJson(),
      ]),
    });
    final cloud = _FakeCloudSync(
      fetchedChanges: [
        CloudHistoryChange(
          serverId: 'server-remote-deleted',
          clientRecordId: record.id,
          version: 3,
          deleted: true,
        ),
      ],
    );
    final repository = DivinationHistoryRepository(cloudSync: cloud);

    await repository.ensureLoaded();

    expect(repository.records, isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(DivinationHistoryRepository.syncCursorKey),
      'cursor-1',
    );
    expect(
      repository.syncStateFor(record.id).status,
      HistorySyncStatus.pending,
    );
    repository.dispose();
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('等待同步状态超时');
}

DivinationHistoryRecord _record(String id) => DivinationHistoryRecord(
  id: id,
  type: 'tarot',
  title: '测试记录',
  summary: '测试摘要',
  createdAt: DateTime(2026, 9, 19),
  payload: const {'spreadType': 'single'},
  algorithmId: 'tarot',
  algorithmVersion: 1,
  schemaVersion: '1.0.0',
);

class _FakeCloudSync implements HistoryCloudSync {
  _FakeCloudSync({
    this.failuresRemaining = 0,
    this.fetchedRecords = const [],
    this.fetchedChanges = const [],
  });

  int failuresRemaining;
  final List<CloudHistoryRecord> fetchedRecords;
  final List<CloudHistoryChange> fetchedChanges;
  final List<String> syncedRecords = [];
  final List<String> deletedServerIds = [];

  @override
  Future<List<CloudHistoryRecord>> fetchRecords() async => fetchedRecords;

  @override
  Future<CloudHistoryChangeBatch> fetchChanges(String? cursor) async =>
      CloudHistoryChangeBatch(
        cursor: 'cursor-1',
        items: fetchedChanges.isNotEmpty
            ? fetchedChanges
            : fetchedRecords
                  .map(
                    (item) => CloudHistoryChange(
                      serverId: item.serverId,
                      clientRecordId: item.record.id,
                      version: item.version,
                      deleted: false,
                      record: item.record,
                    ),
                  )
                  .toList(),
      );

  @override
  Future<CloudHistoryWriteResult> syncRecord(
    DivinationHistoryRecord record, {
    int? baseVersion,
  }) async {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw StateError('暂时不可用');
    }
    syncedRecords.add(record.id);
    return CloudHistoryWriteResult(
      serverId: 'server-${record.id}',
      version: (baseVersion ?? 0) + 1,
    );
  }

  @override
  Future<void> syncAiInterpretation(
    DivinationHistoryRecord record,
    AiInterpretationResponse response, {
    required String answerStyle,
    required String serverRecordId,
  }) async {}

  @override
  Future<void> deleteRecord(String serverRecordId, {int? baseVersion}) async {
    deletedServerIds.add(serverRecordId);
  }
}
