import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/features/clean/presentation/providers/swipe_monthly_provider.dart';
import 'package:phonecleaner/features/home/presentation/providers/home_provider.dart';
import 'package:phonecleaner/features/stats/presentation/providers/stats_provider.dart';

class DuplicateGroupState {
  final DuplicateGroup group;
  final Set<String> selectedIds;

  DuplicateGroupState({
    required this.group,
    Set<String>? selectedIds,
  }) : selectedIds = selectedIds ?? {
    if (group.assets.length > 1)
      ...group.assets.skip(1).map((a) => a.id),
  };

  DuplicateGroupState copyWith({
    Set<String>? selectedIds,
  }) {
    return DuplicateGroupState(
      group: group,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class DuplicateState {
  final List<DuplicateGroupState> groups;
  final bool isLoading;
  final bool isDeleting;
  final int totalSelectedSize;
  final int totalSelectedCount;
  final int scannedCount;
  final int totalToScan;

  DuplicateState({
    required this.groups,
    this.isLoading = false,
    this.isDeleting = false,
    this.totalSelectedSize = 0,
    this.totalSelectedCount = 0,
    this.scannedCount = 0,
    this.totalToScan = 0,
  });

  DuplicateState copyWith({
    List<DuplicateGroupState>? groups,
    bool? isLoading,
    bool? isDeleting,
    int? totalSelectedSize,
    int? totalSelectedCount,
    int? scannedCount,
    int? totalToScan,
  }) {
    return DuplicateState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      totalSelectedSize: totalSelectedSize ?? this.totalSelectedSize,
      totalSelectedCount: totalSelectedCount ?? this.totalSelectedCount,
      scannedCount: scannedCount ?? this.scannedCount,
      totalToScan: totalToScan ?? this.totalToScan,
    );
  }
}

final duplicateProvider = NotifierProvider<DuplicateNotifier, DuplicateState>(DuplicateNotifier.new);

class DuplicateNotifier extends Notifier<DuplicateState> {
  late final PhotoRepository _repository;
  
  // Buffers for Zero-Jank throttling
  List<DuplicateGroupState> _pendingGroups = [];
  int _scannedAccumulator = 0;
  DateTime _lastUpdate = DateTime.now();

  @override
  DuplicateState build() {
    _repository = ref.watch(photoRepositoryProvider);
    // Trigger initial load
    Future.microtask(() => loadDuplicates());
    return DuplicateState(groups: []);
  }

  Future<void> loadDuplicates() async {
    state = state.copyWith(
      isLoading: true, 
      groups: [], 
      scannedCount: 0, 
      totalToScan: 5000
    );

    // Get total count once for progress bar
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isNotEmpty) {
      final total = await paths.first.assetCountAsync;
      state = state.copyWith(totalToScan: total > 5000 ? 5000 : total);
    }

    _repository.getDuplicateGroupsStream().listen(
      (newGroups) {
        _pendingGroups.addAll(newGroups.map((g) => DuplicateGroupState(group: g)));
        _scannedAccumulator += 200; // Chunk size is 200
        
        final now = DateTime.now();
        // Update UI every 1s OR if it's the very first result
        if (now.difference(_lastUpdate) > const Duration(seconds: 1) || state.groups.isEmpty) {
          _applyPending();
        }
      },
      onDone: () {
        _applyPending(); // Flush remaining
        state = state.copyWith(
          isLoading: false,
          scannedCount: state.totalToScan,
        );
      },
      onError: (_) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  void _applyPending() {
    if (_pendingGroups.isEmpty && _scannedAccumulator == 0) {
      _lastUpdate = DateTime.now();
      return;
    }
    
    final currentGroups = [...state.groups];
    state = state.copyWith(
      groups: [...currentGroups, ..._pendingGroups],
      scannedCount: (state.scannedCount + _scannedAccumulator).clamp(0, state.totalToScan),
    );
    
    _pendingGroups = [];
    _scannedAccumulator = 0;
    _lastUpdate = DateTime.now();
    _updateSelectedTotals();
  }

  void _updateSelectedTotals() {
    int totalSize = 0;
    int totalCount = 0;
    
    for (var groupState in state.groups) {
      if (groupState.selectedIds.isNotEmpty) {
        totalCount += groupState.selectedIds.length;
        // Map asset IDs to their respective sizes stored in DuplicateGroup
        for (int i = 0; i < groupState.group.assets.length; i++) {
          if (groupState.selectedIds.contains(groupState.group.assets[i].id)) {
            totalSize += groupState.group.sizes[i];
          }
        }
      }
    }
    
    state = state.copyWith(
      totalSelectedSize: totalSize,
      totalSelectedCount: totalCount,
    );
  }

  void toggleSelection(int groupIndex, String assetId) {
    final groups = [...state.groups];
    final groupState = groups[groupIndex];
    final newSelected = Set<String>.from(groupState.selectedIds);
    
    if (newSelected.contains(assetId)) {
      newSelected.remove(assetId);
    } else {
      newSelected.add(assetId);
    }
    
    groups[groupIndex] = groupState.copyWith(selectedIds: newSelected);
    state = state.copyWith(groups: groups);
    _updateSelectedTotals();
  }

  void selectAll(int groupIndex) {
    final groups = [...state.groups];
    final groupState = groups[groupIndex];
    // Select all but the first one (following "Best" logic)
    final newSelected = groupState.group.assets.skip(1).map((a) => a.id).toSet();
    
    groups[groupIndex] = groupState.copyWith(selectedIds: newSelected);
    state = state.copyWith(groups: groups);
    _updateSelectedTotals();
  }

  void deselectAll(int groupIndex) {
    final groups = [...state.groups];
    final groupState = groups[groupIndex];
    
    groups[groupIndex] = groupState.copyWith(selectedIds: const {});
    state = state.copyWith(groups: groups);
    _updateSelectedTotals();
  }

  Future<List<String>> deleteSelected() async {
    state = state.copyWith(isDeleting: true);
    
    List<AssetEntity> toDelete = [];
    double totalSize = 0;
    
    for (var groupState in state.groups) {
      if (groupState.selectedIds.isNotEmpty) {
        final assets = groupState.group.assets.where((a) => groupState.selectedIds.contains(a.id)).toList();
        toDelete.addAll(assets);
        // Use exact sizes from the repository result
        for (int i = 0; i < groupState.group.assets.length; i++) {
          if (groupState.selectedIds.contains(groupState.group.assets[i].id)) {
            totalSize += groupState.group.sizes[i];
          }
        }
      }
    }

    List<String> deletedIds = [];
    if (toDelete.isNotEmpty) {
      deletedIds = await _repository.deleteAssets(toDelete);
      if (deletedIds.isNotEmpty) {
        final actualSizeGB = (totalSize / (1024.0 * 1024.0 * 1024.0)) * (deletedIds.length / toDelete.length);
        await ref.read(statsProvider.notifier).addSession(deletedIds.length, actualSizeGB);
      }
    }

    await loadDuplicates();
    ref.invalidate(homeStatsProvider);
    ref.invalidate(monthlyGroupsProvider);
    state = state.copyWith(isDeleting: false);
    return deletedIds;
  }
}
