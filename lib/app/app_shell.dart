import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:zhaoxingzhai/app/app_sidebar.dart';
import 'package:zhaoxingzhai/app/app_topbar.dart';
import 'package:zhaoxingzhai/app/app_view.dart';
import 'package:zhaoxingzhai/app/placeholder_page.dart';
import 'package:zhaoxingzhai/core/ai/ai_service_factory.dart';
import 'package:zhaoxingzhai/core/auth/auth_session.dart';
import 'package:zhaoxingzhai/core/database/app_database.dart';
import 'package:zhaoxingzhai/core/models/answer_preference.dart';
import 'package:zhaoxingzhai/core/routing/divination_tool_router.dart';
import 'package:zhaoxingzhai/core/theme/app_theme.dart';
import 'package:zhaoxingzhai/features/cases/case_selection.dart';
import 'package:zhaoxingzhai/features/cases/data/case_repository.dart';
import 'package:zhaoxingzhai/features/cases/data/case_cloud_sync.dart';
import 'package:zhaoxingzhai/features/cases/presentation/cases_page.dart';
import 'package:zhaoxingzhai/features/compatibility/presentation/compatibility_page.dart';
import 'package:zhaoxingzhai/features/almanac/presentation/almanac_page.dart';
import 'package:zhaoxingzhai/features/daily_hexagram/presentation/daily_hexagram_page.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/data/history_cloud_sync.dart';
import 'package:zhaoxingzhai/features/history/presentation/history_page.dart';
import 'package:zhaoxingzhai/features/home/presentation/home_page.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_repository.dart';
import 'package:zhaoxingzhai/features/home/data/home_conversation_cloud_sync.dart';
import 'package:zhaoxingzhai/features/fortune/domain/today_fortune.dart';
import 'package:zhaoxingzhai/features/fortune/presentation/fortune_page.dart';
import 'package:zhaoxingzhai/features/meihua/presentation/meihua_page.dart';
import 'package:zhaoxingzhai/features/liuyao/presentation/liuyao_page.dart';
import 'package:zhaoxingzhai/features/bazi/presentation/bazi_page.dart';
import 'package:zhaoxingzhai/features/ziwei/presentation/ziwei_page.dart';
import 'package:zhaoxingzhai/features/oracle/presentation/oracle_page.dart';
import 'package:zhaoxingzhai/features/settings/presentation/settings_page.dart';
import 'package:zhaoxingzhai/features/tarot/presentation/tarot_page.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/xiaoliuren_page.dart';

