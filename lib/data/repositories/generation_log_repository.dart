import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/generation_model.dart';

class GenerationLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionGeneratedImages = "generated_images";

  Future<void> logGeneration(
    String userId,
    TaskStatusResponse taskStatus,
    String workflow,
  ) async {
    try {
      final logData = {
        "userId": userId,
        "taskId": taskStatus.taskId,
        "workflow": workflow,
        "prompt": taskStatus.positivePrompt ?? "",
        "imageUrl": taskStatus.resultFiles?.firstOrNull ?? "",
        "createdAt": FieldValue.serverTimestamp(),
        "status": "completed",
      };

      await _firestore.collection(_collectionGeneratedImages).add(logData);
      debugPrint(
        "GenerationLogRepository: Logged successfully for user: $userId",
      );
    } catch (e) {
      debugPrint("GenerationLogRepository: Error logging: $e");
      // Logging failure should not disrupt the app flow
    }
  }
}
