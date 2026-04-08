import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_hashing/image_hashing.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  final List<int> sizes;
  final int totalSize;
  final Map<String, Uint8List> previewBytes;

  DuplicateGroup({
    required this.assets,
    required this.sizes,
    required this.totalSize,
    Map<String, Uint8List>? previewBytes,
  }) : previewBytes = previewBytes ?? {};
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
  Stream<List<DuplicateGroup>> getDuplicateGroupsStream();
  Future<List<DuplicateGroup>> getDuplicateGroups(); // For backward compatibility if needed
  
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

  // Cache management
  Map<String, dynamic> _hashCache = {};
  bool _cacheLoaded = false;

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'photo_hash_cache.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        _hashCache = json.decode(content);
      }
    } catch (_) {}
    _cacheLoaded = true;
  }

  Future<void> _saveCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'photo_hash_cache.json'));
      await file.writeAsString(json.encode(_hashCache));
    } catch (_) {}
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

      double usedGB = _calculateEstimatedStorage(totalPhotos, totalVideos);

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

  double _calculateEstimatedStorage(int imageCount, int videoCount) {
    // High-performance estimation:
    // Avg Photo: 3.5 MB
    // Avg Video: 45.0 MB
    final double totalMB = (imageCount * 3.5) + (videoCount * 45.0);
    return totalMB / 1024.0;
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
    // Collect all results from the stream for backward compatibility
    final List<DuplicateGroup> all = [];
    await for (final groups in getDuplicateGroupsStream()) {
      all.addAll(groups);
    }
    return all;
  }

  @override
  Stream<List<DuplicateGroup>> getDuplicateGroupsStream() async* {
    await _loadCache();
    
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return;

    final totalCount = await paths.first.assetCountAsync;
    // Increased limit to 5000 photos for progressive scanning
    final maxPhotos = totalCount > 5000 ? 5000 : totalCount;
    
    // Process in chunks of 200 to give immediate feedback
    const int chunkSize = 200;
    
    for (int start = 0; start < maxPhotos; start += chunkSize) {
      final end = (start + chunkSize < maxPhotos) ? start + chunkSize : maxPhotos;
      final assets = await paths.first.getAssetListRange(start: start, end: end);

      // Phase 1: FAST filtering by dimensions
      final Map<String, List<AssetEntity>> dimensionGroups = {};
      for (final asset in assets) {
        final key = '${asset.width}x${asset.height}';
        dimensionGroups.putIfAbsent(key, () => []).add(asset);
      }

      final List<AssetEntity> dimensionCandidates = [];
      for (final group in dimensionGroups.values) {
        if (group.length > 1) {
          dimensionCandidates.addAll(group);
        }
      }

      if (dimensionCandidates.isEmpty) {
        yield [];
        continue;
      }

      // Phase 2: Metadata Blitz - Group by Dimensions + Modified Timestamp
      // (High-confidence fast match to avoid Native File calls)
      final Map<String, List<AssetEntity>> metadataMatchGroups = {};
      for (final asset in dimensionCandidates) {
        final key = '${asset.width}x${asset.height}_${asset.modifiedDateTime.millisecondsSinceEpoch}';
        metadataMatchGroups.putIfAbsent(key, () => []).add(asset);
      }

      final List<AssetEntity> potentialCandidates = [];
      for (final group in metadataMatchGroups.values) {
        if (group.length > 1) {
          potentialCandidates.addAll(group);
        }
      }

      // If no metadata match, we still check those with same dimensions but different dates
      // to be thorough, but we treat metadata matches as priority.
      if (potentialCandidates.isEmpty) {
        potentialCandidates.addAll(dimensionCandidates);
      }

      // Phase 3: Refined filtering by File Size (Pro optimization)
      final Map<String, List<AssetEntity>> sizeGroups = {};
      final Map<String, int> assetSizes = {};

      // STRICT SEQUENTIAL PROCESSING (No Future.wait) to eliminate lag
      for (final asset in potentialCandidates) {
        try {
          final file = await asset.file.timeout(const Duration(milliseconds: 1000));
          if (file != null) {
            final size = await file.length();
            assetSizes[asset.id] = size;
            final key = '${asset.width}x${asset.height}_$size';
            sizeGroups.putIfAbsent(key, () => []).add(asset);
          }
        } catch (_) {}
        // Small delay to let UI breathe between each request
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final List<AssetEntity> finalCandidates = [];
      for (final group in sizeGroups.values) {
        if (group.length > 1) {
          finalCandidates.addAll(group);
        }
      }

      if (finalCandidates.isEmpty) {
        yield [];
        continue;
      }

      // Phase 4: Perceptual Hashing with Caching & Byte-Reuse
      final Map<String, Uint8List> idToBytesToHash = {};
      final Map<String, String> idToHash = {};
      final Map<String, Uint8List> chunkPreviews = {};

      // STRICT SEQUENTIAL PROCESSING for thumbnails
      for (final asset in finalCandidates) {
        final cachedData = _hashCache[asset.id];
        final currentMod = asset.modifiedDateTime.millisecondsSinceEpoch;
        
        if (cachedData != null && cachedData['mod'] == currentMod) {
          idToHash[asset.id] = cachedData['hash'];
          try {
            final thumbData = await asset.thumbnailDataWithSize(const ThumbnailSize(64, 64));
            if (thumbData != null) chunkPreviews[asset.id] = thumbData;
          } catch (_) {}
        } else {
          try {
            final thumbData = await asset.thumbnailDataWithSize(const ThumbnailSize(64, 64));
            if (thumbData != null) {
              idToBytesToHash[asset.id] = thumbData;
              chunkPreviews[asset.id] = thumbData;
            }
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Hash missing ones in isolate
      if (idToBytesToHash.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final Map<String, String> newHashes = await compute(
          _processBytesInIsolate, 
          {
            'data': idToBytesToHash,
            'tempPath': tempDir.path,
          },
        );

        newHashes.forEach((id, hash) {
          idToHash[id] = hash;
          final asset = finalCandidates.firstWhere((a) => a.id == id);
          _hashCache[id] = {
            'hash': hash,
            'mod': asset.modifiedDateTime.millisecondsSinceEpoch,
          };
        });
        await _saveCache();
      }

      // Group by hash results for THIS chunk
      final Map<String, List<AssetEntity>> hashGroupsMap = {};
      for (final asset in finalCandidates) {
        final hash = idToHash[asset.id];
        if (hash != null) {
          hashGroupsMap.putIfAbsent(hash, () => []).add(asset);
        }
      }

      final List<DuplicateGroup> chunkResult = [];
      for (final group in hashGroupsMap.values) {
        if (group.length > 1) {
          final List<int> sizes = group.map((a) => assetSizes[a.id] ?? 0).toList();
          final int totalSize = sizes.fold(0, (sum, s) => sum + s);
          
          // Filter previews to only include assets in this group
          final Map<String, Uint8List> groupPreviews = {};
          for (final asset in group) {
            if (chunkPreviews.containsKey(asset.id)) {
              groupPreviews[asset.id] = chunkPreviews[asset.id]!;
            }
          }

          chunkResult.add(DuplicateGroup(
            assets: group,
            sizes: sizes,
            totalSize: totalSize,
            previewBytes: groupPreviews,
          ));
        }
      }

      yield chunkResult;
    }
  }

  // Optimized static helper for isolate - Handles Byte-to-File-to-Hash internally
  static Map<String, String> _processBytesInIsolate(Map<String, dynamic> params) {
    final Map<String, Uint8List> data = params['data'];
    final String baseTempPath = params['tempPath'];
    
    final Map<String, String> results = {};
    final hasher = AHash();
    
    // Create a sub-directory for this specific isolate run
    final isolateDir = Directory(p.join(baseTempPath, 'isolate_hash_${DateTime.now().microsecondsSinceEpoch}'));
    isolateDir.createSync(recursive: true);

    try {
      for (final entry in data.entries) {
        try {
          final assetId = entry.key;
          final bytes = entry.value;
          
          // Write to a temporary file so we can use hasher.encodeImage
          final tempFile = File(p.join(isolateDir.path, '$assetId.jpg'));
          tempFile.writeAsBytesSync(bytes);
          
          final hash = hasher.encodeImage(tempFile.path);
          results[assetId] = hash!;
        } catch (_) {
          // Skip corrupt image data
        }
      }
    } finally {
      // Clean up isolate-specific temp files immediately
      if (isolateDir.existsSync()) {
        try {
          isolateDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    return results;
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
