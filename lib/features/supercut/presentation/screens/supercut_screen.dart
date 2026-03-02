import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/supercut/presentation/providers/supercut_provider.dart';

class SupercutScreen extends ConsumerStatefulWidget {
  const SupercutScreen({super.key});

  @override
  ConsumerState<SupercutScreen> createState() => _SupercutScreenState();
}

class _SupercutScreenState extends ConsumerState<SupercutScreen> {
  bool _isExporting = false;
  String _selectedMusic = 'Chill Melodies';

  @override
  Widget build(BuildContext context) {
    final selectedPhotos = ref.watch(supercutProvider);

    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: CustomScrollView(
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Supercut'),
              backgroundColor: CupertinoColors.transparent,
              border: null,
            ),
          SliverPadding(
            padding: EdgeInsets.all(20.w),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(60.r),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                          blurRadius: 20.r,
                        ),
                      ],
                    ),
                    child: Icon(CupertinoIcons.play_rectangle_fill, size: 50.sp, color: CupertinoColors.activeBlue),
                  ),
                  SizedBox(height: 20.h),
                  Text('Select Kept Photos', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text('${selectedPhotos.length} photos selected', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14.sp)),
                  SizedBox(height: 24.h),
                  _buildMusicSelector(),
                ],
              ),
            ),
          ),
          if (selectedPhotos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Photos you "KEEP" during cleaning\nwill appear here for selection.', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16.sp),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asset = selectedPhotos[index];
                    return _PhotoThumbnail(asset: asset);
                  },
                  childCount: selectedPhotos.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40.w),
              child: _isExporting
                  ? Column(
                      children: [
                        const CupertinoActivityIndicator(radius: 15),
                        SizedBox(height: 10.h),
                        Text('Generating Supercut...', style: TextStyle(fontSize: 14.sp)),
                      ],
                    )
                  : CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(16.r),
                      onPressed: selectedPhotos.isEmpty ? null : _startExport,
                      child: const Text('Export Supercut HD'),
                    ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _startExport() async {
    setState(() => _isExporting = true);
    
    // In a real app, this would get the kept photos and run FFmpeg
    // For this demo, we simulate a delay
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() => _isExporting = false);
      _showExportSuccess();
    }
  }

  Widget _buildMusicSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.music_note_2, color: CupertinoColors.activeBlue, size: 20.sp),
          SizedBox(width: 12.w),
          Text('Background Music', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showMusicPicker,
            child: Row(
              children: [
                Text(_selectedMusic, style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14.sp)),
                Icon(CupertinoIcons.chevron_up_chevron_down, size: 14.sp, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMusicPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250.h,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Container(
              color: CupertinoColors.systemGrey6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40.h,
                onSelectedItemChanged: (index) {
                  final tracks = ['Chill Melodies', 'Upbeat Summer', 'Lo-Fi Beats', 'Acoustic Morning'];
                  setState(() => _selectedMusic = tracks[index]);
                },
                children: const [
                  Center(child: Text('Chill Melodies')),
                  Center(child: Text('Upbeat Summer')),
                  Center(child: Text('Lo-Fi Beats')),
                  Center(child: Text('Acoustic Morning')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSuccess() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Complete!'),
        content: const Text('Your Supercut has been saved to your Photos library.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Great'),
            onPressed: () {
              ref.read(supercutProvider.notifier).clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final AssetEntity asset;
  const _PhotoThumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: CupertinoColors.systemGrey6,
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder(
        future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return const Center(child: CupertinoActivityIndicator(radius: 10));
        },
      ),
    );
  }
}
