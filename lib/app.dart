import 'package:flutter/cupertino.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/home/presentation/screens/home_screen.dart';
import 'package:phonecleaner/features/clean/presentation/screens/permission_screen.dart';

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
    // Return HomeScreen directly without the bottom navigation bar
    return const HomeScreen();
  }
}
