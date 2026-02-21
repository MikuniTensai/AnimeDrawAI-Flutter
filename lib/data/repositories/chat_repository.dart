import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService;

  ChatRepository(this._apiService);

  // --- Real-time Streams (for character chat or shared sessions) ---

  Stream<List<ChatMessage>> getChatMessagesStream(String sessionId) {
    return _db
        .collection('chats')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  // --- General AI Chat Actions (via ApiService) ---

  Future<ChatMessage?> sendGeneralMessage(
    String text,
    String? sessionId,
  ) async {
    final response = await _apiService.sendGeneralChatMessage({
      'message': text,
      'session_id': sessionId,
    });

    if (response['success'] == true && response['response'] != null) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response['response'],
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sessionId: response['session_id'],
      );
    }
    return null;
  }

  Future<List<ChatMessage>> getHistory(String sessionId) async {
    final response = await _apiService.getChatHistory(sessionId);
    if (response['success'] == true && response['messages'] != null) {
      return (response['messages'] as List).map((m) {
        return ChatMessage(
          id: "${sessionId}_${m['timestamp']}",
          role: m['role'],
          content: m['content'],
          timestamp: _parseTimestamp(m['timestamp']),
          sessionId: sessionId,
        );
      }).toList();
    }
    return [];
  }

  Future<String?> createSession() async {
    final response = await _apiService.createChatSession();
    return response['success'] == true ? response['session_id'] : null;
  }

  Future<bool> deleteSession(String sessionId) async {
    final response = await _apiService.deleteChatSession(sessionId);
    return response['success'] == true;
  }

  Future<List<String>> getModels() async {
    final response = await _apiService.getChatModels();
    if (response['success'] == true && response['models'] != null) {
      return (response['models'] as List)
          .map((m) => m['name'] as String)
          .toList();
    }
    return [];
  }

  int _parseTimestamp(dynamic ts) {
    if (ts is int) return ts;
    if (ts is String) {
      return DateTime.tryParse(ts)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  // --- Legacy/Firestore Actions ---

  Future<void> sendMessage(String text, String? sessionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final message = {
      'userId': user.uid,
      'sessionId': sessionId,
      'role': 'user',
      'content': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _db.collection('chats').add(message);
  }
}
