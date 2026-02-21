import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings_model.dart';
import 'package:flutter/foundation.dart';

class AppSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<WelcomeMessageData?> getWelcomeMessage() async {
    try {
      final doc = await _firestore
          .collection('app_settings')
          .doc('welcome_message')
          .get();

      if (doc.exists) {
        return WelcomeMessageData.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error fetching welcome message: $e');
    }
    return null;
  }
}
