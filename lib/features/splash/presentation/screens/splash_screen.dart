import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/features/splash/presentation/screens/language_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const LanguageScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Redrawn background using CustomPainter
          CustomPaint(painter: SplashBackgroundPainter()),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20.r,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32.r),
                        child: Container(
                          color: Colors.white,
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  CupertinoIcons.photo_fill,
                                  size: 64,
                                  color: Color(0xFF00ACC1),
                                ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                    )
                    .fadeIn(duration: 600.ms),
                SizedBox(height: 24.h),
                // App Name
                Text(
                      'PhotoCleaner',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                SizedBox(height: 8.h),
                Text(
                  'Smart Cleanup • Simple Life',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 800.ms),
              ],
            ),
          ),
          // Loading indicator at bottom
          Positioned(
            bottom: 60.h,
            left: 0,
            right: 0,
            child: const Center(
              child: CupertinoActivityIndicator(
                color: Colors.white,
                radius: 12,
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ),
        ],
      ),
    );
  }
}

class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Base Gradient
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF006064), // Deep Teal
          Color(0xFF00ACC1), // Cyan
          Color(0xFF4DD0E1), // Light Cyan
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // 2. Abstract Shapes (Hexagons)
    _drawHexagon(
      canvas,
      size,
      Offset(size.width * 0.2, size.height * 0.2),
      120,
      0.1,
    );
    _drawHexagon(
      canvas,
      size,
      Offset(size.width * 0.8, size.height * 0.4),
      180,
      0.08,
    );
    _drawHexagon(
      canvas,
      size,
      Offset(size.width * 0.3, size.height * 0.7),
      200,
      0.05,
    );
    _drawHexagon(
      canvas,
      size,
      Offset(size.width * 0.7, size.height * 0.1),
      80,
      0.12,
    );

    // 3. Light Streaks
    final streakPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.4,
        size.width,
        size.height * 0.2,
      );
    canvas.drawPath(path1, streakPaint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.6,
        size.width,
        size.height * 0.8,
      );
    canvas.drawPath(path2, streakPaint);

    // 4. Soft Overlay Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.8,
        colors: [Colors.white.withOpacity(0.2), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);
  }

  void _drawHexagon(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double opacity,
  ) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * math.pi / 180;
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