/// 应用外壳。
///
/// 宽屏：固定侧栏 + 顶栏 + 内容区；窄屏：侧栏收进抽屉，顶栏常驻。
/// 页面用 [IndexedStack] 承载，切换入口不丢失各页状态。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppView _view = AppView.tools;
  final Set<AppView> _visitedViews = {AppView.tools};
  AnswerPreference _preference = AnswerPreference.chat;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<RoutedDivinationDraft?> _routedDraft = ValueNotifier(
    null,
  );

  late final DivinationHistoryRepository _historyRepository;
  late final http.Client _historySyncClient;
  late final AuthSession _authSession;
  String? _activeUserId;
  late final CaseRepository _caseRepository;
  late final CaseSelectionController _caseSelection;
  late final AiServiceBundle _aiServiceBundle = AiServiceFactory.create();
  late final HomeConversationRepository _homeConversations;

  /// 已接入真实实现的入口；未列入的一律走占位页。
  late final Map<AppView, Widget> _implemented = {
    AppView.tools: HomePage(
      onOpenFeature: _open,
      onOpenRoutedQuestion: _openRoutedQuestion,
      fortuneHeadline: () => TodayFortune.build(
        DateTime.now(),
        caseSnapshot: _caseSelection.currentSnapshot,
      ).headline,
      fortuneListenable: _caseSelection,
      currentCase: () => _caseSelection.currentSnapshot,
      conversationRepository: _homeConversations,
    ),
    AppView.charts: MeihuaPage(
      routedDraft: _routedDraft,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.meihuaRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
      onResultWithContext: (result, context) => _historyRepository.addMeihua(
        result,
        consultationContext: context,
        caseSnapshot: _caseSelection.currentSnapshot,
      ),
    ),
    AppView.compatibility: CompatibilityPage(
      repository: _caseRepository,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onOpenCases: () => _open(AppView.cases),
      onResult: _historyRepository.addCompatibility,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          result.stableId,
          response,
          answerStyle: _preference.id,
        );
      },
    ),
    AppView.xiaoliuren: XiaoliurenPage(
      routedDraft: _routedDraft,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.xiaoliurenRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
      onResultWithQuestion: (result, question) =>
          _historyRepository.addXiaoliuren(
            result,
            question: question,
            caseSnapshot: _caseSelection.currentSnapshot,
          ),
    ),
    AppView.oracle: OraclePage(
      routedDraft: _routedDraft,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.ssgwRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
      onResultWithQuestion: (result, question) => _historyRepository.addSsgw(
        result,
        question: question,
        caseSnapshot: _caseSelection.currentSnapshot,
      ),
    ),
    AppView.dailyHexagram: DailyHexagramPage(
      routedDraft: _routedDraft,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.dailyHexagramRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
      currentCase: () => _caseSelection.currentSnapshot,
      onResultWithQuestion: (result, question) =>
          _historyRepository.addDailyHexagram(
            result,
            question: question,
            caseSnapshot: _caseSelection.currentSnapshot,
          ),
    ),
    AppView.liuyao: LiuyaoPage(
      routedDraft: _routedDraft,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onResult: (result) => _historyRepository.addLiuyao(
        result,
        caseSnapshot: _caseSelection.currentSnapshot,
      ),
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.liuyaoRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
    ),
    AppView.bazi: BaziPage(
      currentCase: () => _caseSelection.currentSnapshot,
      onResult: (result) => _historyRepository.addBazi(result),
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.baziRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
    ),
    AppView.ziwei: ZiweiPage(
      currentCase: () => _caseSelection.currentSnapshot,
      onResult: _historyRepository.addZiwei,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.ziweiRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
    ),
    AppView.tarot: TarotPage(
      routedDraft: _routedDraft,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.tarotRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
      onResultWithQuestion: (result, question) => _historyRepository.addTarot(
        result,
        question: question,
        caseSnapshot: _caseSelection.currentSnapshot,
      ),
    ),
    AppView.almanac: const AlmanacPage(),
    AppView.fortune: FortunePage(
      currentCase: () => _caseSelection.currentSnapshot,
      aiService: _aiServiceBundle.service,
      answerStyle: () => _preference.id,
      onResult: (result, currentCase) =>
          _historyRepository.addTodayFortune(result, caseSnapshot: currentCase),
      onAiResponse: (result, response) async {
        await _historyRepository.updateAiInterpretation(
          DivinationHistoryRepository.todayFortuneRecordId(result),
          response,
          answerStyle: _preference.id,
        );
      },
    ),
    AppView.cases: CasesPage(
      repository: _caseRepository,
      selection: _caseSelection,
    ),
    AppView.settings: SettingsPage(
      authSession: _authSession,
      onAccountDeleted: _clearDeletedAccountData,
    ),
  };

  @override
  void initState() {
    super.initState();
    _historySyncClient = http.Client();
    _authSession = AuthSession(client: _historySyncClient)
      ..addListener(_onAuthChanged);
    _homeConversations = HomeConversationRepository(
      cloudSync: HomeConversationCloudSync(
        client: _historySyncClient,
        accessToken: _authSession.accessTokenForRequest,
      ),
    );
    _historyRepository = DivinationHistoryRepository(
      database: AppDatabase.shared,
      cloudSync: BackendHistoryCloudSync(
        client: _historySyncClient,
        accessToken: _authSession.accessTokenForRequest,
      ),
    );
    _caseRepository = CaseRepository(
      database: AppDatabase.shared,
      cloudSync: CaseCloudSync(
        client: _historySyncClient,
        accessToken: _authSession.accessTokenForRequest,
      ),
    );
    _caseSelection = CaseSelectionController(_caseRepository);
    unawaited(_authSession.restore());
  }

  @override
  void dispose() {
    _caseSelection.dispose();
    _caseRepository.dispose();
    _historyRepository.dispose();
    _authSession
      ..removeListener(_onAuthChanged)
      ..dispose();
    _historySyncClient.close();
    _aiServiceBundle.dispose();
    _homeConversations.dispose();
    _routedDraft.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    final nextUserId = _authSession.user?.id;
    if (nextUserId != null && nextUserId != _activeUserId) {
      unawaited(_historyRepository.refreshFromCloud());
      unawaited(_caseRepository.refreshFromCloud());
      unawaited(_homeConversations.syncFromCloud());
    }
    _activeUserId = nextUserId;
    if (mounted) setState(() {});
  }

  Future<void> _clearDeletedAccountData() async {
    _caseSelection.clearSelection();
    await _caseRepository.clearLocalData();
    await _historyRepository.clearLocalData();
    if (mounted) {
      setState(() {
        _view = AppView.settings;
        _activeUserId = null;
      });
    }
  }

  void _open(AppView view) {
    if (view == _view) return;
    setState(() {
      _visitedViews.add(view);
      _view = view;
    });
  }

  void _openRoutedQuestion(String question, DivinationTool tool) {
    _routedDraft.value = RoutedDivinationDraft(question: question, tool: tool);
    _open(switch (tool) {
      DivinationTool.meihua => AppView.charts,
      DivinationTool.tarot => AppView.tarot,
      DivinationTool.xiaoliuren => AppView.xiaoliuren,
      DivinationTool.ssgw => AppView.oracle,
      DivinationTool.liuyao => AppView.liuyao,
      DivinationTool.ziwei => AppView.ziwei,
      DivinationTool.dailyHexagram => AppView.dailyHexagram,
    });
  }

  /// 全局历史作为独立抽屉打开，不与案例页混用。
  void _openHistory() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _select(AppView view) {
    _open(view);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Widget _pageFor(AppView view) =>
      _implemented[view] ?? PlaceholderPage(view: view);

  /// 全局历史抽屉。
  ///
  /// 参考实现里历史是独立抽屉或路由状态，不与案例页共用入口。
  Widget get _historyDrawer {
    final available = MediaQuery.sizeOf(context).width;
    final width = available >= 480 ? 420.0 : available * 0.92;
    return Drawer(
      width: width,
      child: SafeArea(child: HistoryPage(repository: _historyRepository)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppTheme.sidebarBreakpoint;

    final topbar = AppTopBar(
      view: _view,
      onOpenNav: () => _scaffoldKey.currentState?.openDrawer(),
      onOpenCases: () => _open(AppView.cases),
      onOpenHistory: _openHistory,
      showNavToggle: !wide,
      // AI 偏好入口只在首页出现，其余页面顶栏显示标题。
      preference: _view == AppView.tools ? _preference : null,
      onPreferenceChanged: (value) => setState(() => _preference = value),
      channelName: '内置 AI',
      accountLabel: _authSession.user?.displayName ?? _authSession.user?.email,
      onOpenAccount: () => _open(AppView.settings),
    );

    final content = IndexedStack(
      index: _view.index,
      children: [
        for (final view in AppView.values)
          // 数据较大的术式只在首次进入时挂载；进入后继续留在
          // IndexedStack 中，因此切换页面仍能保留状态。
          if (_visitedViews.contains(view))
            _pageFor(view)
          else
            const SizedBox(),
      ],
    );

    if (wide) {
      return Scaffold(
        key: _scaffoldKey,
        endDrawer: _historyDrawer,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSidebar(current: _view, onSelect: _open),
            Expanded(
              child: Column(
                children: [
                  topbar,
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: AppTheme.sidebarWidth,
        backgroundColor: AppTheme.sidebar(context),
        child: AppSidebar(
          current: _view,
          onSelect: _select,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
      endDrawer: _historyDrawer,
      body: Column(
        children: [
          topbar,
          Expanded(child: content),
        ],
      ),
    );
  }
}
