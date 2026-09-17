import 'package:flutter/material.dart';
import 'package:zhaoxingzhai/features/history/data/divination_history_repository.dart';
import 'package:zhaoxingzhai/features/history/presentation/history_page.dart';
import 'package:zhaoxingzhai/features/home/presentation/home_page.dart';
import 'package:zhaoxingzhai/features/tarot/presentation/tarot_page.dart';
import 'package:zhaoxingzhai/features/xiaoliuren/presentation/xiaoliuren_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final DivinationHistoryRepository _historyRepository;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _historyRepository = DivinationHistoryRepository();
    _pages = [
      HomePage(onOpenFeature: _selectPage),
      XiaoliurenPage(onResult: _historyRepository.addXiaoliuren),
      TarotPage(onResult: _historyRepository.addTarot),
      HistoryPage(repository: _historyRepository),
    ];
  }

  @override
  void dispose() {
    _historyRepository.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            selectedIcon: Icon(Icons.nightlight),
            label: '小六壬',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: '塔罗',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
        ],
      ),
    );
  }
}
