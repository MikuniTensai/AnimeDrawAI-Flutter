import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/generation_model.dart';
import '../models/generation_limit_model.dart';
import '../models/daily_reward_model.dart';
import '../services/api_service.dart';
import 'generation_repository.dart';
import 'gallery_repository.dart';
import 'usage_statistics_repository.dart';
import 'workflow_stats_repository.dart';
import 'generation_log_repository.dart';
import '../models/vision_model.dart'; // Added
import '../models/shop_model.dart';
import '../models/leaderboard_model.dart';
import 'package:dio/dio.dart';

class GenerationLimitExceededException implements Exception {
  final int remaining;
  final String message;
  final LimitInfo? limitInfo;

  GenerationLimitExceededException({
    this.remaining = 0,
    this.message = "Generation limit exceeded",
    this.limitInfo,
  });

  @override
  String toString() => message;
}

class DrawAiRepository {
  static const String _tag = "DrawAiRepository";
  static const Duration _pollingInterval = Duration(seconds: 2);
  static const int _maxPollingAttempts = 180; // 6 minutes
  static const String _workflowCacheKey = "cached_workflows";
  static const String _workflowTimestampKey = "workflow_timestamp";
  static const int _cacheMaxAge = 24 * 60 * 60 * 1000; // 24 hours (Full expiry)
  static const int _cacheRefreshThreshold =
      60 * 60 * 1000; // 1 hour (Background fetch threshold)

  // Daily Status Cache
  static const String _dailyStatusCacheKey = "cached_daily_status";
  static const String _dailyStatusTimestampKey = "daily_status_timestamp";
  static const int _dailyStatusCacheMaxAge = 15 * 60 * 1000; // 15 minutes

  // Visions Cache
  static const String _inventoryCacheKey = "cache_inventory";
  static const String _visionCacheKey = "cached_visions";
  static const String _visionTimestampKey = "vision_timestamp";
  static const int _visionCacheMaxAge = 12 * 60 * 60 * 1000; // 12 hours

  final ApiService _apiService;
  final GenerationRepository _generationRepo;
  final GalleryRepository _galleryRepo;
  final UsageStatisticsRepository? _statsRepo;
  final WorkflowStatsRepository _wfStatsRepo;
  final GenerationLogRepository _generationLogRepo = GenerationLogRepository();

  DrawAiRepository(
    this._apiService,
    this._generationRepo,
    this._galleryRepo,
    this._statsRepo,
    this._wfStatsRepo,
  );

  /// Get list of available workflows with caching
  Future<Map<String, WorkflowInfo>> getWorkflows({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (forceRefresh) {
      debugPrint("$_tag: Force refreshing workflows...");
      return await _fetchAndCacheWorkflows(prefs);
    }

    // Try to load from cache first
    try {
      final cachedData = prefs.getString(_workflowCacheKey);
      final timestamp = prefs.getInt(_workflowTimestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);
        final workflows = decoded.map(
          (key, value) => MapEntry(key, WorkflowInfo.fromJson(value)),
        );

        final age = currentTime - timestamp;

        // If cache is still within background refresh threshold, just return it
        if (age < _cacheRefreshThreshold) {
          debugPrint(
            "$_tag: Workflows cache is fresh (${age ~/ 1000}s old), skipping background fetch",
          );
          return workflows;
        }

        // If cache is older than threshold but not fully expired (24h),
        // return cache but refresh in background
        if (age < _cacheMaxAge) {
          debugPrint(
            "$_tag: Workflows cache is stale (${age ~/ 60000}m old), refreshing in background",
          );
          _fetchAndCacheWorkflows(prefs);
          return workflows;
        }
      }
    } catch (e) {
      debugPrint("$_tag: Error reading workflow cache: $e");
    }

    return await _fetchAndCacheWorkflows(prefs);
  }

