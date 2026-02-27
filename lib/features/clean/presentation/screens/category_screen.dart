import 'package:flutter/cupertino.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/clean/presentation/screens/swipe_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: CustomScrollView(
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Clean'),
              backgroundColor: CupertinoColors.transparent,
              border: null,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _CategoryCard(
                    title: 'Recents',
                    subtitle: 'Clean your latest photos',
                    icon: CupertinoIcons.time,
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const SwipeScreen(category: 'Recents'))),
                  ).animate().fadeIn().slideX(begin: 0.1),
                  const SizedBox(height: 16),
                  _CategoryCard(
                    title: 'On This Day',
                    subtitle: 'Relive memories from today',
                    icon: CupertinoIcons.calendar_today,
                    color: const Color(0xFFEC4899),
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const SwipeScreen(category: 'On This Day'))),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 100)).slideX(begin: 0.1),
                  const SizedBox(height: 16),
                  _CategoryCard(
                    title: 'Monthly History',
                    subtitle: 'Grouped by month and year',
                    icon: CupertinoIcons.folder_fill,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const SwipeScreen(category: 'Monthly'))),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideX(begin: 0.1),
                  const SizedBox(height: 16),
                  _CategoryCard(
                    title: 'Random Mix',
                    subtitle: 'Feeling lucky? Clean anything',
                    icon: CupertinoIcons.shuffle,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const SwipeScreen(category: 'Random'))),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)).slideX(begin: 0.1),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.subtitle.copyWith(color: CupertinoColors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.subtitle.copyWith(fontSize: 14, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey4),
          ],
        ),
      ),
    );
  }
}
