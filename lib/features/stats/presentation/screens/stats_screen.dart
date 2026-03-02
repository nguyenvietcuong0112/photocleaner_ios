import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phonecleaner/features/stats/presentation/providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: CustomScrollView(
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Stats'),
              backgroundColor: CupertinoColors.transparent,
              border: null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    _StatCard(
                      title: 'Total Photos Deleted',
                      value: stats.totalDeleted.toString(),
                      subtitle: 'Since you started',
                      icon: CupertinoIcons.delete,
                      color: AppColors.delete,
                    ).animate().fadeIn().slideY(begin: 0.2),
                    SizedBox(height: 20.h),
                    _StatCard(
                      title: 'Storage Saved',
                      value:
                          '${stats.totalStorageSavedGB.toStringAsFixed(1)} GB',
                      subtitle: 'Valuable space recovered',
                      icon: CupertinoIcons.cloud_fill,
                      color: CupertinoColors.activeBlue,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                    SizedBox(height: 20.h),
                    _StatCard(
                      title: 'Current Streak',
                      value: '${stats.currentStreak} Days',
                      subtitle: 'Keep it going!',
                      icon: CupertinoIcons.flame_fill,
                      color: CupertinoColors.systemOrange,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    SizedBox(height: 40.h),
                    Text(
                      'Recent Sessions',
                      style:
                          AppTextStyles.subtitle.copyWith(fontSize: 18.sp),
                    ),
                    SizedBox(height: 20.h),
                    _buildSessionHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistory() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: List.generate(3, (index) => _SessionRow(index: index)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        AppTextStyles.subtitle.copyWith(fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Text(value,
                    style: AppTextStyles.counter.copyWith(fontSize: 32.sp)),
                SizedBox(height: 4.h),
                Text(subtitle,
                    style: TextStyle(
                        color: CupertinoColors.systemGrey2, fontSize: 13.sp)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32.sp),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final int index;
  const _SessionRow({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        border: index == 2
            ? null
            : Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey6, width: 1.h)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(['Yesterday', 'Feb 23', 'Feb 20'][index],
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
              Text('12:45 PM',
                  style: TextStyle(
                      color: CupertinoColors.systemGrey, fontSize: 12.sp)),
            ],
          ),
          Text(['-42 photos', '-28 photos', '-115 photos'][index],
              style: TextStyle(
                  color: AppColors.delete,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp)),
        ],
      ),
    );
  }
}

