import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/cases/case_selection.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('案例可以新增、持久化与重新读取', () async {
    final repository = CaseRepository();
    final profile = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1, 8, 30),
      now: DateTime(2026, 1, 1),
    );

    await repository.add(profile);

    final reloaded = CaseRepository();
    await reloaded.ensureLoaded();

    expect(reloaded.cases, hasLength(1));
    expect(reloaded.cases.single.name, '张三');
    expect(reloaded.findById(profile.id), isNotNull);

    repository.dispose();
    reloaded.dispose();
  });

  test('更新案例会替换同名标识的记录而不是新增', () async {
    final repository = CaseRepository();
    final profile = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1, 8, 30),
      now: DateTime(2026, 1, 1),
    );
    await repository.add(profile);

    await repository.update(
      profile.copyWith(name: '张三改名', updatedAt: DateTime(2026, 2, 1)),
    );

    expect(repository.cases, hasLength(1));
    expect(repository.cases.single.name, '张三改名');
    expect(repository.cases.single.id, profile.id);

    repository.dispose();
  });

  test('删除案例后无法再查到', () async {
    final repository = CaseRepository();
    final profile = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1),
      now: DateTime(2026, 1, 1),
    );
    await repository.add(profile);
    await repository.delete(profile.id);

    expect(repository.cases, isEmpty);
    expect(repository.findById(profile.id), isNull);

    repository.dispose();
  });

  test('单条案例损坏时跳过并保留其余数据', () async {
    SharedPreferences.setMockInitialValues({
      CaseRepository.storageKey: jsonEncode([
        {
          'name': '正常案例',
          'birthDateTime': DateTime(1990, 5, 1).toIso8601String(),
        },
        {'name': '', 'birthDateTime': 'x'},
        {'missing': 'both'},
      ]),
    });

    final repository = CaseRepository();
    await repository.ensureLoaded();

    expect(repository.cases, hasLength(1));
    expect(repository.cases.single.name, '正常案例');

    repository.dispose();
  });

  test('案例按更新时间倒序排列', () async {
    final repository = CaseRepository();
    await repository.add(
      CaseProfile.create(
        name: '较早',
        birthDateTime: DateTime(1990),
        now: DateTime(2026, 1, 1),
      ),
    );
    await repository.add(
      CaseProfile.create(
        name: '较晚',
        birthDateTime: DateTime(1991),
        now: DateTime(2026, 3, 1),
      ),
    );

    expect(repository.cases.first.name, '较晚');

    repository.dispose();
  });

  test('选中的案例被删除后选择状态自动失效', () async {
    final repository = CaseRepository();
    final selection = CaseSelectionController(repository);
    final profile = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1),
      now: DateTime(2026, 1, 1),
    );
    await repository.add(profile);

    selection.select(profile.id);
    expect(selection.current?.name, '张三');
    expect(selection.currentSnapshot?.name, '张三');

    await repository.delete(profile.id);

    expect(selection.current, isNull);
    expect(selection.currentSnapshot, isNull);

    selection.dispose();
    repository.dispose();
  });

  test('取消选择后不再有当前案例', () async {
    final repository = CaseRepository();
    final selection = CaseSelectionController(repository);
    final profile = CaseProfile.create(
      name: '张三',
      birthDateTime: DateTime(1990, 5, 1),
      now: DateTime(2026, 1, 1),
    );
    await repository.add(profile);

    selection.select(profile.id);
    expect(selection.current, isNotNull);

    selection.clearSelection();
    expect(selection.current, isNull);

    selection.dispose();
    repository.dispose();
  });

  test('账号注销会清除案例和云同步映射', () async {
    SharedPreferences.setMockInitialValues({
      CaseRepository.storageKey: jsonEncode([]),
      CaseRepository.serverIdsKey: jsonEncode({'local': 'server'}),
      CaseRepository.pendingDeletesKey: jsonEncode({'old': 'deleted'}),
    });
    final repository = CaseRepository();

    await repository.clearLocalData();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(CaseRepository.storageKey), isFalse);
    expect(preferences.containsKey(CaseRepository.serverIdsKey), isFalse);
    expect(preferences.containsKey(CaseRepository.pendingDeletesKey), isFalse);
    repository.dispose();
  });
}
