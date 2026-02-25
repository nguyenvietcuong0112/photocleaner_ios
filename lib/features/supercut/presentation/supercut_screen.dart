import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/supercut/presentation/supercut_provider.dart';

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
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(CupertinoIcons.play_rectangle_fill, size: 50, color: CupertinoColors.activeBlue),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Kept Photos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${selectedPhotos.length} photos selected', style: const TextStyle(color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 24),
                  _buildMusicSelector(),
                ],
              ),
            ),
          ),
          if (selectedPhotos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Photos you "KEEP" during cleaning\nwill appear here for selection.', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
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
              padding: const EdgeInsets.all(40),
              child: _isExporting
                  ? const Column(
                      children: [
                        CupertinoActivityIndicator(radius: 15),
                        SizedBox(height: 10),
                        Text('Generating Supercut...', style: TextStyle(fontSize: 14)),
                      ],
                    )
                  : CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.music_note_2, color: CupertinoColors.activeBlue, size: 20),
          const SizedBox(width: 12),
          const Text('Background Music', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showMusicPicker,
            child: Row(
              children: [
                Text(_selectedMusic, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                const Icon(CupertinoIcons.chevron_up_chevron_down, size: 14, color: CupertinoColors.systemGrey),
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
        height: 250,
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
                itemExtent: 40,
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
        borderRadius: BorderRadius.circular(8),
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
