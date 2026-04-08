import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/home/presentation/screens/home_screen.dart';
import 'package:phonecleaner/features/splash/presentation/screens/splash_screen.dart';

class SwipeCleanApp extends StatelessWidget {
  const SwipeCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 13/14 design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const CupertinoApp(
          title: 'SwipeClean',
          theme: CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: CupertinoColors.activeBlue,
            scaffoldBackgroundColor: AppColors.backgroundStart,
          ),
          home: SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
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
