import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';

/// Manages user's favorite workflows (Firestore-backed)
class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Get all favorite workflow IDs for the current user
  Stream<List<String>> getFavoriteIdsStream() {
    final uid = _userId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get all favorite workflow IDs (one-shot)
  Future<List<String>> getFavoriteIds() async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('FavoritesRepository: Error getting favorites: $e');
      return [];
    }
  }

  /// Check if a workflow is favorited
  Future<bool> isFavorite(String workflowId) async {
    final ids = await getFavoriteIds();
    return ids.contains(workflowId);
  }

  /// Add a workflow to favorites
  Future<void> addFavorite(String workflowId) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(workflowId)
        .set({
          'workflowId': workflowId,
          'addedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Remove a workflow from favorites
  Future<void> removeFavorite(String workflowId) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(workflowId)
        .delete();
  }

  /// Toggle favorite status, returns new state (true = now favorited)
  Future<bool> toggleFavorite(String workflowId) async {
    final isFav = await isFavorite(workflowId);
    if (isFav) {
      await removeFavorite(workflowId);
      return false;
    } else {
      await addFavorite(workflowId);
      return true;
    }
  }

  /// Get full WorkflowInfo objects for all favorites
  Future<List<WorkflowInfo>> getFavoriteWorkflows(
    Map<String, WorkflowInfo> allWorkflows,
  ) async {
    final ids = await getFavoriteIds();
    return ids
        .where((id) => allWorkflows.containsKey(id))
        .map((id) => allWorkflows[id]!)
        .toList();
  }
}
