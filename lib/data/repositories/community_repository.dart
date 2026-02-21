import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/community_model.dart';

class CommunityRepository {
  static const String _collectionPosts = "community_posts";
  static const String _collectionUserLikes = "user_likes";
  static const String _storagePathCommunity = "community";
  static const int _pageSize = 20;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> publishPostFromGallery({required CommunityPost post}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not authenticated");

      final postWithUser = post.copyWith(
        userId: userId,
        createdAt: DateTime.now(),
      );

      final postMap = postWithUser.toJson();
      postMap.remove('id');

      final docRef = await _firestore.collection(_collectionPosts).add(postMap);
      return docRef.id;
    } catch (e) {
      debugPrint("Publish failed: $e");
      rethrow;
    }
  }

  Future<String> uploadToCommunity({
    required File imageFile,
    required CommunityPost post,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not authenticated");

      // 1. Upload to Storage
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = "$_storagePathCommunity/$userId/$imageId.jpg";
      final ref = _storage.ref().child(storagePath);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // 2. Create Firestore doc
      final postWithUrl = post.copyWith(
        userId: userId,
        imageUrl: downloadUrl,
        thumbnailUrl: downloadUrl,
        createdAt: DateTime.now(),
      );

      final postMap = postWithUrl.toJson();
      postMap.remove('id');

      final docRef = await _firestore.collection(_collectionPosts).add(postMap);
      return docRef.id;
    } catch (e) {
      debugPrint("Upload failed: $e");
      rethrow;
    }
  }

  Stream<List<CommunityPost>> getPostsStream({
    SortType sortBy = SortType.popular,
    String? category,
    int limit = _pageSize,
  }) {
    final userId = _auth.currentUser?.uid;
    Query query = _firestore.collection(_collectionPosts);

    if (category != null && category != "All") {
      query = query.where("category", isEqualTo: category);
    }

    switch (sortBy) {
      case SortType.popular:
        query = query.orderBy("likes", descending: true);
        break;
      case SortType.recent:
        query = query.orderBy("createdAt", descending: true);
        break;
      case SortType.trending:
        query = query.orderBy("likes", descending: true);
        break;
      case SortType.myPosts:
        if (userId != null) {
          query = query.where("userId", isEqualTo: userId);
        } else {
          query = query.limit(0);
        }
        break;
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CommunityPost.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  Future<void> toggleLike(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    final likeRef = _firestore
        .collection(_collectionUserLikes)
        .doc(userId)
        .collection("posts")
        .doc(postId);

    final postRef = _firestore.collection(_collectionPosts).doc(postId);

    try {
      // 1. Check if already liked OUTSIDE transaction (matching Android implementation)
      final likeDoc = await likeRef.get();
      final isLiked = likeDoc.exists;

      // 2. Perform transaction for the post likes count and the like document itself
      await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) return;

        final currentLikes = (postSnapshot.data()?["likes"] as int?) ?? 0;
        final newLikes = isLiked ? currentLikes - 1 : currentLikes + 1;

        transaction.update(postRef, {"likes": newLikes < 0 ? 0 : newLikes});

        if (isLiked) {
          transaction.delete(likeRef);
        } else {
          transaction.set(likeRef, {
            "likedAt": DateTime.now().millisecondsSinceEpoch,
          });
        }
      });
    } catch (e) {
      debugPrint("Error toggling like: $e");
      rethrow;
    }
  }

  Future<bool> hasLiked(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection(_collectionUserLikes)
          .doc(userId)
          .collection("posts")
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking like status: $e");
      return false;
    }
  }

  Future<void> incrementDownload(String postId) async {
    await _firestore.collection(_collectionPosts).doc(postId).update({
      "downloads": FieldValue.increment(1),
    });
  }

  Future<void> incrementView(String postId) async {
    await _firestore.collection(_collectionPosts).doc(postId).update({
      "views": FieldValue.increment(1),
    });
  }

  Future<void> reportPost(String postId, String reason) async {
    await _firestore.collection(_collectionPosts).doc(postId).update({
      "reportCount": FieldValue.increment(1),
      "isReported": true,
    });
  }

  Future<void> deletePost(String postId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    final doc = await _firestore.collection(_collectionPosts).doc(postId).get();
    if (doc.data()?["userId"] != userId) {
      throw Exception("Not authorized to delete this post");
    }

    await _firestore.collection(_collectionPosts).doc(postId).delete();
  }
}
