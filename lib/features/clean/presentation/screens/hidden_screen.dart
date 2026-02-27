import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/features/clean/presentation/providers/gallery_provider.dart';

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});

  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hiddenProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white.withValues(alpha: 0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Color(0xFF2D3748)),
          onPressed: () {
            if (_selectedIndex != null) {
              setState(() => _selectedIndex = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        middle: const Text(
          'Hidden',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: _selectedIndex != null 
          ? Text('${_selectedIndex! + 1}/${state.assets.length}', 
              style: const TextStyle(color: Color(0xFF718096), fontSize: 16))
          : null,
      ),
      child: SafeArea(
        child: state.isLoading 
          ? const Center(child: CupertinoActivityIndicator())
          : state.assets.isEmpty
            ? _buildEmptyState()
            : _selectedIndex != null
              ? _buildDetailView(state.assets)
              : _buildGridView(state.assets),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No hidden photos yet', style: TextStyle(color: CupertinoColors.systemGrey)),
    );
  }

  Widget _buildGridView(List<AssetEntity> assets) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: _Thumbnail(asset: assets[index]),
        );
      },
    );
  }

  Widget _buildDetailView(List<AssetEntity> assets) {
    final asset = assets[_selectedIndex!];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: _Thumbnail(asset: asset, highRes: true),
          ),
        ),
        // Bottom controls
        Container(
          padding: const EdgeInsets.only(bottom: 40, top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ArrowButton(
                icon: CupertinoIcons.chevron_left,
                onPressed: _selectedIndex! > 0 
                  ? () => setState(() => _selectedIndex = _selectedIndex! - 1)
                  : null,
              ),
              _ActionButton(
                icon: CupertinoIcons.eye_fill,
                color: const Color(0xFFFFA000),
                onPressed: () async {
                  final repo = ref.read(photoRepositoryProvider);
                  await repo.toggleHidden(asset);
                  final ids = ref.read(hiddenIdsProvider);
                  final newIds = Set<String>.from(ids);
                  if (newIds.contains(asset.id)) {
                    newIds.remove(asset.id);
                  } else {
                    newIds.add(asset.id);
                  }
                  ref.read(hiddenIdsProvider.notifier).updateIds(newIds);

                  if (_selectedIndex! >= assets.length - 1) {
                    setState(() => _selectedIndex = assets.length <= 1 ? null : assets.length - 2);
                  }
                  if (assets.length <= 1) setState(() => _selectedIndex = null);
                },
              ),
              _ArrowButton(
                icon: CupertinoIcons.chevron_right,
                onPressed: _selectedIndex! < assets.length - 1 
                  ? () => setState(() => _selectedIndex = _selectedIndex! + 1)
                  : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final AssetEntity asset;
  final bool highRes;
  const _Thumbnail({required this.asset, this.highRes = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: asset.thumbnailDataWithSize(highRes ? const ThumbnailSize(1000, 1500) : const ThumbnailSize(300, 300)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: const Color(0xFFF7FAFC));
      },
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ArrowButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFFFA000), size: 24),
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFF3E0), width: 8),
          color: CupertinoColors.white,
        ),
        child: Center(child: Icon(icon, color: color, size: 40)),
      ),
    );
  }
}
