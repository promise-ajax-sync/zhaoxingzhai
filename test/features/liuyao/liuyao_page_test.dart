import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/engine/liuyao/liuyao_divination.dart';
import 'package:zhaoxingzhai/features/liuyao/presentation/liuyao_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(HexagramData.load);

  testWidgets('手动六爻排盘展示纳甲世应与关联卦', (tester) async {
    LiuyaoResult? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiuyaoPage(
            onResult: (result) async {
              saved = result;
            },
          ),
        ),
      ),
    );

    final submit = find.text('按录入值排盘');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(find.textContaining('乾为天'), findsWidgets);
    expect(find.textContaining('世'), findsWidgets);
    expect(find.text('互卦：乾为天 · 错卦：坤为地 · 综卦：乾为天'), findsOneWidget);
    expect(find.byKey(const ValueKey('liuyao-ai-reading')), findsOneWidget);
  });
}
