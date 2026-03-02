import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/splash/presentation/screens/intro_screen.dart';

class LanguageScreen extends StatefulWidget {
  final bool isFromSettings;
  const LanguageScreen({super.key, this.isFromSettings = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'flag': 'assets/icons/flag_en.png'},
    {'name': 'France', 'flag': 'assets/icons/flag_fr.png'},
    {'name': 'Germany', 'flag': 'assets/icons/flag_de.png'},
    {'name': 'Ghana', 'flag': 'assets/icons/flag_gh.png'},
  ];

  void _onContinue() {
    if (widget.isFromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (context) => const IntroScreen()));
    }
  }

  void _onLanguageSelected(String name) {
    setState(() {
      _selectedLanguage = name;
    });

    // If coming from settings, auto-pop after a short delay to show selection
    if (widget.isFromSettings) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: ScreenUtil().statusBarHeight,
              left: 8.w,
              right: 16.w,
            ),
            height: 60.h + ScreenUtil().statusBarHeight,
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: Row(
              children: [
                if (widget.isFromSettings)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.chevron_back,
                      color: Color(0xFF006064),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                SizedBox(width: 8.w),
                Text(
                  'Choose Language',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006064),
                  ),
                ),
                const Spacer(),
                if (!widget.isFromSettings)
                  GestureDetector(
                    onTap: _onContinue,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_right,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Language List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguage == lang['name'];

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: GestureDetector(
                    onTap: () => _onLanguageSelected(lang['name']!),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Circular Flag
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                lang['flag']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: CupertinoColors.systemGrey6,
                                      child: const Icon(
                                        CupertinoIcons.flag,
                                        size: 20,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Text(
                            lang['name']!,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: const Color(0xFF263238),
                            ),
                          ),
                          const Spacer(),
                          // Custom Radio Button
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : const Color(0xFFCFD8DC),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 12.w,
                                      height: 12.w,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
