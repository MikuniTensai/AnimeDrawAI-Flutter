import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WorkflowStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'workflow_stats';

  // In-memory cache
  final Map<String, Map<String, int>> _statsCache = {};
  final _statsController =
      StreamController<Map<String, Map<String, int>>>.broadcast();

  CollectionReference get _statsCollection =>
      _firestore.collection(_collectionPath);

  Stream<Map<String, Map<String, int>>> get statsStream =>
      _statsController.stream;

  Map<String, Map<String, int>> get currentStats =>
      Map.unmodifiable(_statsCache);

  /// Get all workflow stats as a `Map<WorkflowId, Map<String, int>>`
  Future<Map<String, Map<String, int>>> getAllStats() async {
    // Return cache immediately if available
    if (_statsCache.isNotEmpty) {
      _statsController.add(_statsCache);
    }

    try {
      debugPrint(
        "WorkflowStatsRepository: Fetching all workflow stats from server...",
      );
      final snapshot = await _statsCollection.get(
        const GetOptions(source: Source.server),
      );

      debugPrint(
        "WorkflowStatsRepository: Found ${snapshot.docs.length} documents in workflow_stats",
      );

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _statsCache[doc.id] = {
          'viewCount': (data['viewCount'] as num?)?.toInt() ?? 0,
          'generationCount': (data['generationCount'] as num?)?.toInt() ?? 0,
        };
      }

      if (_statsCache.isNotEmpty) {
        debugPrint(
          "WorkflowStatsRepository: First few cached keys: ${_statsCache.keys.take(5).toList()}",
        );
      }

      _statsController.add(_statsCache);
      return _statsCache;
    } catch (e) {
      debugPrint("WorkflowStatsRepository: Error fetching workflow stats: $e");
      return _statsCache;
    }
  }

  /// Increment view count for a workflow
  Future<void> incrementView(String workflowId) async {
    // 1. Optimistic update
    if (!_statsCache.containsKey(workflowId)) {
      _statsCache[workflowId] = {'viewCount': 0, 'generationCount': 0};
    }
    _statsCache[workflowId]!['viewCount'] =
        (_statsCache[workflowId]!['viewCount'] ?? 0) + 1;
    _statsController.add(_statsCache);

    try {
      final docRef = _statsCollection.doc(workflowId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final currentCount = data['viewCount'] ?? 0;
          transaction.update(docRef, {'viewCount': currentCount + 1});
        } else {
          transaction.set(docRef, {'viewCount': 1, 'generationCount': 0});
        }
      });
      debugPrint(
        "WorkflowStatsRepository: Incremented view count for $workflowId",
      );
    } catch (e) {
      debugPrint(
        "WorkflowStatsRepository: Error incrementing view count for $workflowId: $e",
      );
      // Revert optimistic update on error (optional, but good practice)
      _statsCache[workflowId]!['viewCount'] =
          (_statsCache[workflowId]!['viewCount'] ?? 0) - 1;
      _statsController.add(_statsCache);
    }
  }

  /// Increment generation count for a workflow
  Future<void> incrementGeneration(String workflowId) async {
    // 1. Optimistic update
    if (!_statsCache.containsKey(workflowId)) {
      _statsCache[workflowId] = {'viewCount': 0, 'generationCount': 0};
    }
    _statsCache[workflowId]!['generationCount'] =
        (_statsCache[workflowId]!['generationCount'] ?? 0) + 1;
    _statsController.add(_statsCache);

    try {
      final docRef = _statsCollection.doc(workflowId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final currentCount = data['generationCount'] ?? 0;
          transaction.update(docRef, {'generationCount': currentCount + 1});
        } else {
          transaction.set(docRef, {'viewCount': 0, 'generationCount': 1});
        }
      });
      debugPrint(
        "WorkflowStatsRepository: Incremented generation count for $workflowId",
      );
    } catch (e) {
      debugPrint(
        "WorkflowStatsRepository: Error incrementing generation count for $workflowId: $e",
      );
    }
  }

  void dispose() {
    _statsController.close();
  }
}
