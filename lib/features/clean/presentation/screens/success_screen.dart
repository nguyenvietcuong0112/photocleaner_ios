import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/features/stats/presentation/providers/stats_provider.dart';

import '../../../home/presentation/screens/home_screen.dart';

class SuccessScreen extends ConsumerWidget {
  final int deletedCount;
  final double sizeSavedGB;
  final String? category;

  const SuccessScreen({
    super.key,
    required this.deletedCount,
    required this.sizeSavedGB,
    this.category,
  });

  String _formatSize(double gb) {
    if (gb < 0.1) {
      // Format with common/dot as in image (e.g. 857,5 MB)
      final mb = gb * 1024;
      return mb.toStringAsFixed(1).replaceAll('.', ',');
    }
    return gb.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatNumber(int number) {
    // Add space or comma for thousands if needed, but the image shows simple numbers
    return number.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTimeStats = ref.watch(statsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                // Success Icon Area
                _buildSuccessIcon(),
                SizedBox(height: 16.h),
                Text(
                  'SUCCESS',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A202C),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Recents Section
          _buildStatSection(
            title: 'Recents',
            count: deletedCount,
            size: _formatSize(sizeSavedGB),
            unit: sizeSavedGB < 0.1 ? 'MB' : 'GB',
            backgroundColor: const Color(0xFFF7FAFC),
          ),
          
          // All Time Section
          _buildStatSection(
            title: 'All time',
            count: allTimeStats.totalDeleted,
            size: _formatSize(allTimeStats.totalStorageSavedGB),
            unit: allTimeStats.totalStorageSavedGB < 0.1 ? 'MB' : 'GB',
            backgroundColor: const Color(0xFFEBF8FF),
          ),
          
          // Action Button Section
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: _buildHomeButton(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        color: const Color(0xFF9AE6B4).withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(12.w),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF68D391),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.checkmark_alt,
            color: CupertinoColors.white,
            size: 64.sp,
            weight: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection({
    required String title,
    required int count,
    required String size,
    required String unit,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A5568),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                '${_formatNumber(count)} Images',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF56565), // Bright Red
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Deleted',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Text(
                '$size $unit',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF48BB78), // Vibrant Green
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Saved',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF63B3ED), Color(0xFF4299E1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4299E1).withValues(alpha: 0.4),
              blurRadius: 15.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Back to home',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
