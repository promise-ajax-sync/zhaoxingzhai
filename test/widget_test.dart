import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhaoxingzhai/app/app_sidebar.dart';
import 'package:zhaoxingzhai/core/data/ssgw_data.dart';
import 'package:zhaoxingzhai/core/data/tarot_data.dart';
import 'package:zhaoxingzhai/core/data/hexagram_data.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/features/cases/presentation/cases_page.dart';
import 'package:zhaoxingzhai/features/daily_hexagram/presentation/daily_hexagram_page.dart';
import 'package:zhaoxingzhai/features/home/presentation/home_page.dart';
import 'package:zhaoxingzhai/features/meihua/presentation/meihua_page.dart';
import 'package:zhaoxingzhai/features/oracle/presentation/oracle_page.dart';
import 'package:zhaoxingzhai/features/tarot/presentation/tarot_page.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/xiaoliuren_page.dart';
import 'package:zhaoxingzhai/main.dart';

/// 宽于 [AppTheme.sidebarBreakpoint]，侧栏常驻。
const _wideSize = Size(1280, 900);

/// 窄于断点，侧栏收进抽屉。
const _narrowSize = Size(800, 1200);

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
  // AppShell 会保留已访问页面状态，测试启动只需要完成首屏布局。
  // 不在这里等待全局“完全 settle”，避免未来某个常驻动画或异步页面
  // 让所有与该页面无关的外壳测试一起超时。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 100,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('等待组件超时：$finder');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首页展示今日运势与对话输入区', (WidgetTester tester) async {
    await _pumpApp(tester, _wideSize);

    expect(find.byType(HomePage), findsOneWidget);
    // 「今日运势」同时出现在侧栏入口与首页运势条上。
    expect(find.text('今日运势'), findsNWidgets(2));
    expect(find.text('探索未来'), findsOneWidget);
    expect(find.text('解读术数'), findsOneWidget);
    expect(find.text('功德箱'), findsOneWidget);
    expect(find.textContaining('写下问题，交给'), findsOneWidget);
  });

  testWidgets('首页根据地点问题推荐梅花易数', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomePage(onOpenFeature: (_) {})),
      ),
    );

    await tester.enterText(find.byType(TextField), '我会在哪里找到对象');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    expect(find.text('推荐：梅花易数'), findsOneWidget);
    expect(find.textContaining('地点、方位或时间线索'), findsOneWidget);
    expect(find.text('进入梅花易数'), findsOneWidget);
  });

  testWidgets('首页路由问题可以自动带入梅花易数', (WidgetTester tester) async {
    final draft = ValueNotifier<RoutedDivinationDraft?>(
      RoutedDivinationDraft(question: '我会在哪里找到对象', tool: DivinationTool.meihua),
    );
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MeihuaPage(routedDraft: draft)),
      ),
    );
    await _pumpUntilFound(tester, find.text('占问背景（可选）'));

    expect(find.text('我会在哪里找到对象'), findsOneWidget);
    expect(find.text('感情关系'), findsOneWidget);
  });

  testWidgets('首页路由问题可以自动带入塔罗', (WidgetTester tester) async {
    final draft = ValueNotifier<RoutedDivinationDraft?>(
      RoutedDivinationDraft(question: '对方内心怎么想', tool: DivinationTool.tarot),
    );
    addTearDown(draft.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TarotPage(routedDraft: draft)),
      ),
    );
    await _pumpUntilFound(tester, find.text('占问主题'));

    expect(find.text('对方内心怎么想'), findsOneWidget);
    expect(find.textContaining('当前分类：感情关系'), findsOneWidget);
  });

  testWidgets('宽屏下侧栏常驻并可进入小六壬', (WidgetTester tester) async {
    await _pumpApp(tester, _wideSize);

    expect(find.byType(AppSidebar), findsOneWidget);
    // 宽屏侧栏常驻，不再显示抽屉开关。
    expect(find.byTooltip('打开导航'), findsNothing);

    await tester.tap(find.text('小六壬'));
    await tester.pumpAndSettle();

    expect(find.byType(XiaoliurenPage), findsOneWidget);
    expect(find.text('小六壬时间起课'), findsOneWidget);
    expect(find.text('点击选择日期和时辰'), findsOneWidget);
    expect(find.text('起课规则'), findsOneWidget);
    expect(find.text('通行掌诀'), findsOneWidget);
    expect(find.text('多能鄙事'), findsOneWidget);
    expect(find.text('开始占卜'), findsOneWidget);
  });

  testWidgets('窄屏下侧栏收入抽屉并可切换视图', (WidgetTester tester) async {
    await _pumpApp(tester, _narrowSize);

    // 抽屉未展开时侧栏不在树上。
    expect(find.byType(AppSidebar), findsNothing);

    await tester.tap(find.byTooltip('打开导航'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSidebar), findsOneWidget);

    await tester.tap(find.text('小六壬'));
    await tester.pumpAndSettle();

    expect(find.byType(XiaoliurenPage), findsOneWidget);
    // 选中后抽屉自动收起。
    expect(find.byType(AppSidebar), findsNothing);
  });

  testWidgets('未选时间时占卜按钮为禁用态，不进入计算态', (WidgetTester tester) async {
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('小六壬'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始占卜'),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.text('开始占卜'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('请先选择日期和时辰'), findsNothing);
  });

  testWidgets('侧栏可以进入西方占卜并加载完整牌阵', (WidgetTester tester) async {
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('西方占卜'));
    await tester.pumpAndSettle();

    expect(find.byType(TarotPage), findsOneWidget);
    expect(find.text('选择牌阵'), findsWidgets);
    expect(find.text('单牌指引'), findsWidgets);
    expect(find.text('爱情牌阵'), findsOneWidget);
    expect(find.text('十二宫牌阵'), findsOneWidget);
  });

  testWidgets('侧栏可以进入灵签并按签号查询', (WidgetTester tester) async {
    // rootBundle 的异步资源加载不依赖 widget 测试的假时钟推进；先完成
    // 数据预热，再验证页面挂载和交互，避免对加载动画使用 pumpAndSettle。
    await tester.runAsync(SsgwData.load);
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('灵签'));
    await _pumpUntilFound(tester, find.text('随机抽签'));

    expect(find.byType(OraclePage), findsOneWidget);
    expect(find.text('随机抽签'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('ssgw-sign-number-input')),
      '1',
    );
    await tester.tap(find.text('查询签文'));
    await _pumpUntilFound(tester, find.text('第1签'));

    expect(find.text('第1签'), findsOneWidget);
    expect(find.textContaining('第一签'), findsWidgets);
  });

  testWidgets('侧栏可以进入每日一卦并显示本卦变卦互卦', (WidgetTester tester) async {
    await tester.runAsync(HexagramData.load);
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('每日一卦'));
    await _pumpUntilFound(tester, find.byType(DailyHexagramPage));
    await _pumpUntilFound(tester, find.text('六爻记录'));
    await _pumpUntilFound(tester, find.textContaining('本卦 ·'));

    expect(find.byType(DailyHexagramPage), findsOneWidget);
    expect(find.textContaining('通用日卦'), findsOneWidget);
    expect(find.textContaining('本卦 ·'), findsOneWidget);
    expect(find.text('变卦'), findsOneWidget);
    expect(find.text('互卦'), findsOneWidget);
    expect(find.text('手动录入'), findsOneWidget);
    expect(find.text('分项解读'), findsOneWidget);
    expect(find.text('传统概览'), findsOneWidget);
    expect(find.text('风险提醒'), findsOneWidget);
  });

  testWidgets('侧栏可以进入梅花易数并完成数字起卦', (WidgetTester tester) async {
    await tester.runAsync(HexagramData.load);
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('梅花易数').first);
    await _pumpUntilFound(tester, find.byType(MeihuaPage));
    await _pumpUntilFound(tester, find.text('开始起卦'));

    expect(find.text('时间'), findsOneWidget);
    expect(find.text('数字'), findsOneWidget);
    expect(find.text('随机'), findsOneWidget);
    await tester.tap(find.text('数字'));
    await tester.pump();
    await tester.tap(find.text('开始起卦'));
    await _pumpUntilFound(tester, find.text('动爻与体用'));

    expect(find.byType(MeihuaPage), findsOneWidget);
    expect(find.text('火地晋'), findsOneWidget);
    expect(find.text('水山蹇'), findsOneWidget);
    expect(find.text('火水未济'), findsOneWidget);
    expect(find.textContaining('体用关系：体生用'), findsOneWidget);
    expect(find.text('现代白话解读'), findsOneWidget);
    expect(find.text('行动建议'), findsOneWidget);
    expect(find.text('风险提醒'), findsOneWidget);
  });

  testWidgets('每日一卦支持逐枚铜钱录入并播放成卦动画', (WidgetTester tester) async {
    await tester.runAsync(HexagramData.load);
    await _pumpApp(tester, _wideSize);
    await tester.tap(find.text('每日一卦'));
    await _pumpUntilFound(tester, find.byType(DailyHexagramPage));
    await _pumpUntilFound(tester, find.text('六爻记录'));

    await tester.tap(find.text('手动录入'));
    await tester.pump();
    expect(find.byKey(const ValueKey('daily-coin-0-0')), findsOneWidget);
    expect(find.text('3+2+2=7 · 少阳'), findsNWidgets(6));

    await tester.tap(find.byKey(const ValueKey('daily-coin-0-0')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('2+2+2=6 · 老阴'), findsOneWidget);

    await tester.tap(find.text('完成六爻并生成卦象'));
    await tester.pump();
    expect(find.textContaining('正在形成卦象'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('本卦 ·'), findsOneWidget);
  });

  testWidgets('塔罗支持切换到手动录牌并校验完整输入', (WidgetTester tester) async {
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('西方占卜'));
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

    // 案例页与历史是两个独立入口：案例页只管理占卜主体，不展示结果。
    await tester.tap(find.text('角色'));
    await tester.pumpAndSettle();

    expect(find.byType(CasesPage), findsOneWidget);
    expect(find.text('还没有角色'), findsOneWidget);

    // 历史记录作为独立抽屉打开。
    await tester.tap(find.byTooltip('记录'));
    await tester.pumpAndSettle();

    expect(find.text('历史记录'), findsWidgets);
    expect(find.textContaining(firstCard.name), findsWidgets);
  });

  testWidgets('可以新建案例并自动选中', (WidgetTester tester) async {
    await _pumpApp(tester, _wideSize);

    await tester.tap(find.text('角色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新建角色'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '测试案例');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 案例出现在列表里，并被自动选为当前案例。
    expect(find.text('测试案例'), findsWidgets);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    // 未填名称时不允许保存。
    await tester.tap(find.text('新建角色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('请填写角色名称'), findsOneWidget);
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
