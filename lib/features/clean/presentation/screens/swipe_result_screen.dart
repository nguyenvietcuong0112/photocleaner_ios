import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/clean/presentation/providers/swipe_provider.dart';
import 'package:phonecleaner/features/clean/presentation/screens/success_screen.dart';

class SwipeResultScreen extends ConsumerWidget {
  final String category;

  const SwipeResultScreen({
    super.key,
    required this.category,
    // deletedCount and keptCount are now reactive via the provider
    int? deletedCount,
    int? keptCount,
  });

  String _formatStorage(double gb) {
    if (gb < 0.01) {
      final mb = gb * 1024;
      return '${mb.toStringAsFixed(1)} MB';
    }
    return '${gb.toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(swipeProvider(category));
    final deletedPhotos = state.deletedPhotos;
    
    // Ensure unique photos in the grid list by ID
    final seenIds = <String>{};
    final allPhotos = [...state.deletedPhotos, ...state.keptPhotos]
        .where((p) => seenIds.add(p.id))
        .toList();
    
    // Calculate total size based on deleted photos
    final totalSizeGB = (deletedPhotos.length * 3.0) / 1024.0;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white.withValues(alpha: 0.9),
        border: null,
        middle: Text(
          category.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF718096),
            letterSpacing: 1.2,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Color(0xFF2D3748)),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Grid view
            Padding(
              padding: const EdgeInsets.only(bottom: 100), // Height of bottom bar
              child: GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: allPhotos.length,
                itemBuilder: (context, index) {
                  final asset = allPhotos[index];
                  final isDeleted = deletedPhotos.any((p) => p.id == asset.id);
                  return _buildGridItem(context, ref, asset, isDeleted);
                },
              ),
            ),

            // Sticky Bottom Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(context, ref, deletedPhotos.length, totalSizeGB),
            ),

            if (state.isDeleting)
              Container(
                color: const Color(0x42000000),
                child: const Center(child: CupertinoActivityIndicator(color: CupertinoColors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, WidgetRef ref, AssetEntity asset, bool isDeleted) {
    return GestureDetector(
      onTap: () {
        ref.read(swipeProvider(category).notifier).toggleDeletion(asset);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.all(isDeleted ? 4 : 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isDeleted 
              ? Border.all(color: const Color(0xFFF06292), width: 3)
              : Border.all(color: CupertinoColors.transparent, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            _Thumbnail(asset: asset),
            
            // Selection overlay - Red tint for deletion
            AnimatedOpacity(
              opacity: isDeleted ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: const Color(0xFFF06292).withValues(alpha: 0.25),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.trash_fill,
                    color: CupertinoColors.white,
                    size: 32,
                    shadows: [Shadow(color: Color(0x42000000), blurRadius: 8)],
                  ),
                ),
              ),
            ),
            
            // Badge indicator
            Positioned(
              top: 8,
              right: 8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: isDeleted
                    ? Container(
                        key: const ValueKey('delete_badge'),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF06292),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.trash_fill, size: 14, color: CupertinoColors.white),
                      )
                    : Container(
                        key: const ValueKey('keep_badge'),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.checkmark_alt, size: 14, color: CupertinoColors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, int count, double sizeGB) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count selected',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  _formatStorage(sizeGB),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          
          // Delete Button
          GestureDetector(
            onTap: count > 0 ? () => _showDeleteConfirmation(context, ref) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: count > 0 ? AppColors.swipeButtonGradient : null,
                color: count > 0 ? null : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(14),
                boxShadow: count > 0 ? [
                  BoxShadow(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: const Text(
                'Delete photos',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _DeleteConfirmDialog(
        onConfirm: () async {
          final navigator = Navigator.of(context);
          Navigator.pop(context); // Close custom dialog immediately
          final deletedIds = await ref.read(swipeProvider(category).notifier).confirmDeletion();
          
          if (deletedIds.isNotEmpty) {
            final actualSizeGB = (deletedIds.length * 3.0) / 1024.0;
            navigator.pushAndRemoveUntil(
              CupertinoPageRoute(
                builder: (_) => SuccessScreen(
                  deletedCount: deletedIds.length,
                  sizeSavedGB: actualSizeGB,
                  category: category,
                ),
              ),
              (route) => route.isFirst,
            );
          }
        },
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF06292),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The file(s) will be moved to Trash and automatically deleted after 30 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A5568),
                decoration: TextDecoration.none,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06292),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final AssetEntity asset;
  const _Thumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return Container(color: const Color(0xFFEDF2F7));
      },
    );
  }
}
