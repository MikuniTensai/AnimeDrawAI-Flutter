import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/generation_model.dart';
import '../models/daily_reward_model.dart';
import '../models/shop_model.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<WorkflowsResponse> getWorkflows() async {
    final response = await _dio.get("workflows");
    return WorkflowsResponse.fromJson(response.data);
  }

  Future<GenerateResponse> generateImage(GenerateRequest request) async {
    final response = await _dio.post("generate", data: request.toJson());
    return GenerateResponse.fromJson(response.data);
  }

  Future<TaskStatusResponse> getTaskStatus(String taskId) async {
    final response = await _dio.get("status/$taskId");
    return TaskStatusResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get("health");
    return response.data;
  }

  Future<GenerateResponse> removeBackground({
    required List<int> image,
    required String filename,
    Map<String, dynamic> options = const {},
  }) async {
    final formData = FormData.fromMap({
      "image": MultipartFile.fromBytes(image, filename: filename),
      "filename": filename,
      ...options.map((key, value) => MapEntry(key, value.toString())),
    });
    final response = await _dio.post("remove-background", data: formData);
    return GenerateResponse.fromJson(response.data);
  }

  Future<GenerateResponse> upscaleImage({
    required List<int> image,
    required String filename,
    Map<String, dynamic> options = const {},
  }) async {
    final formData = FormData.fromMap({
      "image": MultipartFile.fromBytes(image, filename: filename),
      "filename": filename,
      ...options.map((key, value) => MapEntry(key, value.toString())),
    });
    final response = await _dio.post("upscale-image", data: formData);
    return GenerateResponse.fromJson(response.data);
  }

  Future<GenerateResponse> sketchToImage({
    required List<int> image,
    required String filename,
    Map<String, dynamic> options = const {},
  }) async {
    final formData = FormData.fromMap({
      "image": MultipartFile.fromBytes(image, filename: filename),
      "filename": filename,
      ...options.map((key, value) => MapEntry(key, value.toString())),
    });
    final response = await _dio.post("sketch-to-image", data: formData);
    return GenerateResponse.fromJson(response.data);
  }

  Future<GenerateResponse> drawToImage({
    required List<int> image,
    required String filename,
    Map<String, dynamic> options = const {},
  }) async {
    final formData = FormData.fromMap({
      "image": MultipartFile.fromBytes(image, filename: filename),
      "filename": filename,
      ...options.map((key, value) => MapEntry(key, value.toString())),
    });
    final response = await _dio.post("draw-to-image", data: formData);
    return GenerateResponse.fromJson(response.data);
  }

  Future<GenerateResponse> faceRestore({
    required List<int> image,
    required String filename,
    Map<String, dynamic> options = const {},
  }) async {
    final formData = FormData.fromMap({
      "image": MultipartFile.fromBytes(image, filename: filename),
      "filename": filename,
      "tool_name": "face_restore",
      ...options.map((key, value) => MapEntry(key, value.toString())),
    });
    final response = await _dio.post("face-restore", data: formData);
    return GenerateResponse.fromJson(response.data);
  }

  Future<GenerateResponse> makeBackground({
    Map<String, dynamic> options = const {},
  }) async {
    final response = await _dio.post("make-background", data: options);
    return GenerateResponse.fromJson(response.data);
  }

  Future<GenerateResponse> makeBackgroundAdvanced({
    Map<String, dynamic> options = const {},
  }) async {
    final response = await _dio.post("make-background-advanced", data: options);
    return GenerateResponse.fromJson(response.data);
  }

  // Character Management
  Future<Map<String, dynamic>> createCharacter(
    Map<String, dynamic> request,
  ) async {
    final response = await _dio.post("api/character/create", data: request);
    return response.data;
  }

  Future<Map<String, dynamic>> getCharacterProfile(String characterId) async {
    final response = await _dio.get("api/character/profile/$characterId");
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> request) async {
    final response = await _dio.post("api/character/chat", data: request);
    return response.data;
  }

  Future<Map<String, dynamic>> getCharacterChatHistory(
    String characterId, {
    int limit = 50,
  }) async {
    final response = await _dio.get(
      "api/character/history/$characterId",
      queryParameters: {'limit': limit},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> requestPhoto(
    Map<String, dynamic> request,
  ) async {
    final response = await _dio.post(
      "api/character/request-photo",
      data: request,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> injectMessage(
    Map<String, dynamic> request,
  ) async {
    final response = await _dio.post(
      "api/character/message/inject",
      data: request,
    );
    return response.data;
  }

  // Daily Rewards
  Future<DailyStatusResponse> checkDailyStatus() async {
    final response = await _dio.get("daily-rewards/status");
    return DailyStatusResponse.fromJson(response.data);
  }

  Future<DailyClaimResponse> claimDailyReward() async {
    try {
      final response = await _dio.post("daily-rewards/claim");
      return DailyClaimResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return DailyClaimResponse.fromJson(e.response!.data);
        } catch (_) {
          return DailyClaimResponse(
            success: false,
            newStreak: 0,
            error: e.response?.data?['error']?.toString() ?? e.message,
          );
        }
      }
      return DailyClaimResponse(success: false, newStreak: 0, error: e.message);
    } catch (e) {
      return DailyClaimResponse(
        success: false,
        newStreak: 0,
        error: e.toString(),
      );
    }
  }

  // Inventory & Gift
  Future<List<InventoryItemModel>> getInventory() async {
    final response = await _dio.get("user/inventory");
    final data = response.data;
    final List itemsList = data is Map ? (data['inventory'] ?? []) : data;
    return itemsList.map((e) => InventoryItemModel.fromJson(e)).toList();
  }

  Future<GiftResponse> sendGift(GiftRequest request) async {
    final response = await _dio.post("character/gift", data: request.toJson());
    return GiftResponse.fromJson(response.data);
  }

  // Shop
  Future<List<ShopItem>> getShopItems() async {
    final response = await _dio.get("shop/items");
    final data = response.data;
    final List itemsList = data is Map ? (data['items'] ?? []) : data;
    return itemsList.map((e) => ShopItem.fromJson(e)).toList();
  }

  Future<GiftResponse> purchaseShopItem(Map<String, dynamic> request) async {
    final response = await _dio.post("shop/purchase", data: request);
    return GiftResponse.fromJson(response.data);
  }

  Future<UseItemResponse> useItem(UseItemRequest request) async {
    final response = await _dio.post("user/use-item", data: request.toJson());
    return UseItemResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> toggleNotification(
    Map<String, dynamic> request,
  ) async {
    final response = await _dio.post(
      "character/toggle-notification",
      data: request,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateCharacterProfileImage(
    Map<String, dynamic> request,
  ) async {
    final response = await _dio.post(
      "character/update-profile-image",
      data: request,
    );
    return response.data;
  }

  // General AI Chat (api/chat/...)
  Future<Map<String, dynamic>> sendGeneralChatMessage(
    Map<String, dynamic> request,
  ) async {
    final response = await _dio.post("api/chat/send", data: request);
    return response.data;
  }

  Future<Map<String, dynamic>> getChatHistory(String sessionId) async {
    final response = await _dio.get("api/chat/history/$sessionId");
    return response.data;
  }

  Future<Map<String, dynamic>> createChatSession() async {
    final response = await _dio.post("api/chat/session/new");
    return response.data;
  }

  Future<Map<String, dynamic>> deleteChatSession(String sessionId) async {
    final response = await _dio.delete("api/chat/session/$sessionId");
    return response.data;
  }

  Future<Map<String, dynamic>> getChatModels() async {
    final response = await _dio.get("api/chat/models");
    return response.data;
  }
}
