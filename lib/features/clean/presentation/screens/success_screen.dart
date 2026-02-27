import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonecleaner/features/stats/presentation/providers/stats_provider.dart';

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
      return '${(gb * 1024).toStringAsFixed(1)} MB';
    }
    return '${gb.toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTimeStats = ref.watch(statsProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF7BD96), // Peach/Orange background from design
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Header "success."
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'success.',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: CupertinoColors.white,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            
            // Recent stats section
            _buildStatSection(
              title: category != null ? 'from ${category!.toLowerCase()}...' : 'from recents...',
              count: deletedCount,
              size: _formatSize(sizeSavedGB),
              isMain: true,
            ),
            
            const SizedBox(height: 40),
            
            // All-time stats section
            _buildStatSection(
              title: 'all-time!',
              count: allTimeStats.totalDeleted,
              size: _formatSize(allTimeStats.totalStorageSavedGB),
              isMain: false,
            ),
            
            const Spacer(flex: 3),
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF53E6A1), // Mint green button from design
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSection({
    required String title,
    required int count,
    required String size,
    required bool isMain,
  }) {
    final textColor = isMain ? const Color(0xFF2D3748) : const Color(0xFF4A5568);
    final bgColor = isMain ? const Color(0xFFFFD8BE) : const Color(0xFFFEEBC8).withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count images',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'deleted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                size,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'saved',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
