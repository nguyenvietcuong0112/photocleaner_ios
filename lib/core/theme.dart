import 'package:flutter/cupertino.dart';

class AppColors {
  static const Color keep = Color(0xFF4CAF50);
  static const Color delete = Color(0xFFFF5252);
  static const Color backgroundStart = Color(0xFFF0F2F5);
  static const Color backgroundEnd = Color(0xFFE2E8F0);
  
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDFCFB),
      Color(0xFFE2D1C3),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      CupertinoColors.white,
      Color(0xFFF8F9FA),
    ],
  );
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: CupertinoColors.black,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle counter = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    color: CupertinoColors.black,
    letterSpacing: -1,
  );

  static const TextStyle label = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );
}
