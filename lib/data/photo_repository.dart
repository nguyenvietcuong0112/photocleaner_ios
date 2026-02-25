import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PhotoRepository {
  Future<bool> requestPermission();
  Future<List<AssetEntity>> getRecents({int limit = 100});
  Future<List<AssetEntity>> getOnThisDay();
  Future<List<AssetEntity>> getMonthly(int year, int month);
  Future<List<AssetEntity>> getRandom({int limit = 50});
  Future<void> deleteAssets(List<AssetEntity> assets);
  Future<Set<DateTime>> getPhotoDays(DateTime month);
}

class PhotoRepositoryImpl implements PhotoRepository {
  @override
  Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(),
    );
    return ps.isAuth;
  }

  @override
  Future<List<AssetEntity>> getRecents({int limit = 100}) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return [];
    return paths.first.getAssetListRange(start: 0, end: limit);
  }

  @override
  Future<List<AssetEntity>> getOnThisDay() async {
    final now = DateTime.now();
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return [];
    
    final allAssets = await paths.first.getAssetListRange(start: 0, end: 1000);
    return allAssets.where((asset) {
      final date = asset.createDateTime;
      return date.month == now.month && date.day == now.day && date.year != now.year;
    }).toList();
  }

  @override
  Future<List<AssetEntity>> getMonthly(int year, int month) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return [];

    // Client-side filtering as 3.x FilterOptionGroup date syntax varies by sub-version
    final allAssets = await paths.first.getAssetListRange(start: 0, end: 1000);
    return allAssets.where((asset) {
      final date = asset.createDateTime;
      return date.year == year && date.month == month;
    }).toList();
  }

  @override
  Future<List<AssetEntity>> getRandom({int limit = 50}) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return [];
    
    final totalCount = await paths.first.assetCountAsync;
    if (totalCount <= limit) return paths.first.getAssetListRange(start: 0, end: totalCount);

    final random = DateTime.now().millisecond;
    final startOffset = (random % (totalCount - limit)).clamp(0, totalCount - limit);
    return paths.first.getAssetListRange(start: startOffset, end: startOffset + limit);
  }

  @override
  Future<void> deleteAssets(List<AssetEntity> assets) async {
    final List<String> ids = assets.map((e) => e.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
  }

  @override
  Future<Set<DateTime>> getPhotoDays(DateTime month) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return {};

    final allAssets = await paths.first.getAssetListRange(start: 0, end: 1000);
    return allAssets
        .where((a) => a.createDateTime.year == month.year && a.createDateTime.month == month.month)
        .map((a) {
          final d = a.createDateTime;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();
  }
}

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl();
});
