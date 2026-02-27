import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonecleaner/data/photo_repository.dart';

final homeStatsProvider = FutureProvider<PhotoStats>((ref) async {
  final repository = ref.watch(photoRepositoryProvider);
  return repository.getPhotoStats();
});
