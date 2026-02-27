import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/features/clean/presentation/providers/gallery_provider.dart';
import 'package:phonecleaner/features/clean/presentation/providers/swipe_monthly_provider.dart';
import 'package:phonecleaner/features/home/presentation/providers/home_provider.dart';
import 'package:phonecleaner/features/stats/presentation/providers/stats_provider.dart';
import 'package:phonecleaner/features/supercut/presentation/providers/supercut_provider.dart';

class SwipeAction {
  final AssetEntity asset;
  final bool kept;
  SwipeAction(this.asset, this.kept);
}

class SwipeState {
  final List<AssetEntity> photos;
  final List<AssetEntity> keptPhotos;
  final List<AssetEntity> deletedPhotos;
  final List<SwipeAction> history;
  final bool isLoading;
  final bool isDeleting;
  final bool isFinished;

  const SwipeState({
    required this.photos,
    required this.keptPhotos,
    required this.deletedPhotos,
    this.history = const [],
    this.isLoading = false,
    this.isDeleting = false,
    this.isFinished = false,
  });

  SwipeState copyWith({
    List<AssetEntity>? photos,
    List<AssetEntity>? keptPhotos,
    List<AssetEntity>? deletedPhotos,
    List<SwipeAction>? history,
    bool? isLoading,
    bool? isDeleting,
    bool? isFinished,
  }) {
    return SwipeState(
      photos: photos ?? this.photos,
      keptPhotos: keptPhotos ?? this.keptPhotos,
      deletedPhotos: deletedPhotos ?? this.deletedPhotos,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

final swipeProvider = NotifierProvider.family<SwipeNotifier, SwipeState, String>(SwipeNotifier.new);

class SwipeNotifier extends Notifier<SwipeState> {
  final String category;
  SwipeNotifier(this.category);

  late final PhotoRepository _repository;
  late final StatsNotifier _statsNotifier;
  late final SupercutNotifier _supercutNotifier;

  @override
  SwipeState build() {
    _repository = ref.watch(photoRepositoryProvider);
    _statsNotifier = ref.watch(statsProvider.notifier);
    _supercutNotifier = ref.watch(supercutProvider.notifier);
    return const SwipeState(photos: [], keptPhotos: [], deletedPhotos: []);
  }

  Future<void> loadPhotos(String category) async {
    state = state.copyWith(isLoading: true);
    
    List<AssetEntity> fetched;

    // Handle Monthly_YYYY_MM format
    if (category.startsWith('Monthly_')) {
      final parts = category.split('_');
      if (parts.length == 3) {
        final year = int.tryParse(parts[1]) ?? DateTime.now().year;
        final month = int.tryParse(parts[2]) ?? DateTime.now().month;
        fetched = await _repository.getMonthly(year, month);
      } else {
        final now = DateTime.now();
        fetched = await _repository.getMonthly(now.year, now.month);
      }
    } else {
      switch (category) {
        case 'Recents':
          fetched = await _repository.getRecents();
          break;
        case 'On This Day':
          fetched = await _repository.getOnThisDay();
          break;
        case 'Monthly':
          final now = DateTime.now();
          fetched = await _repository.getMonthly(now.year, now.month);
          break;
        case 'Random':
          fetched = await _repository.getRandom();
          break;
        default:
          fetched = await _repository.getRecents();
      }
    }
    
    // Ensure unique photos by ID to prevent duplication issues
    final seenIds = <String>{};
    final uniqueFetched = fetched.where((p) => seenIds.add(p.id)).toList();
    
    state = state.copyWith(
      photos: uniqueFetched, 
      isLoading: false
    );
  }

  void keepPhoto(AssetEntity asset) {
    state = state.copyWith(
      photos: state.photos.where((p) => p.id != asset.id).toList(),
      keptPhotos: [...state.keptPhotos, asset],
      history: [...state.history, SwipeAction(asset, true)],
      isFinished: state.photos.length <= 1,
    );
    _supercutNotifier.toggleSelection(asset);
  }

  void deletePhoto(AssetEntity asset) {
    state = state.copyWith(
      photos: state.photos.where((p) => p.id != asset.id).toList(),
      deletedPhotos: [...state.deletedPhotos, asset],
      history: [...state.history, SwipeAction(asset, false)],
      isFinished: state.photos.length <= 1,
    );
  }

  Future<void> toggleFavorite(AssetEntity asset) async {
    await _repository.toggleFavorite(asset);
    
    final ids = ref.read(favoriteIdsProvider);
    final newIds = Set<String>.from(ids);
    if (newIds.contains(asset.id)) {
      newIds.remove(asset.id);
    } else {
      newIds.add(asset.id);
    }
    ref.read(favoriteIdsProvider.notifier).updateIds(newIds);
  }

  void toggleHidden(AssetEntity asset) {
    _repository.toggleHidden(asset);
    
    final ids = ref.read(hiddenIdsProvider);
    final newIds = Set<String>.from(ids);
    if (newIds.contains(asset.id)) {
      newIds.remove(asset.id);
    } else {
      newIds.add(asset.id);
    }
    ref.read(hiddenIdsProvider.notifier).updateIds(newIds);
  }

  void undo() {
    if (state.history.isEmpty) return;

    final lastAction = state.history.last;
    final newHistory = state.history.sublist(0, state.history.length - 1);

    if (lastAction.kept) {
      state = state.copyWith(
        photos: [lastAction.asset, ...state.photos],
        keptPhotos: state.keptPhotos.where((p) => p.id != lastAction.asset.id).toList(),
        history: newHistory,
        isFinished: false,
      );
      _supercutNotifier.toggleSelection(lastAction.asset);
    } else {
      state = state.copyWith(
        photos: [lastAction.asset, ...state.photos],
        deletedPhotos: state.deletedPhotos.where((p) => p.id != lastAction.asset.id).toList(),
        history: newHistory,
        isFinished: false,
      );
    }
  }

  void toggleDeletion(AssetEntity asset) {
    // Search by ID to ensure we handle potential duplicates gracefully
    final isMarkedForDeletion = state.deletedPhotos.any((p) => p.id == asset.id);
    
    if (isMarkedForDeletion) {
      // Move from deleted to kept
      state = state.copyWith(
        deletedPhotos: state.deletedPhotos.where((p) => p.id != asset.id).toList(),
        keptPhotos: [...state.keptPhotos.where((p) => p.id != asset.id), asset],
      );
      _supercutNotifier.toggleSelection(asset);
    } else {
      // Move from kept to deleted
      state = state.copyWith(
        keptPhotos: state.keptPhotos.where((p) => p.id != asset.id).toList(),
        deletedPhotos: [...state.deletedPhotos.where((p) => p.id != asset.id), asset],
      );
      _supercutNotifier.toggleSelection(asset);
    }
  }

  Future<List<String>> confirmDeletion() async {
    state = state.copyWith(isDeleting: true);
    final deletedIds = await _repository.deleteAssets(state.deletedPhotos);
    if (deletedIds.isEmpty) {
      state = state.copyWith(isDeleting: false);
      return [];
    }

    final keptCount = state.keptPhotos.length;
    await _statsNotifier.addSession(
      deletedIds.length, 
      (deletedIds.length * 3.0) / 1024.0,
      keptCount: keptCount,
    );
    ref.invalidate(homeStatsProvider);
    ref.invalidate(monthlyGroupsProvider);
    
    state = state.copyWith(deletedPhotos: [], history: [], isDeleting: false);
    return deletedIds;
  }
}
