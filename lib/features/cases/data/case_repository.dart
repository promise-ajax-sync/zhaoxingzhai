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

  final Future<SharedPreferences> Function() _preferencesFactory;
  final CaseCloudSync? _cloudSync;
  final AppDatabase? database;
  final List<CaseProfile> _cases = [];
  final Map<String, String> _serverIds = {};
  final Map<String, String> _pendingDeletes = {};
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
      _cases.clear();
      _serverIds.clear();
      _pendingDeletes.clear();
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
    _sort();
  }

  Future<void> _migrateLegacyDataIfNeeded(AppDatabase database) async {
    const migrationKey = 'migration.shared_preferences.cases.v1';
    if (await database.metadataValue(migrationKey) == 'done') return;
    final preferences = await _preferencesFactory();
    final raw = preferences.getString(storageKey);
    final serverIdsRaw = preferences.getString(serverIdsKey);
    final pendingDeletesRaw = preferences.getString(pendingDeletesKey);
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
    _sort();
    await _persist();
    await _persistServerIds();
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
    _sort();
    await _persist();
    await _sync(profile);
    return profile;
  }

  /// 更新已有案例，返回更新后的实例；不存在时原样返回输入。
  Future<CaseProfile> update(CaseProfile profile) async {
    await ensureLoaded();
    final index = _cases.indexWhere((item) => item.id == profile.id);
    if (index < 0) return profile;
    _cases[index] = profile;
    _sort();
    await _persist();
    await _sync(profile);
    return profile;
  }

  /// 删除案例。
  ///
  /// 只删除案例本身；历史记录保存的是快照，不受影响。
  Future<void> delete(String id) async {
    await ensureLoaded();
    _cases.removeWhere((item) => item.id == id);
    await _persist();
    final serverId = _serverIds[id];
    if (serverId != null && _cloudSync != null) {
      _pendingDeletes[id] = serverId;
      await _persistPendingDeletes();
      try {
        await _cloudSync.delete(serverId);
        _serverIds.remove(id);
        _pendingDeletes.remove(id);
        await _persistServerIds();
        await _persistPendingDeletes();
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
    final localDatabase = database;
    if (localDatabase != null) {
      await localDatabase.replaceCases(const []);
      await localDatabase.replaceCaseSyncStates(const []);
    }
    final preferences = await _preferencesFactory();
    await preferences.remove(storageKey);
    await preferences.remove(serverIdsKey);
    await preferences.remove(pendingDeletesKey);
    notifyListeners();
  }

  void _sort() => _cases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> refreshFromCloud() async {
    final cloud = _cloudSync;
    if (cloud == null) return;
    try {
      for (final entry in _pendingDeletes.entries.toList()) {
        await cloud.delete(entry.value);
        _pendingDeletes.remove(entry.key);
        _serverIds.remove(entry.key);
      }
      await _persistPendingDeletes();
      await _persistServerIds();
      final remote = await cloud.fetchCases();
      var changed = false;
      for (final item in remote) {
        _serverIds[item.profile.id] = item.serverId;
        final index = _cases.indexWhere((local) => local.id == item.profile.id);
        if (index < 0) {
          _cases.add(item.profile);
          changed = true;
        } else if (item.profile.updatedAt.isAfter(_cases[index].updatedAt)) {
          _cases[index] = item.profile;
          changed = true;
        }
      }
      final remoteIds = remote.map((item) => item.profile.id).toSet();
      for (final local in _cases) {
        if (_pendingDeletes.containsKey(local.id)) continue;
        CloudCase? remoteItem;
        for (final item in remote) {
          if (item.profile.id == local.id) {
            remoteItem = item;
            break;
          }
        }
        if (!remoteIds.contains(local.id) ||
            (remoteItem != null &&
                local.updatedAt.isAfter(remoteItem.profile.updatedAt))) {
          _serverIds[local.id] = await cloud.upsert(local);
        }
      }
      if (changed) {
        _sort();
        await _persist();
      }
      await _persistServerIds();
    } catch (_) {
      // 离线时继续使用本地案例。
    }
  }

  Future<void> _sync(CaseProfile profile) async {
    final cloud = _cloudSync;
    if (cloud == null) return;
    try {
      _serverIds[profile.id] = await cloud.upsert(profile);
      await _persistServerIds();
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
