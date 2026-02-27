import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStats {
  final int totalDeleted;
  final int totalKept;
  final double totalStorageSavedGB;
  final int currentStreak;
  final DateTime? lastSessionDate;

  const UserStats({
    this.totalDeleted = 0,
    this.totalKept = 0,
    this.totalStorageSavedGB = 0.0,
    this.currentStreak = 0,
    this.lastSessionDate,
  });

  UserStats copyWith({
    int? totalDeleted,
    int? totalKept,
    double? totalStorageSavedGB,
    int? currentStreak,
    DateTime? lastSessionDate,
  }) {
    return UserStats(
      totalDeleted: totalDeleted ?? this.totalDeleted,
      totalKept: totalKept ?? this.totalKept,
      totalStorageSavedGB: totalStorageSavedGB ?? this.totalStorageSavedGB,
      currentStreak: currentStreak ?? this.currentStreak,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    );
  }
}

final statsProvider = NotifierProvider<StatsNotifier, UserStats>(() {
  return StatsNotifier();
});

class StatsNotifier extends Notifier<UserStats> {
  @override
  UserStats build() {
    _loadStats();
    return const UserStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final deleted = prefs.getInt('total_deleted') ?? 0;
    final kept = prefs.getInt('total_kept') ?? 0;
    final storage = prefs.getDouble('total_storage_saved') ?? 0.0;
    final streak = prefs.getInt('current_streak') ?? 0;
    final lastDateStr = prefs.getString('last_session_date');
    
    state = UserStats(
      totalDeleted: deleted,
      totalKept: kept,
      totalStorageSavedGB: storage,
      currentStreak: streak,
      lastSessionDate: lastDateStr != null ? DateTime.parse(lastDateStr) : null,
    );
  }

  Future<void> addSession(int count, double storageGB, {int keptCount = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final newDeleted = state.totalDeleted + count;
    final newKept = state.totalKept + keptCount;
    final newStorage = state.totalStorageSavedGB + storageGB;
    
    // Simple streak logic
    int newStreak = state.currentStreak;
    final now = DateTime.now();
    if (state.lastSessionDate == null) {
      newStreak = 1;
    } else {
      final diff = now.difference(state.lastSessionDate!).inDays;
      if (diff == 1) {
        newStreak += 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    }

    await prefs.setInt('total_deleted', newDeleted);
    await prefs.setInt('total_kept', newKept);
    await prefs.setDouble('total_storage_saved', newStorage);
    await prefs.setInt('current_streak', newStreak);
    await prefs.setString('last_session_date', now.toIso8601String());

    state = state.copyWith(
      totalDeleted: newDeleted,
      totalKept: newKept,
      totalStorageSavedGB: newStorage,
      currentStreak: newStreak,
      lastSessionDate: now,
    );
  }
}
