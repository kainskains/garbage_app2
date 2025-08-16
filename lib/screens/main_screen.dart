// lib/screens/main_screen.dart (改良版)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garbage_app/screens/trash_recognition_screen.dart';
import 'package:garbage_app/screens/settings_screen.dart';
import 'package:garbage_app/screens/calendar_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // 各画面の設定データ
  final List<ScreenConfig> _screens = [
    ScreenConfig(
      title: 'ごみ分別',
      icon: Icons.camera_alt,
      activeIcon: Icons.camera_alt_rounded,
      label: '分別',
      color: Colors.green,
      gradient: const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    ScreenConfig(
      title: 'カレンダー',
      icon: Icons.calendar_today,
      activeIcon: Icons.calendar_today_rounded,
      label: 'カレンダー',
      color: Colors.blue,
      gradient: const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF03A9F4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    ScreenConfig(
      title: '設定',
      icon: Icons.settings,
      activeIcon: Icons.settings_rounded,
      label: '設定',
      color: Colors.orange,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(initialPage: _selectedIndex);

    // FABアニメーション設定
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _widgetOptions = <Widget>[
      const TrashRecognitionScreen(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    // 初期アニメーション
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリのライフサイクル管理
    if (state == AppLifecycleState.resumed) {
      _fabAnimationController.forward();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // 同じタブの場合は何もしない

    // ハプティックフィードバック
    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = index;
    });

    // ページ遷移アニメーション
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );

    // FABアニメーションのリセット
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = _screens[_selectedIndex];

    return Scaffold(
      extendBody: false, // extendBodyをfalseに変更
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: currentScreen.gradient,
            boxShadow: [
              BoxShadow(
                color: currentScreen.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                currentScreen.title,
                key: ValueKey(_selectedIndex),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              // 通知アイコン（将来の機能拡張用）
              AnimatedOpacity(
                opacity: _selectedIndex == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _selectedIndex == 1 ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('通知設定は今後実装予定です'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } : null,
                ),
              ),
            ],
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        itemCount: _widgetOptions.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1.0 - (value * 0.3)).clamp(0.7, 1.0);
              }

              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: _widgetOptions[index],
                ),
              );
            },
          );
        },
      ),
      // FloatingActionButtonを削除（分別画面でのみ表示する必要がある場合は、
      // TrashRecognitionScreen内で独自に実装することを推奨）
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: List.generate(_screens.length, (index) {
              final screen = _screens[index];
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == index
                        ? screen.color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == index ? screen.activeIcon : screen.icon,
                    size: _selectedIndex == index ? 26 : 24,
                  ),
                ),
                activeIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: screen.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    screen.activeIcon,
                    size: 26,
                  ),
                ),
                label: screen.label,
              );
            }),
            currentIndex: _selectedIndex,
            selectedItemColor: _screens[_selectedIndex].color,
            unselectedItemColor: Colors.grey.shade600,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            selectedFontSize: 12,
            unselectedFontSize: 11,
          ),
        ),
      ),
    );
  }
}

// 画面設定用のデータクラス
class ScreenConfig {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  final LinearGradient gradient;

  const ScreenConfig({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.gradient,
  });
}