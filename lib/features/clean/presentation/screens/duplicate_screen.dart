import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/features/clean/presentation/providers/duplicate_provider.dart';
import 'package:phonecleaner/features/clean/presentation/screens/success_screen.dart';

class DuplicateScreen extends ConsumerWidget {
  const DuplicateScreen({super.key});

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duplicateProvider);
    
    int totalSelectedSize = 0;
    int totalSelectedCount = 0;
    for (var groupState in state.groups) {
      if (groupState.selectedIds.isNotEmpty) {
        totalSelectedCount += groupState.selectedIds.length;
        totalSelectedSize += ((groupState.group.totalSize / groupState.group.assets.length) * groupState.selectedIds.length).floor();
      }
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white.withValues(alpha: 0.9),
        border: null,
        middle: Text(
          'Duplicate',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, size: 24.sp, color: Color(0xFF2D3748)),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (state.isLoading)
              const Center(child: CupertinoActivityIndicator())
            else if (state.groups.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                padding: EdgeInsets.only(bottom: 120.h, top: 10.h),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final groupState = state.groups[index];
                  return _buildDuplicateGroup(context, ref, index, groupState);
                },
              ),

            // Bottom bar
            if (state.groups.isNotEmpty)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildBottomBar(context, ref, totalSelectedCount, totalSelectedSize, state.isDeleting),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.doc_on_doc,
              size: 60.sp,
              color: CupertinoColors.systemGrey.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(
            'No duplicates found',
            style: TextStyle(
                fontSize: 18.sp,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateGroup(BuildContext context, WidgetRef ref, int groupIndex, DuplicateGroupState groupState) {
    final assets = groupState.group.assets;
    final isAnySelected = groupState.selectedIds.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${assets.length} Photo',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3182CE),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (isAnySelected) {
                    ref.read(duplicateProvider.notifier).deselectAll(groupIndex);
                  } else {
                    ref.read(duplicateProvider.notifier).selectAll(groupIndex);
                  }
                },
                child: Text(
                  isAnySelected ? 'Deselect all' : 'Select all',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4299E1),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Large "Best" photo
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildLargeThumbnail(assets[0],
                      groupState.selectedIds.contains(assets[0].id)),
                ),
              ),
              SizedBox(width: 8.w),
              // Right: 2x2 grid
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.w,
                    ),
                    itemCount: (assets.length - 1).clamp(0, 4),
                    itemBuilder: (context, i) {
                      final asset = assets[i + 1];
                      final isSelected = groupState.selectedIds.contains(asset.id);
                      return _buildSmallThumbnail(ref, groupIndex, asset, isSelected);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeThumbnail(AssetEntity asset, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: const Color(0xFFEDF2F7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Thumbnail(asset: asset),
          // "Best" badge
          Positioned(
            top: 12.h,
            left: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Best',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Selection indicator (circle)
          Positioned(
            bottom: 12.h,
            right: 12.w,
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CupertinoColors.white, width: 2.w),
                color: isSelected
                    ? const Color(0xFF4299E1)
                    : CupertinoColors.black.withValues(alpha: 0.2),
              ),
              child: isSelected
                  ? Icon(CupertinoIcons.checkmark_alt,
                      size: 16.sp, color: CupertinoColors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallThumbnail(WidgetRef ref, int groupIndex, AssetEntity asset, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(duplicateProvider.notifier).toggleSelection(groupIndex, asset.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: const Color(0xFFEDF2F7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumbnail(asset: asset),
            // Selection indicator
            Positioned(
              bottom: 6.h,
              right: 6.w,
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF4299E1)
                      : CupertinoColors.black.withValues(alpha: 0.2),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                          width: 1.5.w),
                ),
                child: isSelected
                    ? Icon(CupertinoIcons.checkmark_alt,
                        size: 14.sp, color: CupertinoColors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, int count, int size, bool isDeleting) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 15.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count photos',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatSize(size),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38B2AC), // Teal color from design
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: count > 0 && !isDeleting ? () => _confirmDelete(context, ref) : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: count > 0
                    ? const LinearGradient(
                        colors: [Color(0xFF4299E1), Color(0xFF667EEA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: count > 0 ? null : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: count > 0
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4299E1).withValues(alpha: 0.3),
                          blurRadius: 12.r,
                          offset: Offset(0, 6.h),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'Delete photos',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete duplicates?'),
        content: const Text('Selected photos will be moved to Trash.'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              // Calculate potential stats before deletion attempt
              final state = ref.read(duplicateProvider);
              int totalSelectedCount = 0;
              double totalSelectedSize = 0;
              for (var groupState in state.groups) {
                if (groupState.selectedIds.isNotEmpty) {
                  totalSelectedCount += groupState.selectedIds.length;
                  totalSelectedSize += (groupState.group.totalSize / groupState.group.assets.length) * groupState.selectedIds.length;
                }
              }
              final sizeSavedGB = totalSelectedSize / (1024.0 * 1024.0 * 1024.0);

              final navigator = Navigator.of(context);
              Navigator.pop(context); // Close custom dialog immediately
              final deletedIds = await ref.read(duplicateProvider.notifier).deleteSelected();
              
              if (deletedIds.isNotEmpty) {
                final actualSizeGB = sizeSavedGB * (deletedIds.length / totalSelectedCount);
                
                navigator.pushAndRemoveUntil(
                  CupertinoPageRoute(
                    builder: (_) => SuccessScreen(
                      deletedCount: deletedIds.length,
                      sizeSavedGB: actualSizeGB,
                      category: 'duplicates',
                    ),
                  ),
                  (route) => route.isFirst,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
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
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: const Color(0xFFF7FAFC));
      },
    );
  }
}
