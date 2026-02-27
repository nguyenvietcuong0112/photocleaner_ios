import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

final permissionProvider = NotifierProvider<PermissionNotifier, PermissionState>(() {
  return PermissionNotifier();
});

class PermissionNotifier extends Notifier<PermissionState> {
  @override
  PermissionState build() {
    _init();
    return PermissionState.notDetermined;
  }

  Future<void> _init() async {
    await checkPermission();
  }

  Future<void> checkPermission() async {
    final ps = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    state = ps;
  }

  Future<void> requestPermission() async {
    final ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(),
    );
    state = ps;
  }
}
