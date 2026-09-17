/// 案例仓储：当前设备上的案例增删查改。
///
/// 与历史记录一样暂用 SharedPreferences 持久化，后续随历史记录一起
/// 迁移到结构化数据库（见 docs/SYDF_ANALYSIS_AND_REUSE.md 的 Flutter 存储决策）。
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';

class CaseRepository extends ChangeNotifier {
  CaseRepository({Future<SharedPreferences> Function()? preferencesFactory})
    : _preferencesFactory = preferencesFactory ?? SharedPreferences.getInstance;

  static const String storageKey = 'zhaoxingzhai.cases.v1';

  final Future<SharedPreferences> Function() _preferencesFactory;
  final List<CaseProfile> _cases = [];
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  String? _loadError;

  List<CaseProfile> get cases => List.unmodifiable(_cases);
  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final preferences = await _preferencesFactory();
      final raw = preferences.getString(storageKey);
      _cases.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          throw const FormatException('案例数据格式无效');
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
      _loadError = null;
    } catch (error) {
      _loadError = error.toString();
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
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
    return profile;
  }

  /// 删除案例。
  ///
  /// 只删除案例本身；历史记录保存的是快照，不受影响。
  Future<void> delete(String id) async {
    await ensureLoaded();
    _cases.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> clear() async {
    await ensureLoaded();
    _cases.clear();
    await _persist();
  }

  void _sort() => _cases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> _persist() async {
    final preferences = await _preferencesFactory();
    final encoded = jsonEncode(_cases.map((item) => item.toJson()).toList());
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) {
      throw StateError('本地案例写入失败');
    }
    notifyListeners();
  }
}
