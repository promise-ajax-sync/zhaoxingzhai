/// 案例仓储：当前设备上的案例增删查改。
///
/// 生产环境使用 Drift 持久化；SharedPreferences 仅用于旧数据迁移和兼容性测试。
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/database/app_database.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/core/sync/sync_version_conflict.dart';
import 'package:zhaoxingzhai/features/cases/data/case_cloud_sync.dart';

class CaseRepository extends ChangeNotifier {
  CaseRepository({
    Future<SharedPreferences> Function()? preferencesFactory,
    CaseCloudSync? cloudSync,
    this.database,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _cloudSync = _retainCloudSync(cloudSync);

  static CaseCloudSync? _retainCloudSync(CaseCloudSync? value) => value;

  static const String storageKey = 'zhaoxingzhai.cases.v1';
  static const String serverIdsKey = 'zhaoxingzhai.case_server_ids.v1';
  static const String pendingDeletesKey =
      'zhaoxingzhai.case_pending_deletes.v1';
  static const String serverVersionsKey =
      'zhaoxingzhai.case_server_versions.v1';
  static const String _databaseVersionsKey = 'sync.case_server_versions.v1';
  static const String _databaseCursorKey = 'sync.case_cursor.v1';
  static const String _databasePendingUpsertsKey =
      'sync.case_pending_upserts.v1';
  static const String syncCursorKey = 'zhaoxingzhai.case_sync_cursor.v1';
  static const String pendingUpsertsKey =
      'zhaoxingzhai.case_pending_upserts.v1';

  final Future<SharedPreferences> Function() _preferencesFactory;
  final CaseCloudSync? _cloudSync;
  final AppDatabase? database;
  final List<CaseProfile> _cases = [];
  final Map<String, String> _serverIds = {};
  final Map<String, String> _pendingDeletes = {};
  final Map<String, int> _serverVersions = {};
  final Set<String> _pendingUpserts = {};
  String? _syncCursor;
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  String? _loadError;

  List<CaseProfile> get cases => List.unmodifiable(_cases);
  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final localDatabase = database;
      if (localDatabase != null) {
        await _loadFromDatabase(localDatabase);
        await _migrateLegacyDataIfNeeded(localDatabase);
        await refreshFromCloud();
        _loadError = null;
        return;
      }
      final preferences = await _preferencesFactory();
      final raw = preferences.getString(storageKey);
      final serverIdsRaw = preferences.getString(serverIdsKey);
      final pendingDeletesRaw = preferences.getString(pendingDeletesKey);
      final serverVersionsRaw = preferences.getString(serverVersionsKey);
      _pendingUpserts.clear();
      _syncCursor = preferences.getString(syncCursorKey);
      _restorePendingUpserts(preferences.getString(pendingUpsertsKey));
      _cases.clear();
      _serverIds.clear();
      _pendingDeletes.clear();
      _serverVersions.clear();
      if (serverIdsRaw != null && serverIdsRaw.isNotEmpty) {
        final decoded = jsonDecode(serverIdsRaw);
        if (decoded is Map) {
          _serverIds.addAll(
            decoded.map((key, value) => MapEntry('$key', '$value')),
          );
        }
      }
      if (pendingDeletesRaw != null && pendingDeletesRaw.isNotEmpty) {
        final decoded = jsonDecode(pendingDeletesRaw);
        if (decoded is Map) {
          _pendingDeletes.addAll(
            decoded.map((key, value) => MapEntry('$key', '$value')),
          );
        }
      }
      _restoreVersionMap(serverVersionsRaw);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          throw const FormatException('角色数据格式无效');
        }
        for (final item in decoded) {
          if (item is! Map) continue;
          // 单条损坏时跳过，保留其余可读案例。
          final profile = CaseProfile.tryFromJson(
            Map<String, dynamic>.from(item),
          );
          if (profile != null) _cases.add(profile);
        }
        _sort();
      }
      for (final profile in _cases) {
        if (!_serverIds.containsKey(profile.id)) {
          _pendingUpserts.add(profile.id);
        }
      }
      await refreshFromCloud();
      _loadError = null;
    } catch (error) {
      _loadError = error.toString();
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _loadFromDatabase(AppDatabase database) async {
    _cases.clear();
    _serverIds.clear();
    _pendingDeletes.clear();
    _serverVersions.clear();
    _pendingUpserts.clear();
    for (final row in await database.loadCases()) {
      final decoded = jsonDecode(row.profileJson);
      if (decoded is! Map) continue;
      final profile = CaseProfile.tryFromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (profile != null) _cases.add(profile);
    }
    for (final row in await database.loadCaseSyncStates()) {
      if (row.serverId != null) _serverIds[row.localId] = row.serverId!;
      if (row.pendingDeleteServerId != null) {
        _pendingDeletes[row.localId] = row.pendingDeleteServerId!;
      }
    }
    _restoreVersionMap(await database.metadataValue(_databaseVersionsKey));
    final storedCursor = await database.metadataValue(_databaseCursorKey);
    _syncCursor = storedCursor == null || storedCursor.isEmpty
        ? null
        : storedCursor;
    _restorePendingUpserts(
      await database.metadataValue(_databasePendingUpsertsKey),
    );
    _sort();
  }

  Future<void> _migrateLegacyDataIfNeeded(AppDatabase database) async {
    const migrationKey = 'migration.shared_preferences.cases.v1';
    if (await database.metadataValue(migrationKey) == 'done') return;
    final preferences = await _preferencesFactory();
    final raw = preferences.getString(storageKey);
    final serverIdsRaw = preferences.getString(serverIdsKey);
    final pendingDeletesRaw = preferences.getString(pendingDeletesKey);
    final serverVersionsRaw = preferences.getString(serverVersionsKey);
    if (_cases.isEmpty && raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final profile = CaseProfile.tryFromJson(
            Map<String, dynamic>.from(item),
          );
          if (profile != null) _cases.add(profile);
        }
      }
    }
    void restoreMap(String? encoded, Map<String, String> target) {
      if (encoded == null || encoded.isEmpty) return;
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        target.addAll(decoded.map((key, value) => MapEntry('$key', '$value')));
      }
    }

    restoreMap(serverIdsRaw, _serverIds);
    restoreMap(pendingDeletesRaw, _pendingDeletes);
    _restoreVersionMap(serverVersionsRaw);
    _syncCursor ??= preferences.getString(syncCursorKey);
    _restorePendingUpserts(preferences.getString(pendingUpsertsKey));
    for (final profile in _cases) {
      if (!_serverIds.containsKey(profile.id)) {
        _pendingUpserts.add(profile.id);
      }
    }
    _sort();
    await _persist();
    await _persistServerIds();
    await _persistServerVersions();
    await _persistSyncCursor();
    await _persistPendingUpserts();
    await database.setMetadataValue(migrationKey, 'done');
  }

  CaseProfile? findById(String id) {
    for (final item in _cases) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// 新增案例。返回保存后的实例。
  Future<CaseProfile> add(CaseProfile profile) async {
    await ensureLoaded();
    _cases.removeWhere((item) => item.id == profile.id);
    _cases.add(profile);
    _pendingUpserts.add(profile.id);
    _sort();
    await _persist();
    await _persistPendingUpserts();
    await _sync(profile);
    return profile;
  }

  /// 更新已有案例，返回更新后的实例；不存在时原样返回输入。
  Future<CaseProfile> update(CaseProfile profile) async {
    await ensureLoaded();
    final index = _cases.indexWhere((item) => item.id == profile.id);
    if (index < 0) return profile;
    _cases[index] = profile;
    _pendingUpserts.add(profile.id);
    _sort();
    await _persist();
    await _persistPendingUpserts();
    await _sync(profile);
    return profile;
  }

  /// 删除案例。
  ///
  /// 只删除案例本身；历史记录保存的是快照，不受影响。
  Future<void> delete(String id) async {
    await ensureLoaded();
    _cases.removeWhere((item) => item.id == id);
    _pendingUpserts.remove(id);
    await _persist();
    await _persistPendingUpserts();
    final serverId = _serverIds[id];
    if (serverId != null && _cloudSync != null) {
      _pendingDeletes[id] = serverId;
      await _persistPendingDeletes();
      try {
        await _cloudSync.delete(serverId, baseVersion: _serverVersions[id]);
        _serverIds.remove(id);
        _pendingDeletes.remove(id);
        _serverVersions.remove(id);
        await _persistServerIds();
        await _persistPendingDeletes();
        await _persistServerVersions();
      } on SyncVersionConflict {
        await _acceptRemoteVersion(id);
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    await ensureLoaded();
    _cases.clear();
    await _persist();
  }

  Future<void> clearLocalData() async {
    await ensureLoaded();
    _cases.clear();
    _serverIds.clear();
    _pendingDeletes.clear();
    _serverVersions.clear();
    _pendingUpserts.clear();
    _syncCursor = null;
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.replaceCases(const []);
      await localDatabase.replaceCaseSyncStates(const []);
      await localDatabase.setMetadataValue(_databaseVersionsKey, '{}');
      await localDatabase.setMetadataValue(_databaseCursorKey, '');
      await localDatabase.setMetadataValue(_databasePendingUpsertsKey, '[]');
    }
    final preferences = await _preferencesFactory();
    await preferences.remove(storageKey);
    await preferences.remove(serverIdsKey);
    await preferences.remove(pendingDeletesKey);
    await preferences.remove(serverVersionsKey);
    await preferences.remove(syncCursorKey);
    await preferences.remove(pendingUpsertsKey);
    notifyListeners();
  }

  void _sort() => _cases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> refreshFromCloud() async {
    final cloud = _cloudSync;
    if (cloud == null) return;
    try {
      for (final entry in _pendingDeletes.entries.toList()) {
        try {
          await cloud.delete(
            entry.value,
            baseVersion: _serverVersions[entry.key],
          );
          _pendingDeletes.remove(entry.key);
          _serverIds.remove(entry.key);
          _serverVersions.remove(entry.key);
        } on SyncVersionConflict {
          await _acceptRemoteVersion(entry.key);
        }
      }
      await _persistPendingDeletes();
      await _persistServerIds();
      await _persistServerVersions();
      final batch = await cloud.fetchChanges(_syncCursor);
      var changed = false;
      for (final item in batch.items) {
        final localId = item.clientId;
        final previousVersion = _serverVersions[localId];
        _serverIds[localId] = item.serverId;
        if (item.deleted) {
          _serverVersions[localId] = item.version;
          _pendingDeletes.remove(localId);
          _pendingUpserts.remove(localId);
          final before = _cases.length;
          _cases.removeWhere((local) => local.id == localId);
          changed = changed || before != _cases.length;
          continue;
        }
        final remoteProfile = item.profile;
        if (remoteProfile == null) continue;
        if (_pendingUpserts.contains(localId) &&
            previousVersion != null &&
            item.version > previousVersion) {
          // 保留旧基础版本，让随后的上传触发 409，再统一采用云端版本。
          continue;
        }
        _serverVersions[localId] = item.version;
        final index = _cases.indexWhere((local) => local.id == localId);
        if (index < 0) {
          _cases.add(remoteProfile);
          changed = true;
        } else if (!_pendingUpserts.contains(localId) &&
            remoteProfile.updatedAt.isAfter(_cases[index].updatedAt)) {
          _cases[index] = remoteProfile;
          changed = true;
        }
      }
      _syncCursor = batch.cursor;
      for (final localId in _pendingUpserts.toList()) {
        if (_pendingDeletes.containsKey(localId)) continue;
        final local = findById(localId);
        if (local == null) {
          _pendingUpserts.remove(localId);
          continue;
        }
        try {
          final result = await cloud.upsert(
            local,
            baseVersion: _serverVersions[local.id],
          );
          _serverIds[local.id] = result.serverId;
          _serverVersions[local.id] = result.version;
          _pendingUpserts.remove(local.id);
        } on SyncVersionConflict {
          await _acceptRemoteVersion(local.id);
        }
      }
      if (changed) {
        _sort();
        await _persist();
      }
      await _persistServerIds();
      await _persistServerVersions();
      await _persistPendingUpserts();
      await _persistSyncCursor();
    } catch (_) {
      // 离线时继续使用本地案例。
    }
  }

  Future<void> _sync(CaseProfile profile) async {
    final cloud = _cloudSync;
    if (cloud == null) return;
    try {
      final result = await cloud.upsert(
        profile,
        baseVersion: _serverVersions[profile.id],
      );
      _serverIds[profile.id] = result.serverId;
      _serverVersions[profile.id] = result.version;
      _pendingUpserts.remove(profile.id);
      await _persistServerIds();
      await _persistServerVersions();
      await _persistPendingUpserts();
    } on SyncVersionConflict {
      await _acceptRemoteVersion(profile.id);
    } catch (_) {
      // 后续刷新或再次编辑时重试，不阻断本地操作。
    }
  }

  Future<void> _persistServerIds() async {
    final localDatabase = database;
    if (localDatabase != null) {
      await _persistCaseSyncStates(localDatabase);
      return;
    }
    final preferences = await _preferencesFactory();
    await preferences.setString(serverIdsKey, jsonEncode(_serverIds));
  }

  Future<void> _persistPendingDeletes() async {
    final localDatabase = database;
    if (localDatabase != null) {
      await _persistCaseSyncStates(localDatabase);
      return;
    }
    final preferences = await _preferencesFactory();
    await preferences.setString(pendingDeletesKey, jsonEncode(_pendingDeletes));
  }

  void _restoreVersionMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) return;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) return;
    for (final entry in decoded.entries) {
      if (entry.value is num) {
        _serverVersions['${entry.key}'] = (entry.value as num).toInt();
      }
    }
  }

  Future<void> _persistServerVersions() async {
    final encoded = jsonEncode(_serverVersions);
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.setMetadataValue(_databaseVersionsKey, encoded);
      return;
    }
    final preferences = await _preferencesFactory();
    await preferences.setString(serverVersionsKey, encoded);
  }

  void _restorePendingUpserts(String? encoded) {
    if (encoded == null || encoded.isEmpty) return;
    final decoded = jsonDecode(encoded);
    if (decoded is List) {
      _pendingUpserts.addAll(decoded.map((item) => '$item'));
    }
  }

  Future<void> _persistPendingUpserts() async {
    final encoded = jsonEncode(_pendingUpserts.toList());
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.setMetadataValue(_databasePendingUpsertsKey, encoded);
      return;
    }
    final preferences = await _preferencesFactory();
    await preferences.setString(pendingUpsertsKey, encoded);
  }

  Future<void> _persistSyncCursor() async {
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.setMetadataValue(
        _databaseCursorKey,
        _syncCursor ?? '',
      );
      return;
    }
    final preferences = await _preferencesFactory();
    if (_syncCursor == null) {
      await preferences.remove(syncCursorKey);
    } else {
      await preferences.setString(syncCursorKey, _syncCursor!);
    }
  }

  Future<void> _acceptRemoteVersion(String localId) async {
    final cloud = _cloudSync;
    if (cloud == null) return;
    List<CloudCase> remote;
    try {
      remote = await cloud.fetchCases();
    } catch (_) {
      _loadError = '检测到角色版本冲突，等待网络恢复后重新获取云端版本';
      notifyListeners();
      return;
    }
    CloudCase? match;
    for (final item in remote) {
      if (item.profile.id == localId) {
        match = item;
        break;
      }
    }
    if (match == null) {
      _loadError = '检测到角色版本冲突，但云端未返回对应角色';
      notifyListeners();
      return;
    }
    _pendingDeletes.remove(localId);
    _pendingUpserts.remove(localId);
    _serverIds[localId] = match.serverId;
    _serverVersions[localId] = match.version;
    _cases.removeWhere((item) => item.id == localId);
    _cases.add(match.profile);
    _sort();
    _loadError = '该角色已在其他设备更新，已保留云端最新版本';
    await _persist();
    await _persistPendingDeletes();
    await _persistServerIds();
    await _persistServerVersions();
  }

  Future<void> _persist() async {
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.replaceCases(
        _cases.map(
          (item) => LocalCasesCompanion.insert(
            id: item.id,
            profileJson: jsonEncode(item.toJson()),
            updatedAt: item.updatedAt,
          ),
        ),
      );
      notifyListeners();
      return;
    }
    final preferences = await _preferencesFactory();
    final encoded = jsonEncode(_cases.map((item) => item.toJson()).toList());
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('本地角色写入失败');
    }
    notifyListeners();
  }

  Future<void> _persistCaseSyncStates(AppDatabase database) async {
    final localIds = {..._serverIds.keys, ..._pendingDeletes.keys};
    await database.replaceCaseSyncStates(
      localIds.map(
        (id) => LocalCaseSyncStatesCompanion.insert(
          localId: id,
          serverId: Value(_serverIds[id]),
          pendingDeleteServerId: Value(_pendingDeletes[id]),
        ),
      ),
    );
  }
}
