import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'matches_screen.dart';
import 'league_hub_screen.dart';
import 'competitions_screen.dart';
import 'kijiweni_screen.dart';
import 'more_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MatchesScreen(),
    LeagueHubScreen(),
    CompetitionsScreen(),
    KijiweniScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.surface : AppColors.lightSurface;
    final borderCol = isDark ? AppColors.borderSubtle : AppColors.lightBorder;
    final unselectedCol = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: borderCol, width: 1),
          ),
          boxShadow: isDark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: navBg,
          selectedItemColor: AppColors.emerald,
          unselectedItemColor: unselectedCol,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.sports_soccer_outlined),
              activeIcon: const Icon(Icons.sports_soccer),
              label: AppStrings.get('nav_matches'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.leaderboard_outlined),
              activeIcon: const Icon(Icons.leaderboard_rounded),
              label: AppStrings.get('nav_table_stats'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events_outlined),
              activeIcon: const Icon(Icons.emoji_events),
              label: AppStrings.get('nav_leagues'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.forum_outlined),
              activeIcon: const Icon(Icons.forum_rounded),
              label: AppStrings.get('nav_kijiweni'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz_rounded),
              activeIcon: const Icon(Icons.more_horiz),
              label: AppStrings.get('nav_more'),
            ),
          ],
        ),
      ),
    );
  }
}
