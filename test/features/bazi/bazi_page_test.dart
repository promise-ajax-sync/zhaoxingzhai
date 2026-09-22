import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/engine/bazi/bazi_divination.dart';
import 'package:zhaoxingzhai/core/models/case_profile.dart';
import 'package:zhaoxingzhai/features/bazi/presentation/bazi_page.dart';

CaseSnapshot _case() => CaseSnapshot(
  caseId: 'bazi-page',
  name: '测试角色',
  gender: CaseGender.male,
  calendarType: CaseCalendarType.solar,
  birthDateTime: DateTime(1990, 5, 17, 14, 30),
);

void main() {
  testWidgets('未选择角色时显示引导', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BaziPage(currentCase: _empty)),
      ),
    );
    expect(find.textContaining('请先'), findsOneWidget);
  });

  testWidgets('八字页面展示四柱并支持保存', (tester) async {
    BaziResult? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BaziPage(
            currentCase: _case,
            onResult: (result) async => saved = result,
          ),
        ),
      ),
    );
    expect(find.textContaining('四柱八字'), findsOneWidget);
    expect(find.text('年柱'), findsOneWidget);
    expect(find.text('月柱'), findsOneWidget);
    expect(find.text('日柱'), findsOneWidget);
    expect(find.text('时柱'), findsOneWidget);
    final save = find.text('保存八字记录');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(saved, isNotNull);
    expect(saved!.pillars, hasLength(4));
  });
}

CaseSnapshot? _empty() => null;
