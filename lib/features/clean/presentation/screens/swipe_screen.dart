import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/features/clean/presentation/providers/swipe_provider.dart';
import 'package:phonecleaner/features/clean/presentation/providers/gallery_provider.dart';
import 'package:phonecleaner/features/clean/presentation/screens/swipe_result_screen.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  final String category;
  const SwipeScreen({super.key, required this.category});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> with TickerProviderStateMixin {
  late Offset _offset = Offset.zero;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(swipeProvider(widget.category).notifier).loadPhotos(widget.category));
  }

  void _navigateToResults(SwipeState state) {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => SwipeResultScreen(
          category: widget.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(swipeProvider(widget.category));
    final processedCount = state.keptPhotos.length + state.deletedPhotos.length;
    final totalCount = state.photos.length + processedCount;

    String displayTitle = widget.category;
    if (widget.category.startsWith('Monthly_')) {
      final parts = widget.category.split('_');
      if (parts.length == 3) {
        final year = parts[1];
        final month = int.tryParse(parts[2]) ?? 1;
        final monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        displayTitle = '${monthNames[month - 1]} $year';
      }
    }

    ref.listen<SwipeState>(swipeProvider(widget.category), (previous, next) {
      if (previous != null &&
          !previous.isLoading &&
          previous.photos.isNotEmpty &&
          next.photos.isEmpty &&
          !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateToResults(next);
        });
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white.withValues(alpha: 0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          displayTitle.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        trailing: Text(
          state.photos.isNotEmpty ? '${processedCount + 1}/$totalCount' : '$processedCount/$totalCount',
          style: const TextStyle(
            color: Color(0xFF718096),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Undo button floating
            Positioned(
              top: 10,
              right: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(CupertinoIcons.arrow_counterclockwise, color: Color(0xFF2D3748), size: 20),
                ),
                onPressed: () => ref.read(swipeProvider(widget.category).notifier).undo(),
              ),
            ),
            
            if (state.isLoading)
              const Center(child: CupertinoActivityIndicator())
            else if (state.photos.isEmpty && state.keptPhotos.isEmpty && state.deletedPhotos.isEmpty)
              _buildEmptyState()
            else
              ...state.photos.indexed.map((entry) {
                final index = entry.$1;
                final asset = entry.$2;
                final isTop = index == state.photos.length - 1;

                return Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: isTop ? _buildTopCard(asset) : _buildBackgroundCard(index, state.photos.length),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 64,
            color: CupertinoColors.systemGrey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep it up!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(AssetEntity asset) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _offset += details.delta;
          _angle = _offset.dx / 20 * (pi / 180);
        });
      },
      onPanEnd: (details) {
        if (_offset.dx > 150) {
          _swipeRight(asset);
        } else if (_offset.dx < -150) {
          _swipeLeft(asset);
        } else {
          _resetPos();
        }
      },
      child: Transform.translate(
        offset: _offset,
        child: Transform.rotate(
          angle: _angle,
          child: Stack(
            children: [
              _buildPhotoCard(asset),
              _buildOverlayLabels(),
              _buildFloatingButtons(asset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(AssetEntity asset) {
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final hiddenIds = ref.watch(hiddenIdsProvider);
    final isFavorite = favoriteIds.contains(asset.id);
    final isHidden = hiddenIds.contains(asset.id);

    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingAction(
            icon: isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: isFavorite ? const Color(0xFFFF5252) : CupertinoColors.white,
            onPressed: () => ref.read(swipeProvider(widget.category).notifier).toggleFavorite(asset),
          ),
          const SizedBox(height: 16),
          _FloatingAction(
            icon: isHidden ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_slash,
            color: isHidden ? const Color(0xFFFFA000) : CupertinoColors.white,
            onPressed: () => ref.read(swipeProvider(widget.category).notifier).toggleHidden(asset),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(AssetEntity asset) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder(
        future: asset.thumbnailDataWithSize(const ThumbnailSize(1000, 1500)),
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
            color: const Color(0xFFF7FAFC),
            child: const Center(child: CupertinoActivityIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildOverlayLabels() {
    double opacity = (_offset.dx.abs() / 100).clamp(0.0, 1.0);
    bool isKeep = _offset.dx > 0;

    return Opacity(
      opacity: opacity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isKeep ? const Color(0xFF48BB78) : const Color(0xFFF56565), width: 4),
            borderRadius: BorderRadius.circular(12),
            color: CupertinoColors.black.withValues(alpha: 0.1),
          ),
          child: Text(
            isKeep ? 'KEEP' : 'DELETE',
            style: TextStyle(
              color: isKeep ? const Color(0xFF48BB78) : const Color(0xFFF56565),
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCard(int index, int total) {
    double scale = 0.9 + (index / total) * 0.1;
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDF2F7),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  void _swipeLeft(AssetEntity asset) {
    ref.read(swipeProvider(widget.category).notifier).deletePhoto(asset);
    _resetPos();
  }

  void _swipeRight(AssetEntity asset) {
    ref.read(swipeProvider(widget.category).notifier).keepPhoto(asset);
    _resetPos();
  }

  void _resetPos() {
    setState(() {
      _offset = Offset.zero;
      _angle = 0;
    });
  }
}

class _FloatingAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _FloatingAction({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: CupertinoColors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
