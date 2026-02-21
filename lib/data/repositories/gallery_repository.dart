import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/gallery_model.dart';
import '../models/generation_model.dart';
import '../services/local_gallery_service.dart';
import 'usage_statistics_repository.dart';

class GalleryRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalGalleryService _localService = LocalGalleryService();
  final UsageStatisticsRepository? _statsRepo;

  GalleryRepository([this._statsRepo]);

  /// Get generations - Local Only (Android Parity)
  /// Android's GalleryScreen uses ImageStorage.getAllImages() which is local.
  Stream<List<GeneratedImage>> getGenerationsStream() async* {
    // 1. Return initial local images
    final initialImages = await _localService.getAllImages();
    _sortImages(initialImages);
    yield initialImages;

    // 2. Listen for future changes
    await for (final images in _localService.imagesStream) {
      final updatedImages = List<GeneratedImage>.from(images);
      _sortImages(updatedImages);
      yield updatedImages;
    }
  }

  void _sortImages(List<GeneratedImage> images) {
    images.sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> saveGeneration(TaskStatusResponse task) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    var imageUrl = task.downloadUrls?.isNotEmpty == true
        ? task.downloadUrls![0]
        : null;
    if (imageUrl == null) return;

    // Resolve relative URL
    if (imageUrl.startsWith('/')) {
      imageUrl = "https://drawai-api.drawai.site$imageUrl";
    }

    final newImage = GeneratedImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      imageUrl: imageUrl,
      prompt: task.positivePrompt,
      negativePrompt: task.negativePrompt,
      workflow: task.workflow ?? 'standard',
      seed: task.seed ?? 0,
      createdAt: DateTime.now(),
    );

    // 1. Save locally (Android Parity)
    await _localService.saveImage(newImage);

    // 2. Increment stats (Android Parity)
    await _statsRepo?.incrementSaves();

    // Note: We do NOT write to `user_generations` anymore because Android
    // does not use it, and we don't have permission.
    // Global logging is handled by GenerationLogRepository.
  }

  Future<void> toggleFavorite(String imageId, bool currentStatus) async {
    // Local Update Only
    try {
      await _localService.toggleFavorite(imageId, !currentStatus);
      if (!currentStatus) {
        await _statsRepo?.incrementFavorites();
      } else {
        await _statsRepo?.decrementFavorites();
      }
    } catch (_) {}
  }

  Future<void> deleteGeneration(String imageId) async {
    // Local Delete Only
    try {
      await _localService.deleteImage(imageId);
    } catch (_) {}
  }

  Future<void> toggleVaultLock(String imageId, bool isLocked) async {
    try {
      await _localService.toggleVaultLock(imageId, isLocked);
    } catch (_) {}
  }

  Future<void> markAsShared(String imageId, String communityPostId) async {
    try {
      await _localService.markAsShared(imageId, communityPostId);
    } catch (_) {}
  }

  Future<void> exportGallery({
    Function(int current, int total)? onProgress,
  }) async {
    await _localService.exportAllToGallery(onProgress: onProgress);
  }

  Future<void> clearGallery() async {
    try {
      await _localService.clearAllImages();
    } catch (_) {}
  }
}
