import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/core/theme.dart';
import 'swipe_provider.dart';
import 'package:phonecleaner/features/clean/presentation/enhance_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(swipeProvider(widget.category));

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.category,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.normal),
            ),
            if (state.photos.isNotEmpty)
              Text(
                '${state.keptPhotos.length + state.deletedPhotos.length + 1} / ${state.photos.length + state.keptPhotos.length + state.deletedPhotos.length}',
                style: const TextStyle(color: CupertinoColors.white, fontSize: 17, fontWeight: FontWeight.bold),
              )
            else if (state.keptPhotos.isNotEmpty || state.deletedPhotos.isNotEmpty)
              Text(
                '${state.keptPhotos.length + state.deletedPhotos.length} / ${state.keptPhotos.length + state.deletedPhotos.length}',
                style: const TextStyle(color: CupertinoColors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.arrow_counterclockwise, color: CupertinoColors.white),
          onPressed: () => ref.read(swipeProvider(widget.category).notifier).undo(),
        ),
      ),
      child: Stack(
        children: [
          if (state.isLoading)
            const Center(child: CupertinoActivityIndicator(color: CupertinoColors.white))
          else if (state.photos.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.check_mark_circled, size: 100, color: AppColors.keep),
                  const SizedBox(height: 40),
                  const Text('Cleaning Complete!', style: TextStyle(color: CupertinoColors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('You processed ${state.keptPhotos.length + state.deletedPhotos.length} photos', 
                      style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 17)),
                  const SizedBox(height: 40),
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () => _showConfirmation(context, state.deletedPhotos),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Delete ${state.deletedPhotos.length} Photos'),
                    ),
                  ),
                ],
              ),
            )
          else
            ...state.photos.reversed.indexed.map((entry) {
              final index = entry.$1;
              final asset = entry.$2;
              final isTop = index == state.photos.length - 1;

              return Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isTop ? _buildTopCard(asset) : _buildBackgroundCard(index, state.photos.length),
                ),
              );
            }),
          
          _buildBottomBar(state),
        ],
      ),
    );
  }

  Widget _buildTopCard(AssetEntity asset) {
    return GestureDetector(
      onPanStart: (details) {},
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
          setState(() {
            _offset = Offset.zero;
            _angle = 0;
          });
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(AssetEntity asset) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
            color: CupertinoColors.systemGrey6,
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
            border: Border.all(color: isKeep ? AppColors.keep : AppColors.delete, width: 4),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black26,
          ),
          child: Text(
            isKeep ? 'KEEP' : 'DELETE',
            style: TextStyle(
              color: isKeep ? AppColors.keep : AppColors.delete,
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
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildBottomBar(SwipeState state) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: CupertinoIcons.xmark,
            color: AppColors.delete,
            onPressed: () => _swipeLeft(state.photos.last),
          ),
          _ActionButton(
            icon: CupertinoIcons.wand_stars,
            color: CupertinoColors.systemPurple,
            onPressed: () {
              if (state.photos.isNotEmpty) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => EnhanceScreen(asset: state.photos.last),
                  ),
                );
              }
            },
          ),
          _ActionButton(
            icon: CupertinoIcons.heart_fill,
            color: AppColors.keep,
            onPressed: () => _swipeRight(state.photos.last),
          ),
        ],
      ),
    );
  }

  void _preloadThumbnails(List<AssetEntity> photos) {
    if (photos.isEmpty) return;
    final count = min(photos.length, 3);
    for (int i = 0; i < count; i++) {
      photos[i].thumbnailDataWithSize(const ThumbnailSize(1000, 1500));
    }
  }

  void _swipeLeft(AssetEntity asset) {
    ref.read(swipeProvider(widget.category).notifier).deletePhoto(asset);
    _resetPos();
    _preloadThumbnails(ref.read(swipeProvider(widget.category)).photos);
  }

  void _swipeRight(AssetEntity asset) {
    ref.read(swipeProvider(widget.category).notifier).keepPhoto(asset);
    _resetPos();
    _preloadThumbnails(ref.read(swipeProvider(widget.category)).photos);
  }

  void _resetPos() {
    setState(() {
      _offset = Offset.zero;
      _angle = 0;
    });
  }

  void _showConfirmation(BuildContext context, List<AssetEntity> toDelete) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Delete Photos'),
        message: Text('Are you sure you want to delete ${toDelete.length} photos?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(swipeProvider(widget.category).notifier).confirmDeletion();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete All'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
