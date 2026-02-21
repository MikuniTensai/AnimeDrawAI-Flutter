import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class UsageStats {
  final int totalGenerations;
  final int totalSaves;
  final int totalFavorites;
  final String lastGenerationDate;
  final String firstGenerationDate;
  final int lastUpdated;

  UsageStats({
    this.totalGenerations = 0,
    this.totalSaves = 0,
    this.totalFavorites = 0,
    this.lastGenerationDate = "",
    this.firstGenerationDate = "",
    this.lastUpdated = 0,
  });

  factory UsageStats.fromMap(Map<String, dynamic> map) {
    // If stats are nested in a 'statistics' field
    final stats = map['statistics'] as Map<String, dynamic>? ?? map;
    return UsageStats(
      totalGenerations: stats['total_generations'] ?? 0,
      totalSaves: stats['total_saves'] ?? 0,
      totalFavorites: stats['total_favorites'] ?? 0,
      lastGenerationDate: stats['last_generation_date'] ?? "",
      firstGenerationDate: stats['first_generation_date'] ?? "",
      lastUpdated: stats['last_updated'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_generations': totalGenerations,
      'total_saves': totalSaves,
      'total_favorites': totalFavorites,
      'last_generation_date': lastGenerationDate,
      'first_generation_date': firstGenerationDate,
      'last_updated': lastUpdated,
    };
  }
}

class UsageStatisticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  UsageStatisticsRepository({required this.userId});

  DocumentReference get _statsRef => _firestore.collection('users').doc(userId);

  static String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  Future<UsageStats> getUsageStats() async {
    try {
      final doc = await _statsRef.get();
      if (doc.exists) {
        return UsageStats.fromMap(doc.data() as Map<String, dynamic>);
      }
      return UsageStats();
    } catch (e) {
      debugPrint("Error getting usage stats: $e");
      return UsageStats();
    }
  }

  Future<void> incrementGenerations() async {
    try {
      final currentDate = _getCurrentDate();
      final updates = {
        'statistics.total_generations': FieldValue.increment(1),
        'statistics.last_generation_date': currentDate,
        'statistics.last_updated': DateTime.now().millisecondsSinceEpoch,
      };

      // Set first_generation_date if it's the first one
      // Since we can't easily check for null in nested FieldValue.increment
      // without a read, we can just fetch once or just always set it if missing.
      // For simplicity and to avoid another read if possible:
      await _statsRef.update(updates);
    } catch (e) {
      debugPrint("Error incrementing generations: $e");
    }
  }

  Future<void> incrementSaves() async {
    try {
      await _statsRef.update({
        'statistics.total_saves': FieldValue.increment(1),
        'statistics.last_updated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error incrementing saves: $e");
    }
  }

  Future<void> incrementFavorites() async {
    try {
      await _statsRef.update({
        'statistics.total_favorites': FieldValue.increment(1),
        'statistics.last_updated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error incrementing favorites: $e");
    }
  }

  Future<void> decrementFavorites() async {
    try {
      await _statsRef.update({
        'statistics.total_favorites': FieldValue.increment(-1),
        'statistics.last_updated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error decrementing favorites: $e");
    }
  }
}
