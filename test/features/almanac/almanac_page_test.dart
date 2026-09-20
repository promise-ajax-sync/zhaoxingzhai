import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/features/almanac/presentation/almanac_page.dart';

void main() {
  testWidgets('黄历页面展示日期宜忌并支持切换前后日期', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AlmanacPage(initialDate: DateTime(2024, 2, 10))),
      ),
    );

    expect(find.text('2024年2月10日'), findsOneWidget);
    expect(find.text('2024年2月'), findsOneWidget);
    expect(find.textContaining('农历正月初一'), findsOneWidget);
    expect(find.text('宜'), findsOneWidget);
    expect(find.text('忌'), findsOneWidget);
    expect(find.text('春节'), findsWidgets);

    final nextDay = find.byKey(const ValueKey('almanac-next-day'));
    await tester.ensureVisible(nextDay);
    await tester.tap(nextDay);
    await tester.pump();
    expect(find.text('2024年2月11日'), findsOneWidget);

    final previousDay = find.byKey(const ValueKey('almanac-previous-day'));
    await tester.ensureVisible(previousDay);
    await tester.tap(previousDay);
    await tester.pump();
    expect(find.text('2024年2月10日'), findsOneWidget);
  });

  testWidgets('黄历详情展示日课补充信息并可展开十二时辰', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AlmanacPage(initialDate: DateTime(2024, 2, 10))),
      ),
    );

    expect(find.text('日纳音'), findsOneWidget);
    expect(find.text('胎神方位'), findsOneWidget);

    final section = find.text('十二时辰');
    await tester.ensureVisible(section);
    await tester.tap(section);
    await tester.pumpAndSettle();

    final firstPeriod = find.byKey(const ValueKey('almanac-time-0-子时'));
    await tester.ensureVisible(firstPeriod);
    await tester.tap(firstPeriod);
    await tester.pumpAndSettle();
    expect(find.text('时宜'), findsOneWidget);
    expect(find.text('时忌'), findsOneWidget);
  });

  testWidgets('月份日历支持切换月份并点击日期联动详情', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AlmanacPage(initialDate: DateTime(2024, 2, 10))),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('almanac-next-month')));
    await tester.pump();
    expect(find.text('2024年3月'), findsOneWidget);
    expect(find.text('2024年3月10日'), findsOneWidget);

    final march20 = find.byKey(const ValueKey('almanac-date-2024-3-20'));
    await tester.ensureVisible(march20);
    await tester.tap(march20);
    await tester.pump();
    expect(find.text('2024年3月20日'), findsOneWidget);
    expect(find.text('今日节气：春分'), findsOneWidget);
  });

  testWidgets('传统择日可以按当前日期和事项生成参考结果', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AlmanacPage(initialDate: DateTime(2024, 1, 1))),
      ),
    );

    final selectionSection = find.text('传统择日');
    await tester.ensureVisible(selectionSection);
    await tester.tap(selectionSection);
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('almanac-selection-search'));
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pumpAndSettle();

    expect(find.textContaining('传统择日参考'), findsOneWidget);
    expect(find.textContaining('个参考日期'), findsOneWidget);
  });
}
