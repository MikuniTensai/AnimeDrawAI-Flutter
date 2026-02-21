import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../models/shop_model.dart';
import '../services/api_service.dart';

class CharacterRepository {
  final ApiService _apiService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CharacterRepository(this._apiService);

  // --- Real-time Streams ---

  Stream<List<CharacterModel>> getCharactersStream({
    bool includeDeleted = false,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('characters')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return CharacterModel.fromJson({...data, 'id': doc.id});
              })
              .where((character) {
                return includeDeleted || !character.isDeleted;
              })
              .toList();
        });
  }

  Stream<CharacterModel?> getCharacterStream(String characterId) {
    return _db.collection('characters').doc(characterId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return CharacterModel.fromJson({...data, 'id': doc.id});
    });
  }

  // --- Actions ---

  Future<String?> uploadImageToStorage(File file, String characterId) async {
    try {
      final ref = _storage.ref().child('characters/$characterId.jpg');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    // Soft delete in Firestore
    await _db.collection('characters').doc(characterId).update({
      'isDeleted': true,
    });

    // Delete associated chat messages (Optional/Background)
    final chatDocs = await _db
        .collection('characterChats')
        .where('characterId', isEqualTo: characterId)
        .where('userId', isEqualTo: user.uid)
        .get();

    final batch = _db.batch();
    for (var doc in chatDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Combined API Calls ---

  Future<CharacterModel> getCharacterProfile(String characterId) async {
    final response = await _apiService.getCharacterProfile(characterId);
    return CharacterModel.fromJson(response['character'] ?? response);
  }

  Future<Map<String, dynamic>> createCharacter({
    required String imageId,
    required String imageUrl,
    required String prompt,
    String language = 'en',
    String gender = 'female',
    bool replace = false,
    String? name,
    int? seed,
    String? workflow,
  }) async {
    final request = {
      'imageId': imageId,
      'imageUrl': imageUrl,
      'prompt': prompt,
      'language': language,
      'gender': gender,
      'replace': replace,
      'name': name,
      'seed': seed,
      'workflow': workflow,
      'appearancePrompt':
          prompt, // Required for backend persistence (matches Android)
    };
    return await _apiService.createCharacter(request);
  }

  // --- Chat & Relationship ---

  Future<Map<String, dynamic>> sendMessage(
    String characterId,
    String content, {
    bool isUpgradeTrigger = false,
  }) async {
    final request = {
      'characterId': characterId,
      'message': content,
      'isUpgradeTrigger': isUpgradeTrigger,
    };
    return await _apiService.sendMessage(request);
  }

  Future<List<CharacterMessage>> getChatHistory(String characterId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _apiService.getCharacterChatHistory(characterId);
      if (response['success'] == true && response['messages'] != null) {
        final List<dynamic> messagesData = response['messages'];
        final messages = messagesData
            .map((json) => CharacterMessage.fromJson(json))
            .toList();
        return messages;
      }
      return [];
    } catch (e) {
      debugPrint("Error getting chat history: $e");
      // Fallback or rethrow? For now, empty list is safer to avoid crashing UI
      return [];
    }
  }

  Future<Map<String, dynamic>> toggleNotification(
    String characterId,
    bool enable,
  ) async {
    final request = {'characterId': characterId, 'enable': enable};
    return await _apiService.toggleNotification(request);
  }

  Future<Map<String, dynamic>> updateCharacterProfileImage(
    String characterId,
    String imageUrl,
  ) async {
    final request = {'characterId': characterId, 'imageUrl': imageUrl};
    return await _apiService.updateCharacterProfileImage(request);
  }

  Future<Map<String, dynamic>> sendGift(
    String characterId,
    String itemId,
  ) async {
    final request = {'characterId': characterId, 'itemId': itemId};
    return await _apiService
        .sendGift(GiftRequest.fromJson(request))
        .then((res) => res.toJson());
  }

  Future<Map<String, dynamic>> requestPhoto({
    required String characterId,
    required String userPrompt,
    String negativePrompt = "",
    int? seed,
    String appearancePrompt = "",
    String language = "en",
    String chatContext = "",
  }) async {
    final request = {
      'characterId': characterId,
      'prompt_override': userPrompt,
      'negativePrompt': negativePrompt,
      'seed': seed,
      'appearancePrompt': appearancePrompt,
      'language': language,
      'context': chatContext,
    };
    return await _apiService.requestPhoto(request);
  }

  Future<Map<String, dynamic>> injectMessage({
    required String characterId,
    required String role,
    required String content,
    String? imageUrl,
  }) async {
    final request = {
      'characterId': characterId,
      'role': role,
      'content': content,
      'imageUrl': imageUrl,
    };
    return await _apiService.injectMessage(request);
  }
}