  Future<Map<String, WorkflowInfo>> _fetchAndCacheWorkflows(
    SharedPreferences prefs,
  ) async {
    try {
      final response = await _apiService.getWorkflows();
      if (response.success) {
        // Save to cache
        final jsonString = jsonEncode(
          response.workflows.map((key, value) => MapEntry(key, value.toJson())),
        );
        await prefs.setString(_workflowCacheKey, jsonString);
        await prefs.setInt(
          _workflowTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return response.workflows;
      }
      return _getDummyWorkflows();
    } catch (e) {
      debugPrint("$_tag: Error fetching workflows: $e");
      return _getDummyWorkflows();
    }
  }

  Map<String, WorkflowInfo> _getDummyWorkflows() {
    return {
      "anime_red_lily": WorkflowInfo(
        name: "Red Lily",
        description: "Best Quality Anime Style",
        estimatedTime: "40s",
        fileExists: true,
        isPremium: false,
        useCount: 12400,
        viewCount: 45000,
      ),
      "general_asia_blend_illustrious": WorkflowInfo(
        name: "Asia Blend",
        description: "Detailed Asian Illustration",
        estimatedTime: "45s",
        fileExists: true,
        isPremium: false,
        useCount: 8900,
        viewCount: 32000,
      ),
    };
  }

  /// Generate image and wait for completion
  Future<TaskStatusResponse> generateAndWait({
    required String positivePrompt,
    String negativePrompt = "",
    String workflow = "standard",
    required String userId,
    int? seed,
    int? width,
    int? height,
    String? ckptName,
    int? steps,
    double? cfg,
    String? samplerName,
    String? scheduler,
    double? denoise,
    String? upscaleMethod,
    Function(String, TaskStatusResponse?)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call("Memulai generasi...", null);

      // 1. Kick off generation
      final request = GenerateRequest(
        positivePrompt: positivePrompt,
        negativePrompt: negativePrompt,
        workflow: workflow,
        seed: seed,
        width: width,
        height: height,
        ckptName: ckptName,
        steps: steps,
        cfg: cfg,
        samplerName: samplerName,
        scheduler: scheduler,
        denoise: denoise,
        upscaleMethod: upscaleMethod,
      );

      final GenerateResponse response;
      try {
        response = await _apiService.generateImage(request);
      } on DioException catch (e) {
        if (e.response?.statusCode == 403) {
          final data = e.response?.data;
          LimitInfo? limitInfo;
          if (data is Map<String, dynamic> && data.containsKey('limit_info')) {
            try {
              limitInfo = LimitInfo.fromJson(data['limit_info']);
            } catch (_) {}
          }
          throw GenerationLimitExceededException(
            remaining: limitInfo?.remaining ?? 0,
            message: data?['error'] ?? "Limit generasi tercapai",
            limitInfo: limitInfo,
          );
        }
        rethrow;
      }

      if (!response.success || response.taskId == null) {
        if (response.error?.contains("limit") == true) {
          throw GenerationLimitExceededException(
            remaining: response.limitInfo?.remaining ?? 0,
            message: response.error ?? "Limit generasi tercapai",
            limitInfo: response.limitInfo,
          );
        }
        throw Exception(response.error ?? "Gagal memulai generasi");
      }

      final taskId = response.taskId!;
      onStatusUpdate?.call("Processing", null);

      // 2. Poll for results
      final result = await _pollTask(taskId, userId, onStatusUpdate);

      // Increment total generations on success
      await _statsRepo?.incrementGenerations();

      // Increment per-workflow generation count
      await _wfStatsRepo.incrementGeneration(workflow);

      return result;
    } catch (e) {
      debugPrint("$_tag: Error in generateAndWait: $e");
      rethrow;
    }
  }

  /// Execute an image tool (Remove BG, Upscale, etc.) and wait for completion
  Future<TaskStatusResponse> executeToolAndWait({
    required String toolType,
    List<int>? imageBytes,
    String? filename,
    Map<String, dynamic> options = const {},
    Function(String, TaskStatusResponse?)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call("Processing image...", null);

      GenerateResponse response;
      switch (toolType) {
        case 'remove_background':
          response = await _apiService.removeBackground(
            image: imageBytes!,
            filename: filename!,
            options: options,
          );
          break;
        case 'upscale':
          response = await _apiService.upscaleImage(
            image: imageBytes!,
            filename: filename!,
            options: options,
          );
          break;
        case 'sketch_to_image':
          response = await _apiService.sketchToImage(
            image: imageBytes!,
            filename: filename!,
            options: options,
          );
          break;
        case 'draw_to_image':
          response = await _apiService.drawToImage(
            image: imageBytes!,
            filename: filename!,
            options: options,
          );
          break;
        case 'face_restore':
          response = await _apiService.faceRestore(
            image: imageBytes!,
            filename: filename!,
            options: options,
          );
          break;
        case 'make_background':
          return await generateAndWait(
            positivePrompt: options['prompt'] ?? "",
            workflow: "make_background_v1",
            userId: FirebaseAuth.instance.currentUser?.uid ?? "",
            width: int.tryParse(options['width']?.toString() ?? ""),
            height: int.tryParse(options['height']?.toString() ?? ""),
            seed: int.tryParse(options['seed']?.toString() ?? ""),
            onStatusUpdate: onStatusUpdate,
          );
        case 'make_background_advanced':
          return await generateAndWait(
            positivePrompt: options['positive_prompt'] ?? "",
            negativePrompt: options['negative_prompt'] ?? "",
            workflow: "make_background_v2",
            userId: FirebaseAuth.instance.currentUser?.uid ?? "",
            width: int.tryParse(options['width']?.toString() ?? ""),
            height: int.tryParse(options['height']?.toString() ?? ""),
            seed: int.tryParse(options['seed']?.toString() ?? ""),
            cfg: double.tryParse(options['cfg_scale']?.toString() ?? ""),
            steps: int.tryParse(options['steps']?.toString() ?? ""),
            ckptName: options['ckpt_name']?.toString(),
            onStatusUpdate: onStatusUpdate,
          );
        default:
          throw Exception("Unknown tool type: $toolType");
      }

      if (!response.success || response.taskId == null) {
        throw Exception(response.error ?? "Failed to start $toolType");
      }

      final taskId = response.taskId!;
      onStatusUpdate?.call("Processing", null);

      final userId = FirebaseAuth.instance.currentUser?.uid ?? "";

      // Poll for results
      final result = await _pollTask(
        taskId,
        userId,
        onStatusUpdate,
        toolName: toolType,
      );

      // Log stats
      await _statsRepo?.incrementGenerations();
      await _wfStatsRepo.incrementGeneration(toolType);

      return result;
    } catch (e) {
      debugPrint("$_tag: Error in executeToolAndWait: $e");
      rethrow;
    }
  }

  Future<TaskStatusResponse> _pollTask(
    String taskId,
    String userId, // Added userId
    Function(String, TaskStatusResponse?)? onStatusUpdate, {
    String? toolName,
  }) async {
    int attempts = 0;
    int consecutiveErrors = 0;
    const int maxConsecutiveErrors = 5;

    while (attempts < _maxPollingAttempts) {
      try {
        final status = await _apiService.getTaskStatus(taskId);
        consecutiveErrors = 0;

        onStatusUpdate?.call("", status);

        if (status.status == "completed") {
          onStatusUpdate?.call("Downloading images...", status);

          // Secondary steps: Auto-save to Gallery and log stats
          try {
            // 1. Save to Local Gallery (Android Parity)
            await _galleryRepo.saveGeneration(status);

            // 2. Log to Global Stats (Android generated_images)
            await _generationLogRepo.logGeneration(
              userId,
              status,
              status.workflow ?? toolName ?? "standard",
            );

            // 3. Log user usage stats
            await _statsRepo?.incrementSaves();
          } catch (e) {
            debugPrint("$_tag: Warning - Failed to save/log: $e");
          }

          return status;
        } else if (status.status == "error" || status.status == "failed") {
          throw Exception(status.error ?? "Generasi gagal");
        }

        // Wait before next poll
        await Future.delayed(_pollingInterval);
        attempts++;
      } catch (e) {
        consecutiveErrors++;
        if (consecutiveErrors >= maxConsecutiveErrors) {
          throw Exception("Koneksi terputus. Silakan coba lagi nanti.");
        }
        await Future.delayed(_pollingInterval);
        attempts++;
      }
    }

    throw Exception("Waktu habis (Timeout). Task memakan waktu terlalu lama.");
  }

  // Proxies to GenerationRepository for convenience
  Stream<GenerationLimit> getLimitStream(String userId) =>
      _generationRepo.getGenerationLimitStream(userId);

  Future<void> addBonus(String userId) =>
      _generationRepo.addBonusGeneration(userId);

  Stream<int> getGemCountStream(String userId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['gems'] as int? ?? 0);
  }

