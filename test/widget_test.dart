import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/features/home/presentation/home_page.dart';
import 'package:zhaoxingzhai/features/tarot/presentation/tarot_page.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/xiaoliuren_page.dart';
import 'package:zhaoxingzhai/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页展示已接入功能并可以进入小六壬', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('东方术数与占卜工具'), findsOneWidget);
    expect(find.text('小六壬时间起课'), findsOneWidget);
    expect(find.text('塔罗占卜'), findsOneWidget);

    await tester.tap(find.text('小六壬').last);
    await tester.pumpAndSettle();

    expect(find.byType(XiaoliurenPage), findsOneWidget);
    expect(find.text('小六壬时间起课'), findsOneWidget);
    expect(find.text('点击选择日期和时辰'), findsOneWidget);
    expect(find.text('起课规则'), findsOneWidget);
    expect(find.text('通行掌诀'), findsOneWidget);
    expect(find.text('多能鄙事'), findsOneWidget);
    expect(find.text('开始占卜'), findsOneWidget);
  });

  testWidgets('未选时间时占卜按钮为禁用态，不进入计算态', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('小六壬').last);
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始占卜'),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.text('开始占卜'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('请先选择日期和时辰'), findsNothing);
  });

  testWidgets('底部导航可以进入塔罗并加载完整牌阵', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('塔罗').last);
    await tester.pumpAndSettle();

    expect(find.byType(TarotPage), findsOneWidget);
    expect(find.text('选择牌阵'), findsWidgets);
    expect(find.text('单牌指引'), findsWidgets);
    expect(find.text('爱情牌阵'), findsOneWidget);
    expect(find.text('十二宫牌阵'), findsOneWidget);
  });

  testWidgets('塔罗支持切换到手动录牌并校验完整输入', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('塔罗').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('手动录牌'));
    await tester.pumpAndSettle();

    expect(find.text('录入实体牌面'), findsOneWidget);
    expect(find.text('1. 当前指引'), findsOneWidget);
    expect(find.text('生成手动牌阵'), findsOneWidget);

    await tester.ensureVisible(find.text('生成手动牌阵'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成手动牌阵'));
    await tester.pump();

    expect(find.text('请先录入全部 1 张牌'), findsOneWidget);

    final firstCard = TarotData.cards.first;
    final firstCardLabel =
        '${firstCard.number.toString().padLeft(2, '0')} · ${firstCard.name}';
    await tester.tap(find.byKey(const ValueKey('manual-card-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstCardLabel).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('生成手动牌阵'));
    await tester.tap(find.text('生成手动牌阵'));
    await tester.pumpAndSettle();

    expect(find.text(firstCard.name), findsWidgets);
    expect(find.text('正位'), findsOneWidget);
    expect(find.text('牌阵状态'), findsOneWidget);

    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();

    expect(find.text('历史记录'), findsWidgets);
    expect(find.text('单牌指引'), findsOneWidget);
    expect(find.textContaining(firstCard.name), findsOneWidget);
  });

  testWidgets('塔罗数据加载失败后可以重试', (WidgetTester tester) async {
    var attempts = 0;

    Future<void> loadData() async {
      attempts++;
      if (attempts == 1) {
        throw StateError('测试加载失败');
      }
      await TarotData.load();
    }

    await tester.pumpWidget(MaterialApp(home: TarotPage(loadData: loadData)));
    await tester.pumpAndSettle();

    expect(find.text('塔罗数据加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('retry-tarot-load')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('自动抽牌'), findsOneWidget);
    expect(find.text('塔罗数据加载失败'), findsNothing);
  });
}
