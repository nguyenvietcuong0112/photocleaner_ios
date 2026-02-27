import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsArea(context, statsAsync, userStats),
                ),
              ),
              // Feature Icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFeatureIcons(context),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsArea(BuildContext context,
      AsyncValue<PhotoStats> photoStatsAsync, UserStats userStats) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 280, // Sufficient height for stats content
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                // Page 1: General Stats
                photoStatsAsync.when(
                  data: (stats) => _buildGeneralStatsPage(context, stats),
                  loading: () =>
                  const Center(child: CupertinoActivityIndicator()),
                  error: (_, __) =>
                      _buildGeneralStatsPage(context, const PhotoStats()),
                ),
                // Page 2: Swipe Stats
                _buildSwipeStatsPage(
                    context, photoStatsAsync.value ?? const PhotoStats(),
                    userStats),
              ],
            ),
          ),

          // Page indicator dots
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) => _buildDot(index)),
            ),
          ),

          // Swipe Button (always visible)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildMainSwipeButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF4299E1) : const Color(
            0xFFCBD5E0),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery
        .of(context)
        .padding
        .top;
    return Container(
      padding: EdgeInsets.only(
          top: topPadding + 20, left: 24, right: 24, bottom: 50),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PhotoCleaner',
            style: TextStyle(
              fontSize: 28,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.gear_alt_fill,
                color: CupertinoColors.white,
                size: 22,
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
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total count
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$total ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  decoration: TextDecoration.none,
                ),
              ),
              const TextSpan(
                text: 'photos and videos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF718096),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Storage bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: usedRatio,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4299E1), Color(0xFF667EEA)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo size',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA0AEC0),
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  stats.usedStorageGB < 0.1
                      ? '${(stats.usedStorageGB * 1024).toStringAsFixed(1)} MB'
                      : '${stats.usedStorageGB.toStringAsFixed(1)} GB',
                  style: const TextStyle(
                    fontSize: 13,
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
        Container(height: 1, color: const Color(0xFFEDF2F7)),
        const SizedBox(height: 16),

        // Category breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCategoryStat(
                CupertinoIcons.person_crop_rectangle, 'Selfies', stats.selfies),
            _buildCategoryStat(
                CupertinoIcons.device_phone_portrait, 'Screenshots',
                stats.screenshots),
            _buildCategoryStat(
                CupertinoIcons.play_rectangle, 'Videos', stats.totalVideos),
            _buildCategoryStat(
                CupertinoIcons.ellipsis_circle, 'Other', stats.other),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSwipeStatsPage(BuildContext context, PhotoStats photoStats,
    UserStats userStats) {
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
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$deleted ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  decoration: TextDecoration.none,
                ),
              ),
              const TextSpan(
                text: 'images are being deleted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF718096),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Progress bar
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedStorage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
                decoration: TextDecoration.none,
              ),
            ),
            // Text(
            //   '${photoStats.usedStorageGB.toStringAsFixed(1)} GB',
            //   style: const TextStyle(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w500,
            //     color: Color(0xFFA0AEC0),
            //     decoration: TextDecoration.none,
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 24),

        Container(height: 1, color: const Color(0xFFEDF2F7)),
        const SizedBox(height: 20),

        // Swipe metrics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCategoryStat(CupertinoIcons.trash, 'Delete', deleted),
            _buildCategoryStat(CupertinoIcons.arrow_down_to_line, 'Keep', kept),
            _buildCategoryStat(
                CupertinoIcons.square_list, 'Remaining', remaining),
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
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.swipeButtonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.arrow_2_squarepath, color: CupertinoColors.white,
              size: 22),
          SizedBox(width: 10),
          Text(
            'Swipe',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 20,
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
          Icon(icon, size: 14, color: const Color(0xFF718096)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        '$count',
        style: const TextStyle(
          fontSize: 22,
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
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
            decoration: TextDecoration.none,
          ),
        ),
      ],
    ),
  );
}
