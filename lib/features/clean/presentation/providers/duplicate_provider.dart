import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phonecleaner/data/photo_repository.dart';
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

  DuplicateState({
    required this.groups,
    this.isLoading = false,
    this.isDeleting = false,
  });

  DuplicateState copyWith({
    List<DuplicateGroupState>? groups,
    bool? isLoading,
    bool? isDeleting,
  }) {
    return DuplicateState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

final duplicateProvider = NotifierProvider<DuplicateNotifier, DuplicateState>(DuplicateNotifier.new);

class DuplicateNotifier extends Notifier<DuplicateState> {
  late final PhotoRepository _repository;

  @override
  DuplicateState build() {
    _repository = ref.watch(photoRepositoryProvider);
    // Trigger initial load
    Future.microtask(() => loadDuplicates());
    return DuplicateState(groups: []);
  }

  Future<void> loadDuplicates() async {
    state = state.copyWith(isLoading: true);
    final groups = await _repository.getDuplicateGroups();
    state = state.copyWith(
      groups: groups.map((g) => DuplicateGroupState(group: g)).toList(),
      isLoading: false,
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
  }

  void selectAll(int groupIndex) {
    final groups = [...state.groups];
    final groupState = groups[groupIndex];
    // Select all but the first one (following "Best" logic)
    final newSelected = groupState.group.assets.skip(1).map((a) => a.id).toSet();
    
    groups[groupIndex] = groupState.copyWith(selectedIds: newSelected);
    state = state.copyWith(groups: groups);
  }

  void deselectAll(int groupIndex) {
    final groups = [...state.groups];
    final groupState = groups[groupIndex];
    
    groups[groupIndex] = groupState.copyWith(selectedIds: const {});
    state = state.copyWith(groups: groups);
  }

  Future<void> deleteSelected() async {
    state = state.copyWith(isDeleting: true);
    
    final List<AssetEntity> toDelete = [];
    int totalCount = 0;
    int totalSize = 0;

    for (var groupState in state.groups) {
      for (var asset in groupState.group.assets) {
        if (groupState.selectedIds.contains(asset.id)) {
          toDelete.add(asset);
          totalCount++;
          totalSize += (groupState.group.totalSize / groupState.group.assets.length).floor();
        }
      }
    }

    if (toDelete.isNotEmpty) {
      await _repository.deleteAssets(toDelete);
      final sizeGB = totalSize / (1024.0 * 1024.0 * 1024.0);
      await ref.read(statsProvider.notifier).addSession(totalCount, sizeGB);
    }

    await loadDuplicates();
    ref.invalidate(homeStatsProvider);
    state = state.copyWith(isDeleting: false);
  }
}
