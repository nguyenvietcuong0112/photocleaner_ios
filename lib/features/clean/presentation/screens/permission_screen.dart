import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/core/theme.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  final Widget onGranted;
  const PermissionScreen({super.key, required this.onGranted});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isChecking = false;

  Future<void> _requestAccess() async {
    setState(() => _isChecking = true);
    final granted = await ref.read(photoRepositoryProvider).requestPermission();
    setState(() => _isChecking = false);

    if (granted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => widget.onGranted),
        );
      }
    } else {
      _showDeniedDialog();
    }
  }

  void _showDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'PhotoCleaner needs photo access to help you clean your library. Please enable it in Settings.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Settings'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Decoration
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50.h,
            left: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.03),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                children: [
                  const Spacer(),
                  // Premium Icon Container
                  Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4DD0E1), AppColors.accent],
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: 60.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 48.h),
                  Text(
                    'Access Your Photos',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006064),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'To start cleaning, we need permission to view your photo library. We never upload your photos anywhere.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16.sp,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  // Feature highlights
                  _buildFeatureRow(
                    CupertinoIcons.lock_shield,
                    'Secure & Private',
                  ),
                  SizedBox(height: 16.h),
                  _buildFeatureRow(CupertinoIcons.bolt_fill, 'Fast Scanning'),
                  const Spacer(),

                  if (_isChecking)
                    const CupertinoActivityIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _requestAccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Give Access'),
                      ),
                    ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.sp, color: AppColors.accent),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF263238),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
