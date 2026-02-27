import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/data/photo_repository.dart';

class GalleryState {
  final List<AssetEntity> assets;
  final bool isLoading;

  GalleryState({this.assets = const [], this.isLoading = false});

  GalleryState copyWith({List<AssetEntity>? assets, bool? isLoading}) {
    return GalleryState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FavoriteIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void updateIds(Set<String> value) => state = value;
}
final favoriteIdsProvider = NotifierProvider<FavoriteIdsNotifier, Set<String>>(FavoriteIdsNotifier.new);

class HiddenIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void updateIds(Set<String> value) => state = value;
}
final hiddenIdsProvider = NotifierProvider<HiddenIdsNotifier, Set<String>>(HiddenIdsNotifier.new);

final favoriteProvider = NotifierProvider<FavoriteNotifier, GalleryState>(FavoriteNotifier.new);

class FavoriteNotifier extends Notifier<GalleryState> {
  late final PhotoRepository _repository;

  @override
  GalleryState build() {
    _repository = ref.watch(photoRepositoryProvider);
    // Auto-reload when IDs change
    ref.listen(favoriteIdsProvider, (previous, next) {
      load();
    });
    
    // Initial load
    Future.microtask(() => _initializeIds());
    return GalleryState();
  }

  Future<void> _initializeIds() async {
    final favorites = await _repository.getFavorites();
    final ids = favorites.map((a) => a.id).toSet();
    ref.read(favoriteIdsProvider.notifier).state = ids;
    state = state.copyWith(assets: favorites, isLoading: false);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final assets = await _repository.getFavorites();
    state = state.copyWith(assets: assets, isLoading: false);
  }
}

final hiddenProvider = NotifierProvider<HiddenNotifier, GalleryState>(HiddenNotifier.new);

class HiddenNotifier extends Notifier<GalleryState> {
  late final PhotoRepository _repository;

  @override
  GalleryState build() {
    _repository = ref.watch(photoRepositoryProvider);
    // Auto-reload when IDs change
    ref.listen(hiddenIdsProvider, (previous, next) {
      load();
    });

    // Initial load
    Future.microtask(() => _initializeIds());
    return GalleryState();
  }

  Future<void> _initializeIds() async {
    final hidden = await _repository.getHidden();
    final ids = hidden.map((a) => a.id).toSet();
    ref.read(hiddenIdsProvider.notifier).state = ids;
    state = state.copyWith(assets: hidden, isLoading: false);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final assets = await _repository.getHidden();
    state = state.copyWith(assets: assets, isLoading: false);
  }
}
