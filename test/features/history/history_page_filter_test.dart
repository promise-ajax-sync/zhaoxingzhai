import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/presentation/history_page.dart';

void main() {
  testWidgets('历史记录支持按关键词搜索', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = DivinationHistoryRepository();
    addTearDown(repository.dispose);
    await repository.add(
      DivinationHistoryRecord(
        id: 'history-a',
        type: 'tarot',
        title: '工作方向',
        summary: '适合先完成当前任务',
        createdAt: DateTime(2026, 1, 1),
        payload: const {},
        algorithmId: 'tarot',
        algorithmVersion: 1,
        schemaVersion: '1.0.0',
      ),
    );
    await repository.add(
      DivinationHistoryRecord(
        id: 'history-b',
        type: 'today-fortune',
        title: '今日状态',
        summary: '留意沟通节奏',
        createdAt: DateTime(2026, 1, 2),
        payload: const {},
        algorithmId: 'today-fortune',
        algorithmVersion: 1,
        schemaVersion: '1.0.0',
        caseSnapshot: CaseSnapshot(
          caseId: 'role-a',
          name: '小明',
          gender: CaseGender.unspecified,
          calendarType: CaseCalendarType.solar,
          birthDateTime: DateTime(2000, 1, 1),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HistoryPage(repository: repository)),
      ),
    );
    await tester.pump();

    expect(find.text('工作方向'), findsOneWidget);
    expect(find.text('今日状态'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('history-search')), '小明');
    await tester.pump();

    expect(find.text('今日状态'), findsOneWidget);
    expect(find.text('工作方向'), findsNothing);
  });
}
