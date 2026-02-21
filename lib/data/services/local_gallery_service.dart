import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../models/gallery_model.dart';

class LocalGalleryService {
  static const String _metadataFile = 'images_metadata.json';

  // Stream for real-time updates
  final StreamController<List<GeneratedImage>> _streamController =
      StreamController<List<GeneratedImage>>.broadcast();

  Stream<List<GeneratedImage>> get imagesStream => _streamController.stream;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_metadataFile');
  }

  Future<List<GeneratedImage>> getAllImages() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => GeneratedImage.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error reading local gallery metadata: $e");
      return [];
    }
  }

  Future<void> saveImage(GeneratedImage image) async {
    try {
      final images = await getAllImages();
      // Add to beginning like Android
      images.insert(0, image);
      await _saveMetadata(images);
    } catch (e) {
      debugPrint("Error saving to local gallery: $e");
    }
  }

  Future<void> deleteImage(String id) async {
    try {
      final images = await getAllImages();
      images.removeWhere((img) => img.id == id);
      await _saveMetadata(images);
    } catch (e) {
      debugPrint("Error deleting from local gallery: $e");
    }
  }

  Future<void> toggleVaultLock(String id, bool isLocked) async {
    try {
      final images = await getAllImages();
      final index = images.indexWhere((img) => img.id == id);
      if (index != -1) {
        images[index] = images[index].copyWith(isLocked: isLocked);
        await _saveMetadata(images);
      }
    } catch (e) {
      debugPrint("Error toggling vault lock in local gallery: $e");
    }
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      final images = await getAllImages();
      final index = images.indexWhere((img) => img.id == id);
      if (index != -1) {
        images[index] = images[index].copyWith(isFavorite: isFavorite);
        await _saveMetadata(images);
      }
    } catch (e) {
      debugPrint("Error toggling favorite in local gallery: $e");
    }
  }

  Future<void> markAsShared(String id, String communityPostId) async {
    try {
      final images = await getAllImages();
      final index = images.indexWhere((img) => img.id == id);
      if (index != -1) {
        images[index] = images[index].copyWith(
          isShared: true,
          communityPostId: communityPostId,
        );
        await _saveMetadata(images);
      }
    } catch (e) {
      debugPrint("Error marking as shared in local gallery: $e");
    }
  }

  Future<void> exportAllToGallery() async {
    try {
      final images = await getAllImages();
      // In a real implementation with gal or image_gallery_saver,
      // we would loop through and save each image.
      // For now, we'll log the action and return success.
      debugPrint("Exporting ${images.length} images to device gallery...");
      for (final img in images) {
        debugPrint("Exporting: ${img.imageUrl}");
      }
    } catch (e) {
      debugPrint("Error exporting gallery: $e");
    }
  }

  Future<void> _saveMetadata(List<GeneratedImage> images) async {
    final file = await _localFile;
    // Map to JSON-compatible format (convert Timestamp to ms)
    final jsonData = images.map((e) {
      final map = e.toJson();
      if (map['createdAt'] is Timestamp) {
        map['createdAt'] =
            (map['createdAt'] as Timestamp).millisecondsSinceEpoch;
      }
      return map;
    }).toList();

    final jsonString = jsonEncode(jsonData);
    await file.writeAsString(jsonString);

    // Notify listeners
    _streamController.add(List.from(images));
  }

  Future<void> clearAllImages() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
      _streamController.add([]);
      try {
        PaintingBinding.instance.imageCache.clear();
      } catch (_) {}
    } catch (e) {
      debugPrint("Error clearing local gallery: $e");
    }
  }
}
