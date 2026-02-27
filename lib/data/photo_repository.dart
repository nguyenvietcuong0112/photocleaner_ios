import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class MonthlyGroup {
  final int year;
  final int month;
  final int count;
  final AssetEntity coverAsset;

  MonthlyGroup({
    required this.year,
    required this.month,
    required this.count,
    required this.coverAsset,
  });
}

class PhotoStats {
  final int totalPhotos;
  final int totalVideos;
  final int selfies;
  final int screenshots;
  final int other;
  final double usedStorageGB;
  final double totalStorageGB;

  const PhotoStats({
    this.totalPhotos = 0,
    this.totalVideos = 0,
    this.selfies = 0,
    this.screenshots = 0,
    this.other = 0,
    this.usedStorageGB = 0,
    this.totalStorageGB = 128,
  });
}

class DuplicateGroup {
  final List<AssetEntity> assets;
  final int totalSize;

  DuplicateGroup({
    required this.assets,
    required this.totalSize,
  });
}

abstract class PhotoRepository {
  Future<bool> requestPermission();
  Future<List<AssetEntity>> getRecents({int limit = 100});
  Future<List<AssetEntity>> getOnThisDay();
  Future<List<AssetEntity>> getMonthly(int year, int month);
  Future<List<AssetEntity>> getRandom({int limit = 50});
  Future<List<String>> deleteAssets(List<AssetEntity> assets);
  Future<Set<DateTime>> getPhotoDays(DateTime month);
  Future<PhotoStats> getPhotoStats();
  Future<List<MonthlyGroup>> getMonthlyGroups();
  Future<List<DuplicateGroup>> getDuplicateGroups();
  
  // New features
  Future<void> toggleFavorite(AssetEntity asset);
  Future<void> toggleHidden(AssetEntity asset);
  Future<List<AssetEntity>> getFavorites();
  Future<List<AssetEntity>> getHidden();
  bool isHidden(String id);
}

class PhotoRepositoryImpl implements PhotoRepository {
  static const _storageChannel = MethodChannel('com.phonecleaner.app/storage');

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
  Future<List<String>> deleteAssets(List<AssetEntity> assets) async {
    final List<String> ids = assets.map((e) => e.id).toList();
    return await PhotoManager.editor.deleteWithIds(ids);
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

  @override
  Future<PhotoStats> getPhotoStats() async {
    try {
      final imagePaths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
      final videoPaths = await PhotoManager.getAssetPathList(type: RequestType.video, onlyAll: true);

      int totalPhotos = 0;
      if (imagePaths.isNotEmpty) {
        totalPhotos = await imagePaths.first.assetCountAsync;
      }
      
      if (totalPhotos == 0) {
        final allImagePaths = await PhotoManager.getAssetPathList(type: RequestType.image);
        if (allImagePaths.isNotEmpty) {
          final allAlbum = allImagePaths.firstWhere((p) => p.isAll, orElse: () => allImagePaths.first);
          totalPhotos = await allAlbum.assetCountAsync;
        }
      }

      int totalVideos = 0;
      if (videoPaths.isNotEmpty) {
        totalVideos = await videoPaths.first.assetCountAsync;
      }
      
      if (totalVideos == 0) {
        final allVideoPaths = await PhotoManager.getAssetPathList(type: RequestType.video);
        if (allVideoPaths.isNotEmpty) {
          final allAlbum = allVideoPaths.firstWhere((p) => p.isAll, orElse: () => allVideoPaths.first);
          totalVideos = await allAlbum.assetCountAsync;
        }
      }

      int screenshots = 0;
      int selfies = 0;
      try {
        final allPaths = await PhotoManager.getAssetPathList(type: RequestType.image);
        for (final path in allPaths) {
          final name = path.name.toLowerCase();
          if (name.contains('screenshot')) {
            screenshots += await path.assetCountAsync;
          } else if (name.contains('selfie')) {
            selfies += await path.assetCountAsync;
          }
        }
      } catch (_) {
        screenshots = (totalPhotos * 0.1).round();
        selfies = (totalPhotos * 0.1).round();
      }

      double usedGB = 0;
      try {
        usedGB = await _calculateSafeStorage(
          imagePaths.isNotEmpty ? imagePaths.first : null,
          totalPhotos,
          videoPaths.isNotEmpty ? videoPaths.first : null,
          totalVideos,
        );
      } catch (_) {
        usedGB = (totalPhotos * 3.0 + totalVideos * 50.0) / 1024.0;
      }

      final other = totalPhotos - screenshots - selfies;

      double totalMachineStorageGB = 128;
      try {
        final int? totalBytes = await _storageChannel.invokeMethod<int>('getTotalDiskSpace');
        if (totalBytes != null && totalBytes > 0) {
          totalMachineStorageGB = totalBytes / (1024 * 1024 * 1024);
          
          // Round to common capacities for better display (e.g. 128, 256, 512)
          if (totalMachineStorageGB > 480) {
            totalMachineStorageGB = 512;
          } else if (totalMachineStorageGB > 240) {
            totalMachineStorageGB = 256;
          } else if (totalMachineStorageGB > 120) {
            totalMachineStorageGB = 128;
          } else if (totalMachineStorageGB > 60) {
            totalMachineStorageGB = 64;
          } else if (totalMachineStorageGB > 28) {
            totalMachineStorageGB = 32;
          }
        }
      } catch (_) {
        // Silently fail and use default
      }

      return PhotoStats(
        totalPhotos: totalPhotos,
        totalVideos: totalVideos,
        selfies: selfies,
        screenshots: screenshots,
        other: other > 0 ? other : 0,
        usedStorageGB: usedGB,
        totalStorageGB: totalMachineStorageGB,
      );
    } catch (e) {
      return const PhotoStats();
    }
  }

  Future<double> _calculateSafeStorage(
    AssetPathEntity? imagePath,
    int imageCount,
    AssetPathEntity? videoPath,
    int videoCount,
  ) async {
    double totalBytes = 0;

    if (imagePath != null && imageCount > 0) {
      final sampleCount = imageCount > 10 ? 10 : imageCount;
      final assets = await imagePath.getAssetListRange(start: 0, end: sampleCount);
      double totalSampleSize = 0;
      int successCount = 0;
      
      for (final asset in assets) {
        try {
          final file = await asset.file.timeout(const Duration(milliseconds: 500));
          if (file != null) {
            totalSampleSize += await file.length();
            successCount++;
          }
        } catch (_) {}
      }
      
      if (successCount > 0) {
        totalBytes += (totalSampleSize / successCount) * imageCount;
      } else {
        totalBytes += imageCount * 3.0 * 1024 * 1024;
      }
    }

    if (videoPath != null && videoCount > 0) {
      final sampleCount = videoCount > 3 ? 3 : videoCount;
      final assets = await videoPath.getAssetListRange(start: 0, end: sampleCount);
      double totalSampleSize = 0;
      int successCount = 0;
      
      for (final asset in assets) {
        try {
          final file = await asset.file.timeout(const Duration(milliseconds: 1000));
          if (file != null) {
            totalSampleSize += await file.length();
            successCount++;
          }
        } catch (_) {}
      }
      
      if (successCount > 0) {
        totalBytes += (totalSampleSize / successCount) * videoCount;
      } else {
        totalBytes += videoCount * 50.0 * 1024 * 1024;
      }
    }

    return totalBytes / (1024 * 1024 * 1024);
  }

  @override
  Future<List<MonthlyGroup>> getMonthlyGroups() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return [];

    final totalCount = await paths.first.assetCountAsync;
    final allAssets = await paths.first.getAssetListRange(start: 0, end: totalCount > 2000 ? 2000 : totalCount);

    final Map<String, List<AssetEntity>> grouped = {};
    for (final asset in allAssets) {
      final date = asset.createDateTime;
      final key = '${date.year}_${date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(asset);
    }

    final groups = grouped.entries.map((entry) {
      final parts = entry.key.split('_');
      return MonthlyGroup(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        count: entry.value.length,
        coverAsset: entry.value.first,
      );
    }).toList();

    groups.sort((a, b) {
      final yearCmp = b.year.compareTo(a.year);
      if (yearCmp != 0) return yearCmp;
      return b.month.compareTo(a.month);
    });

    return groups;
  }

