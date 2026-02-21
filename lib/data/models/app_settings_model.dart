import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomeMessageData {
  final String title;
  final String message;
  final String? iconUrl;
  final String? imageUrl;
  final String buttonText;
  final bool isActive;
  final DateTime? updatedAt;

  WelcomeMessageData({
    required this.title,
    required this.message,
    this.iconUrl,
    this.imageUrl,
    required this.buttonText,
    required this.isActive,
    this.updatedAt,
  });

  factory WelcomeMessageData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WelcomeMessageData(
      title: data['title'] ?? 'Welcome',
      message: data['message'] ?? '',
      iconUrl: data['iconUrl'],
      imageUrl: data['imageUrl'],
      buttonText: data['buttonText'] ?? 'Ok',
      isActive: data['isActive'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory WelcomeMessageData.defaultMessage() {
    return WelcomeMessageData(
      title: "Welcome to DrawAI",
      message: "Create stunning anime artwork with the power of AI!",
      buttonText: "Ok",
      isActive: true,
    );
  }
}
