import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/splash/presentation/screens/intro_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

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
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => const IntroScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: ScreenUtil().statusBarHeight,
              left: 16.w,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Language',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006064),
                  ),
                ),
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
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: _languages.length,
              separatorBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(left: 80.w),
                child: const Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguage == lang['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang['name']!;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    color: CupertinoColors.white,
                    child: Row(
                      children: [
                        // Circular Flag
                        Container(
                          width: 48.w,
                          height: 48.w,
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
                        SizedBox(width: 20.w),
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