  @override
  Future<List<DuplicateGroup>> getDuplicateGroups() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return [];

    final totalCount = await paths.first.assetCountAsync;
    final assets = await paths.first.getAssetListRange(start: 0, end: totalCount > 2000 ? 2000 : totalCount);

    final Map<String, List<AssetEntity>> potentialDuplicates = {};
    
    for (final asset in assets) {
      try {
        final file = await asset.file.timeout(const Duration(milliseconds: 500));
        if (file == null) continue;
        
        final size = await file.length();
        final key = '${size}_${asset.width}_${asset.height}';
        
        potentialDuplicates.putIfAbsent(key, () => []).add(asset);
      } catch (_) {}
    }

    final List<Future<DuplicateGroup>> duplicateGroupsFutures = potentialDuplicates.values
        .where((group) => group.length > 1)
        .map((group) async {
          int totalSize = 0;
          for (final asset in group) {
            try {
              final file = await asset.file.timeout(const Duration(milliseconds: 500));
              if (file != null) totalSize += await file.length();
            } catch (_) {}
          }
          return DuplicateGroup(assets: group, totalSize: totalSize);
        })
        .toList();

    return Future.wait(duplicateGroupsFutures);
  }

  final Set<String> _hiddenIds = {};

  @override
  Future<void> toggleFavorite(AssetEntity asset) async {
    // For iOS, must use the platform-specific darwin editor
    await PhotoManager.editor.darwin.favoriteAsset(entity: asset, favorite: !asset.isFavorite);
  }

  @override
  Future<void> toggleHidden(AssetEntity asset) async {
    if (_hiddenIds.contains(asset.id)) {
      _hiddenIds.remove(asset.id);
    } else {
      _hiddenIds.add(asset.id);
    }
  }

  @override
  bool isHidden(String id) => _hiddenIds.contains(id);

  @override
  Future<List<AssetEntity>> getFavorites() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return [];
    
    final totalCount = await paths.first.assetCountAsync;
    final allAssets = await paths.first.getAssetListRange(start: 0, end: totalCount > 5000 ? 5000 : totalCount);
    return allAssets.where((a) => a.isFavorite).toList();
  }

  @override
  Future<List<AssetEntity>> getHidden() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (paths.isEmpty) return [];
    
    final totalCount = await paths.first.assetCountAsync;
    final allAssets = await paths.first.getAssetListRange(start: 0, end: totalCount > 5000 ? 5000 : totalCount);
    return allAssets.where((a) => _hiddenIds.contains(a.id)).toList();
  }
}

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl();
});
