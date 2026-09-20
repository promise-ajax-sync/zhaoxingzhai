import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';
import 'package:zhaoxingzhai/features/compatibility/presentation/compatibility_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('案例不足时引导用户先创建案例', (tester) async {
    final repository = CaseRepository();
    addTearDown(repository.dispose);
    await repository.ensureLoaded();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CompatibilityPage(repository: repository)),
      ),
    );
    await tester.pump();

    expect(find.text('至少需要两个角色'), findsOneWidget);
    expect(find.text('前往角色页'), findsOneWidget);
  });

  testWidgets('两个不同案例可以生成完整合盘结果', (tester) async {
    final repository = CaseRepository();
    addTearDown(repository.dispose);
    await repository.add(
      CaseProfile.create(
        name: '甲方',
        birthDateTime: DateTime(1992, 4, 12, 10),
        now: DateTime(2024, 1, 1),
      ),
    );
    await repository.add(
      CaseProfile.create(
        name: '乙方',
        birthDateTime: DateTime(1990, 9, 8, 9),
        now: DateTime(2024, 1, 2),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CompatibilityPage(repository: repository)),
      ),
    );
    await tester.pump();

    final calculate = find.byKey(const ValueKey('compatibility-calculate'));
    await tester.ensureVisible(calculate);
    await tester.tap(calculate);
    await tester.pump();

    expect(find.textContaining('乙方与甲方'), findsOneWidget);
    expect(find.text('相处优势'), findsOneWidget);
    expect(find.text('磨合重点'), findsOneWidget);
    expect(find.text('现实建议'), findsOneWidget);
  });
}
