import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/features/fortune/presentation/fortune_page.dart';

void main() {
  testWidgets('今日运势展示稳定结果并支持切换日期', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FortunePage(initialDate: DateTime(2024, 2, 10))),
      ),
    );
    await tester.pump();

    expect(find.text('今日运势'), findsOneWidget);
    expect(find.text('2024-02-10'), findsWidgets);
    expect(find.text('事业'), findsOneWidget);
    expect(find.text('财运'), findsOneWidget);
    expect(find.text('感情'), findsOneWidget);
    expect(find.text('今日适合'), findsOneWidget);
    expect(find.text('今日谨慎'), findsOneWidget);

    final next = find.byKey(const ValueKey('fortune-next-day'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pump();
    expect(find.text('2024-02-11'), findsWidgets);
  });

  testWidgets('未配置 AI 时仍可完整显示离线运势', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FortunePage(initialDate: DateTime(2024, 2, 10))),
      ),
    );

    final aiButton = find.byKey(const ValueKey('fortune-ai-reading'));
    await tester.ensureVisible(aiButton);
    expect(tester.widget<FilledButton>(aiButton).onPressed, isNull);
    expect(find.textContaining('基础运势已在本地生成'), findsOneWidget);
  });

  testWidgets('查看页面不会自动保存并支持用户主动保存', (tester) async {
    var savedCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FortunePage(
            initialDate: DateTime(2024, 2, 10),
            onResult: (_, _) async {
              savedCount++;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(savedCount, 0);

    final save = find.byKey(const ValueKey('fortune-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(savedCount, 1);
    expect(find.text('已保存'), findsOneWidget);
  });
}
