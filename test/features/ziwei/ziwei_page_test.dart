import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/ziwei/ziwei_chart.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/ziwei/presentation/ziwei_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('未选择角色时提示先选择角色', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ZiweiPage(currentCase: () => null)),
      ),
    );
    expect(find.textContaining('请先在角色页面选择'), findsOneWidget);
  });

  testWidgets('紫微页面展示十二宫、四化与大限并可保存', (tester) async {
    ZiweiChartResult? saved;
    final subject = CaseSnapshot(
      caseId: 'ziwei-page',
      name: '页面角色',
      gender: CaseGender.male,
      calendarType: CaseCalendarType.lunar,
      birthDateTime: DateTime(2024, 1, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZiweiPage(
            currentCase: () => subject,
            onResult: (result) async => saved = result,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('紫微斗数'), findsOneWidget);
    expect(find.textContaining('命宫 ·'), findsWidgets);
    expect(find.textContaining('火六局'), findsWidgets);
    expect(find.textContaining('化禄'), findsWidgets);
    expect(find.textContaining('三方'), findsWidgets);
    expect(find.textContaining('对宫'), findsWidgets);
    expect(find.textContaining('化禄入'), findsWidgets);
    expect(find.text('大限'), findsWidgets);
    expect(find.text('流年'), findsWidgets);
    expect(find.textContaining('农历年'), findsWidgets);
    expect(find.textContaining('流年四化'), findsOneWidget);
    expect(find.textContaining('虚岁'), findsWidgets);
    expect(
      find.byKey(const ValueKey('ziwei-fixed-palace-chart')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ziwei-layer-natal')), findsOneWidget);
    expect(find.byKey(const ValueKey('ziwei-layer-decade')), findsOneWidget);
    expect(find.byKey(const ValueKey('ziwei-layer-annual')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ziwei-layer-description')),
      findsOneWidget,
    );
    for (final branch in const [
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
      '子',
      '丑',
    ]) {
      expect(find.byKey(ValueKey('ziwei-palace-$branch')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('ziwei-layer-annual')));
    await tester.pump();
    expect(find.textContaining('流年命宫'), findsWidgets);
    expect(find.textContaining('太岁命宫'), findsWidgets);
    await tester.ensureVisible(find.text('保存紫微记录'));
    await tester.tap(find.text('保存紫微记录'));
    await tester.pump();
    expect(saved, isNotNull);
    expect(saved!.palaces, hasLength(12));
  });
}
