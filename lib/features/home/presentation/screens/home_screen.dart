import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/features/home/presentation/providers/home_provider.dart';
import 'package:phonecleaner/features/clean/presentation/screens/swipe_monthly_screen.dart';
import 'package:phonecleaner/features/clean/presentation/screens/duplicate_screen.dart';
import 'package:phonecleaner/features/clean/presentation/screens/favorite_screen.dart';
import 'package:phonecleaner/features/clean/presentation/screens/hidden_screen.dart';
import 'package:phonecleaner/features/settings/presentation/screens/settings_screen.dart';
import 'package:phonecleaner/features/stats/presentation/providers/stats_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(homeStatsProvider);
    final userStats = ref.watch(statsProvider);

    return CupertinoPageScaffold(
      child: Container(
        color: const Color(0xFFF0F4F8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              // Stats Card Area (overlapping header)
              Transform.translate(
                offset: Offset(0, -100.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildStatsArea(context, statsAsync, userStats),
                ),
              ),
              // Feature Icons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildFeatureIcons(context),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsArea(
    BuildContext context,
    AsyncValue<PhotoStats> photoStatsAsync,
    UserStats userStats,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 250.h,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                photoStatsAsync.when(
                  data: (stats) => _buildGeneralStatsPage(context, stats),
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (_, __) =>
                      _buildGeneralStatsPage(context, const PhotoStats()),
                ),
                _buildSwipeStatsPage(
                  context,
                  photoStatsAsync.value ?? const PhotoStats(),
                  userStats,
                ),
              ],
            ),
          ),

          // Page indicator dots
          Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) => _buildDot(index)),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
            child: _buildMainSwipeButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? const Color(0xFF4299E1)
            : const Color(0xFFCBD5E0),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 20.h,
        left: 24.w,
        right: 24.w,
        bottom: 120.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2DB6C7), Color(0xFF019FB3)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(
            'PhotoCleaner',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
              letterSpacing: -0.5,
              decoration: TextDecoration.none,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                CupertinoIcons.gear_alt_fill,
                color: CupertinoColors.white,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildGeneralStatsPage(BuildContext context, PhotoStats stats) {
  final total = stats.totalPhotos + stats.totalVideos;
  final usedRatio = stats.totalStorageGB > 0
      ? (stats.usedStorageGB / stats.totalStorageGB).clamp(0.0, 1.0)
      : 0.0;

  return Padding(
    padding: EdgeInsets.all(24.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total count
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$total ',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  decoration: TextDecoration.none,
                ),
              ),
              TextSpan(
                text: 'photos and videos',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF718096),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Storage bar
        Container(
          height: 8.h,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: usedRatio,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8FB1FA), Color(0xFF5F8DF1)],
                ),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo size',
                  style: TextStyle(
                    fontSize: 11, // keep very small font small or use sp? let's use sp for consistency
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA0AEC0),
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  stats.usedStorageGB < 0.1
                      ? '${(stats.usedStorageGB * 1024).toStringAsFixed(1)} MB'
                      : '${stats.usedStorageGB.toStringAsFixed(1)} GB',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total Capacity',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA0AEC0),
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  '${stats.totalStorageGB.toStringAsFixed(0)} GB',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA0AEC0),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Divider
        Container(height: 1.h, color: const Color(0xFFEDF2F7)),
        SizedBox(height: 16.h),

        // Category breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCategoryStat(
              CupertinoIcons.person_crop_rectangle,
              'Selfies',
              stats.selfies,
            ),
            _buildCategoryStat(
              CupertinoIcons.device_phone_portrait,
              'Screenshots',
              stats.screenshots,
            ),
            _buildCategoryStat(
              CupertinoIcons.play_rectangle,
              'Videos',
              stats.totalVideos,
            ),
            _buildCategoryStat(
              CupertinoIcons.ellipsis_circle,
              'Other',
              stats.other,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSwipeStatsPage(
  BuildContext context,
  PhotoStats photoStats,
  UserStats userStats,
) {
  final deleted = userStats.totalDeleted;
  final kept = userStats.totalKept;
  final processed = deleted + kept;
  final total = photoStats.totalPhotos + photoStats.totalVideos;
  final remaining = (total - processed).clamp(0, total);

  // Progress calculation
  final progress = total > 0 ? (processed / total).clamp(0.0, 1.0) : 0.0;

  // Formatting storage
  String formattedStorage = userStats.totalStorageSavedGB < 0.1
      ? '${(userStats.totalStorageSavedGB * 1024).toStringAsFixed(0)} MB'
      : '${userStats.totalStorageSavedGB.toStringAsFixed(1)} GB';

  return Padding(
    padding: EdgeInsets.all(24.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$deleted ',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  decoration: TextDecoration.none,
                ),
              ),
              TextSpan(
                text: 'images are being deleted',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF718096),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Progress bar
        Container(
          height: 12.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8FB1FA), Color(0xFF5F8DF1)],
                ),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedStorage,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        Container(height: 1.h, color: const Color(0xFFEDF2F7)),
        SizedBox(height: 20.h),

        // Swipe metrics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCategoryStat(CupertinoIcons.trash, 'Delete', deleted),
            _buildCategoryStat(CupertinoIcons.arrow_down_to_line, 'Keep', kept),
            _buildCategoryStat(
              CupertinoIcons.square_list,
              'Remaining',
              remaining,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildMainSwipeButton(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => const SwipeMonthlyScreen()),
      );
    },
    child: Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: AppColors.swipeButtonGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withValues(alpha: 0.35),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.arrow_2_squarepath,
            color: CupertinoColors.white,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            'Swipe',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCategoryStat(IconData icon, String label, int count) {
  return Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: const Color(0xFF718096)),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
      SizedBox(height: 6.h),
      Text(
        '$count',
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D3748),
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );
}

Widget _buildFeatureIcons(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildFeatureIcon(
        icon: CupertinoIcons.photo_on_rectangle,
        label: 'Duplicate',
        color: const Color(0xFF00BCD4),
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const DuplicateScreen()),
          );
        },
      ),
      _buildFeatureIcon(
        icon: CupertinoIcons.eye_slash,
        label: 'Hide photos',
        color: const Color(0xFF4CAF50),
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const HiddenScreen()),
          );
        },
      ),
      _buildFeatureIcon(
        icon: CupertinoIcons.heart_fill,
        label: 'Favorite',
        color: const Color(0xFFE91E63),
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const FavoriteScreen()),
          );
        },
      ),
    ],
  );
}

Widget _buildFeatureIcon({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32.sp),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    ),
  );
}
