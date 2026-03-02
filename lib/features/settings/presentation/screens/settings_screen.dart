import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/features/splash/presentation/screens/language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF7F9FC),
        border: null,
        middle: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3748),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            children: [
              _SettingsItem(
                icon: CupertinoIcons.textformat_abc_dottedunderline,
                label: 'Language',
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          const LanguageScreen(isFromSettings: true),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              _SettingsItem(
                icon: CupertinoIcons.share,
                label: 'Share app',
                onTap: () {},
              ),
              SizedBox(height: 12.h),
              _SettingsItem(
                icon: CupertinoIcons.star,
                label: 'Rate',
                onTap: () {},
              ),
              SizedBox(height: 12.h),
              _SettingsItem(
                icon: CupertinoIcons.shield_fill,
                label: 'Policy',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A5568), size: 24.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: const Color(0xFFCBD5E0),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
