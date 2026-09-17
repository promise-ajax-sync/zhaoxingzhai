/// 全局案例选择。
///
/// 参考实现的 `caseSelection`：同一时刻有一个「当前案例」用于新计算。
/// 这里只保存案例标识，读取时才去仓储取，避免仓储刷新后持有过期对象。
library;

import 'package:flutter/foundation.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';

class CaseSelectionController extends ChangeNotifier {
  CaseSelectionController(this._repository) {
    _repository.addListener(_onRepositoryChanged);
  }

  final CaseRepository _repository;
  String? _selectedId;

  /// 当前选中的案例；未选择或案例已被删除时为 `null`。
  CaseProfile? get current {
    final id = _selectedId;
    if (id == null) return null;
    return _repository.findById(id);
  }

  /// 当前案例的快照。
  ///
  /// 每次调用都生成新的值拷贝，写入历史后即与案例解耦。
  CaseSnapshot? get currentSnapshot => current?.toSnapshot();

  String? get selectedId => _selectedId;

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void clearSelection() => select(null);

  void _onRepositoryChanged() {
    // 选中的案例被删除后，选择状态必须跟着失效，否则会拿着
    // 一个已不存在的案例继续计算。
    final id = _selectedId;
    if (id != null && _repository.findById(id) == null) {
      _selectedId = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
