import 'package:flutter/cupertino.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/clean/presentation/category_screen.dart';
import 'package:phonecleaner/features/clean/presentation/permission_screen.dart';
import 'package:phonecleaner/features/calendar/presentation/calendar_screen.dart';
import 'package:phonecleaner/features/supercut/presentation/supercut_screen.dart';
import 'package:phonecleaner/features/stats/presentation/stats_screen.dart';

class SwipeCleanApp extends StatelessWidget {
  const SwipeCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'SwipeClean',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: AppColors.backgroundStart,
      ),
      home: PermissionScreen(onGranted: AppScaffold()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sparkles),
            label: 'Clean',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.play_circle),
            label: 'Supercut',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Stats',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (context) => const CategoryScreen());
          case 1:
            return CupertinoTabView(builder: (context) => const CalendarScreen());
          case 2:
            return CupertinoTabView(builder: (context) => const SupercutScreen());
          case 3:
            return CupertinoTabView(builder: (context) => const StatsScreen());
          default:
            return const CategoryScreen();
        }
      },
    );
  }
}