  Future<DailyStatusResponse> checkDailyStatus() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cachedData = prefs.getString(_dailyStatusCacheKey);
      final timestamp = prefs.getInt(_dailyStatusTimestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null &&
          (currentTime - timestamp) < _dailyStatusCacheMaxAge) {
        debugPrint("$_tag: Returning cached daily status");
        return DailyStatusResponse.fromJson(jsonDecode(cachedData));
      }
    } catch (e) {
      debugPrint("$_tag: Error reading daily status cache: $e");
    }

    final response = await _apiService.checkDailyStatus();

    if (response.success) {
      try {
        await prefs.setString(
          _dailyStatusCacheKey,
          jsonEncode(response.toJson()),
        );
        await prefs.setInt(
          _dailyStatusTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (e) {
        debugPrint("$_tag: Error caching daily status: $e");
      }
    }

    return response;
  }

  Future<DailyClaimResponse> claimDailyReward() async {
    final response = await _apiService.claimDailyReward();

    // Invalidate cache on success OR if already claimed (local state was stale)
    if (response.success ||
        response.error?.contains("Already claimed") == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyStatusCacheKey);
      await prefs.remove(_dailyStatusTimestampKey);
      debugPrint("$_tag: Invalidated daily status cache after claim attempt");
    }

    return response;
  }

  /// Get stats for all workflows
  Future<Map<String, Map<String, int>>> getAllWorkflowStats() async {
    return await _wfStatsRepo.getAllStats();
  }

  Stream<Map<String, Map<String, int>>> get getAllWorkflowStatsStream =>
      _wfStatsRepo.statsStream;

  Map<String, Map<String, int>> get currentWorkflowStats =>
      _wfStatsRepo.currentStats;

  /// Increment view count for a workflow
  Future<void> incrementWorkflowView(String workflowId) async {
    await _wfStatsRepo.incrementView(workflowId);
  }

  /// Fetch visions from Firestore with caching
  Future<List<VisionItem>> getVisions({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      try {
        final cachedData = prefs.getString(_visionCacheKey);
        final timestamp = prefs.getInt(_visionTimestampKey) ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        if (cachedData != null &&
            (currentTime - timestamp) < _visionCacheMaxAge) {
          debugPrint("$_tag: Returning cached visions");
          final List<dynamic> decoded = jsonDecode(cachedData);
          return decoded.map((item) => VisionItem.fromJson(item)).toList();
        }
      } catch (e) {
        debugPrint("$_tag: Error reading vision cache: $e");
      }
    }

    try {
      final querySnapshot = forceRefresh
          ? await FirebaseFirestore.instance
                .collection("visions")
                .get(const GetOptions(source: Source.server))
          : await FirebaseFirestore.instance.collection("visions").get();

      final visions = querySnapshot.docs.map((doc) {
        return VisionItem.fromFirestore(doc.id, doc.data());
      }).toList();

      // Save to cache
      try {
        final jsonString = jsonEncode(visions.map((v) => v.toJson()).toList());
        await prefs.setString(_visionCacheKey, jsonString);
        await prefs.setInt(
          _visionTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (e) {
        debugPrint("$_tag: Error caching visions: $e");
      }

      return visions;
    } catch (e) {
      debugPrint("$_tag: Error fetching visions: $e");
      rethrow;
    }
  }

  // --- Shop Features ---

  Future<List<ShopItem>> getShopItems() async {
    return await _apiService.getShopItems();
  }

  Future<GiftResponse> purchaseShopItem(String itemId) async {
    return await _apiService.purchaseShopItem({'itemId': itemId});
  }

  Future<void> purchaseDailyBooster(String userId) async {
    await _generationRepo.purchaseDailyBooster(userId);
  }

  Future<UseItemResponse> useItem(String itemId) async {
    try {
      return await _apiService.useItem(UseItemRequest(itemId: itemId));
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return UseItemResponse.fromJson(e.response!.data);
        } catch (_) {}
      }
      return UseItemResponse(
        success: false,
        error: e.response?.data?['error'] ?? e.message ?? "Failed to use item",
      );
    } catch (e) {
      return UseItemResponse(success: false, error: e.toString());
    }
  }

  Future<List<InventoryItemModel>> getInventory({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedData = prefs.getString(_inventoryCacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedData);
          return decoded.map((e) => InventoryItemModel.fromJson(e)).toList();
        } catch (e) {
          debugPrint("$_tag: Error decoding cached inventory: $e");
        }
      }
    }

    try {
      final items = await _apiService.getInventory();
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_inventoryCacheKey, encoded);
      return items;
    } catch (e) {
      debugPrint("$_tag: Error fetching inventory: $e");
      // Fallback to cache even if forceRefresh was true but API failed
      final cachedData = prefs.getString(_inventoryCacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedData);
          return decoded.map((e) => InventoryItemModel.fromJson(e)).toList();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<GiftResponse> sendGift(String characterId, String itemId) async {
    return await _apiService.sendGift(
      GiftRequest(characterId: characterId, itemId: itemId),
    );
  }

  // --- Leaderboard Features ---

  Future<List<LeaderboardEntry>> getLeaderboard(String type) async {
    try {
      final docId = _getLeaderboardDocId(type);
      final doc = await FirebaseFirestore.instance
          .collection("leaderboards")
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = LeaderboardData.fromFirestore(doc.data()!);
        return data.entries;
      }
      return [];
    } catch (e) {
      debugPrint("$_tag: Error fetching leaderboard ($type): $e");
      return [];
    }
  }

  String _getLeaderboardDocId(String type) {
    if (type.startsWith('likes_')) return type;
    if (type.startsWith('downloads_')) return type;

    switch (type) {
      case 'weekly':
        return 'top_creators_weekly';
      case 'monthly':
        return 'top_creators_monthly';
      case 'all_time':
        return 'top_creators';
      case 'romancer':
        return 'top_romancers';
      case 'mvp':
        return 'community_mvp';
      case 'rising':
        return 'rising_stars';
      default:
        return type; // Allow direct docId as fallback
    }
  }

  // --- Engagement Features ---

  /// Redeem Promo Code (1000 Gems)
  Future<int> redeemCode(String code) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    final normalizedCode = code.trim().toUpperCase();
    final codeRef = FirebaseFirestore.instance
        .collection("redeem_codes")
        .doc(normalizedCode);
    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

    try {
      final rewardAmount = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final codeSnapshot = await transaction.get(codeRef);

        if (!codeSnapshot.exists) {
          throw Exception("Invalid code");
        }

        final data = codeSnapshot.data()!;
        // Check limit
        final maxRedemptions =
            (data['maxRedemptions'] as num?)?.toInt() ?? 999999;
        final currentRedemptions =
            (data['currentRedemptions'] as num?)?.toInt() ?? 0;

        if (currentRedemptions >= maxRedemptions) {
          throw Exception("Code limit reached");
        }

        // Check if user already redeemed
        final redeemedUsers = List<String>.from(data['redeemedUsers'] ?? []);
        if (redeemedUsers.contains(userId)) {
          throw Exception("You have already used this code");
        }

        final rewardGems = (data['rewardGems'] as num?)?.toInt() ?? 1000;

        // Execute
        transaction.update(userRef, {'gems': FieldValue.increment(rewardGems)});
        transaction.update(codeRef, {
          'currentRedemptions': FieldValue.increment(1),
          'redeemedUsers': FieldValue.arrayUnion([userId]),
        });

        return rewardGems;
      });

      debugPrint("$_tag: Code $normalizedCode redeemed by $userId");
      return rewardAmount;
    } catch (e) {
      debugPrint("$_tag: Error redeeming code: $e");
      rethrow;
    }
  }

  /// Request access for 'More' content
  Future<void> requestMoreAccess() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    try {
      final updates = {
        "moreRequestStatus": "pending",
        "updatedAt": Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection("generation_limits")
          .doc(userId)
          .update(updates);

      debugPrint("$_tag: More access requested for user: $userId");
    } catch (e) {
      debugPrint("$_tag: Error requesting more access: $e");
      rethrow;
    }
  }

  /// Toggle 'More' content enabled status in Firestore
  Future<void> toggleMoreEnabled(bool enabled) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    try {
      await FirebaseFirestore.instance
          .collection("generation_limits")
          .doc(userId)
          .update({"moreEnabled": enabled, "updatedAt": Timestamp.now()});

      debugPrint(
        "$_tag: More content enabled set to $enabled for user: $userId",
      );
    } catch (e) {
      debugPrint("$_tag: Error toggling more content: $e");
      rethrow;
    }
  }
}
