import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/features/clean/presentation/providers/swipe_monthly_provider.dart';
import 'package:phonecleaner/features/clean/presentation/screens/swipe_screen.dart';

class SwipeMonthlyScreen extends ConsumerWidget {
  const SwipeMonthlyScreen({super.key});

  static const List<String> _monthNames = [
    '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(monthlyGroupsProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white.withValues(alpha: 0.95),
        border: null,
        middle: Text(
          'Swipe',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
      ),
      child: SafeArea(
        child: groupsAsync.when(
          data: (groups) => _buildGroupsList(context, groups),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 48.sp,
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.6)),
                SizedBox(height: 12.h),
                Text(
                  'Failed to load photos',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16.sp,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, List<MonthlyGroup> groups) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.photo_on_rectangle,
                size: 64.sp,
                color: CupertinoColors.systemGrey.withValues(alpha: 0.6)),
            SizedBox(height: 16.h),
            Text(
              'No photos found',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }

    // Separate recent (current month) from historical
    final now = DateTime.now();
    MonthlyGroup? recentGroup;
    final historicalGroups = <MonthlyGroup>[];

    for (final group in groups) {
      if (group.year == now.year && group.month == now.month) {
        recentGroup = group;
      } else {
        historicalGroups.add(group);
      }
    }

    final allItems = <_MonthCardData>[];

    if (recentGroup != null) {
      allItems.add(_MonthCardData(
        label: 'RECENT',
        sublabel: '',
        group: recentGroup,
        isRecent: true,
      ));
    }

    for (final group in historicalGroups) {
      allItems.add(_MonthCardData(
        label: _monthNames[group.month],
        sublabel: '${group.year}',
        group: group,
        isRecent: false,
      ));
    }

    return ListView.builder(
      padding: EdgeInsets.only(left: 12.w, right: 16.w, top: 8.h, bottom: 20.h),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        return _buildMonthCard(
          context: context,
          data: item,
        );
      },
    );
  }

  Widget _buildMonthCard({
    required BuildContext context,
    required _MonthCardData data,
  }) {
    final category = 'Monthly_${data.group.year}_${data.group.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 65.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (data.sublabel.isNotEmpty)
                  Text(
                    data.sublabel,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A5568),
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          // Thumbnail card
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => SwipeScreen(category: category),
                  ),
                );
              },
              child: Container(
                height: 170.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.08),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover thumbnail
                    _CoverThumbnail(asset: data.group.coverAsset),
                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60.h,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0x00000000),
                              const Color(0xFF000000).withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Item count badge
                    Positioned(
                      bottom: 14.h,
                      left: 16.w,
                      child: Row(
                        children: [
                          Container(
                            width: 26.w,
                            height: 26.w,
                            decoration: BoxDecoration(
                              color: _getBadgeColor(data.group.month),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getBadgeColor(data.group.month)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${data.group.count} items',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(
                                  color: Color(0x80000000),
                                  blurRadius: 4.r,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(int month) {
    final colors = [
      const Color(0xFF42A5F5), // Jan
      const Color(0xFFEF5350), // Feb
      const Color(0xFF66BB6A), // Mar
      const Color(0xFFAB47BC), // Apr
      const Color(0xFFFFA726), // May
      const Color(0xFF26C6DA), // Jun
      const Color(0xFFFF7043), // Jul
      const Color(0xFF5C6BC0), // Aug
      const Color(0xFF8D6E63), // Sep
      const Color(0xFF26A69A), // Oct
      const Color(0xFFBDBDBD), // Nov
      const Color(0xFFFFA726), // Dec
    ];
    return colors[(month - 1) % 12];
  }
}

class _MonthCardData {
  final String label;
  final String sublabel;
  final MonthlyGroup group;
  final bool isRecent;

  _MonthCardData({
    required this.label,
    required this.sublabel,
    required this.group,
    required this.isRecent,
  });
}

class _CoverThumbnail extends StatelessWidget {
  final AssetEntity asset;
  const _CoverThumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(600, 400)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return Container(
          color: const Color(0xFFE2E8F0),
          child: const Center(child: CupertinoActivityIndicator()),
        );
      },
    );
  }
}
