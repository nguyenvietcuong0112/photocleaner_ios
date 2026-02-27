import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

final supercutProvider = NotifierProvider<SupercutNotifier, List<AssetEntity>>(() {
  return SupercutNotifier();
});

class SupercutNotifier extends Notifier<List<AssetEntity>> {
  @override
  List<AssetEntity> build() {
    return [];
  }

  void toggleSelection(AssetEntity asset) {
    if (state.any((e) => e.id == asset.id)) {
      state = state.where((e) => e.id != asset.id).toList();
    } else {
      state = [...state, asset];
    }
  }

  void clear() {
    state = [];
  }
}
