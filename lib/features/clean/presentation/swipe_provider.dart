import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/features/stats/presentation/stats_provider.dart';
import 'package:phonecleaner/features/supercut/presentation/supercut_provider.dart';

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
  final bool isFinished;

  const SwipeState({
    required this.photos,
    required this.keptPhotos,
    required this.deletedPhotos,
    this.history = const [],
    this.isLoading = false,
    this.isFinished = false,
  });

  SwipeState copyWith({
    List<AssetEntity>? photos,
    List<AssetEntity>? keptPhotos,
    List<AssetEntity>? deletedPhotos,
    List<SwipeAction>? history,
    bool? isLoading,
    bool? isFinished,
  }) {
    return SwipeState(
      photos: photos ?? this.photos,
      keptPhotos: keptPhotos ?? this.keptPhotos,
      deletedPhotos: deletedPhotos ?? this.deletedPhotos,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
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
    if (category.startsWith('On ')) {
       fetched = await _repository.getRecents(limit: 50); 
    } else {
      switch (category) {
        case 'Recents':
          fetched = await _repository.getRecents();
          break;
        case 'On This Day':
          fetched = await _repository.getOnThisDay();
          break;
        case 'Random':
          fetched = await _repository.getRandom();
          break;
        default:
          fetched = await _repository.getRecents();
      }
    }
    
    state = state.copyWith(photos: fetched, isLoading: false);
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

  Future<void> confirmDeletion() async {
    final count = state.deletedPhotos.length;
    final storageGB = (count * 3.0) / 1024.0;
    
    await _repository.deleteAssets(state.deletedPhotos);
    await _statsNotifier.addSession(count, storageGB);
    
    state = state.copyWith(deletedPhotos: [], history: []);
  }
}
