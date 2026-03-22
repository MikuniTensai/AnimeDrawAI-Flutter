import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SubscriptionRepository(this.userId);

  DocumentReference get _userDoc => _firestore.collection("users").doc(userId);

  Stream<UserSubscription> getSubscriptionStream() {
    if (userId.isEmpty) return Stream.value(UserSubscription());

    return _userDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return UserSubscription();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return UserSubscription();

      // Manual mapping to handle enum strings safely
      final planName =
          data["subscriptionType"]?.toString().toLowerCase() ?? "free";
      SubscriptionPlan plan;
      try {
        plan = SubscriptionPlan.values.firstWhere(
          (e) => e.name.toLowerCase() == planName,
        );
      } catch (_) {
        plan = SubscriptionPlan.free;
      }

      return UserSubscription(
        plan: plan,
        generationUsed: data["generationUsed"] ?? 0,
        dailyGenerationCount: data["dailyGenerationCount"] ?? 0,
        lastGenerationDate: data["lastGenerationDate"] ?? "",
        subscriptionStartDate: data["subscriptionStartDate"] ?? "",
        expiryDate: data["subscriptionExpiryDate"],
        isActive: data["subscriptionActive"] ?? true,
        moreAccess: data["moreAccess"] ?? false,
      );
    });
  }

  Future<void> upgradePlan(
    SubscriptionPlan plan, {
    int durationMonths = 1,
  }) async {
    await activatePlanFromPurchase(
      plan,
      duration: Duration(days: 30 * durationMonths),
    );
  }

  Future<void> activatePlanFromPurchase(
    SubscriptionPlan plan, {
    DateTime? purchaseDate,
    Duration duration = const Duration(days: 30),
  }) async {
    _ensureUserId();

    final startDate = purchaseDate ?? DateTime.now();
    final expiryDate = startDate.add(duration);
    final subscriptionType = plan.name.toLowerCase();
    final subscriptionLimit = plan == SubscriptionPlan.pro ? 600 : 200;
    final limitDoc = _firestore.collection('generation_limits').doc(userId);

    final batch = _firestore.batch();
    batch.set(_userDoc, {
      "subscriptionType": subscriptionType,
      "subscriptionExpiryDate": expiryDate.toIso8601String(),
      "subscriptionActive": true,
      "generationUsed": 0,
      "dailyGenerationCount": 0,
      "subscriptionStartDate": startDate.toIso8601String(),
      "isPremium": true,
    }, SetOptions(merge: true));

    batch.set(limitDoc, {
      'subscriptionType': subscriptionType,
      'subscriptionEndDate': Timestamp.fromDate(expiryDate),
      'subscriptionLimit': subscriptionLimit,
      'subscriptionUsed': 0,
      'isPremium': true,
      'updatedAt': Timestamp.now(),
      'userId': userId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> recordGeneration() async {
    final snapshot = await _userDoc.get();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final data = snapshot.data() as Map<String, dynamic>?;
    final lastDate = data?["lastGenerationDate"] ?? "";
    final dailyCount = data?["dailyGenerationCount"] ?? 0;
    final totalUsed = data?["generationUsed"] ?? 0;

    final newDailyCount = (lastDate == today) ? dailyCount + 1 : 1;

    await _userDoc.update({
      "generationUsed": totalUsed + 1,
      "dailyGenerationCount": newDailyCount,
      "lastGenerationDate": today,
    });
  }

  Future<void> addChatLimit(int amount) async {
    // In a real production app, this should increment the custom chat limit
    // value in the `generation_limits` collection or equivalent.
    final limitDoc = _firestore.collection('generation_limits').doc(userId);
    final limitSnapshot = await limitDoc.get();

    if (limitSnapshot.exists) {
      final currentLimit = limitSnapshot.data()?['subscriptionLimit'] ?? 0;
      await limitDoc.update({'subscriptionLimit': currentLimit + amount});
    } else {
      await limitDoc.set({
        'subscriptionLimit': amount,
        'userId': userId,
      }, SetOptions(merge: true));
    }
  }

  Future<void> activateDayPass({DateTime? purchaseDate}) async {
    await activatePlanFromPurchase(
      SubscriptionPlan.basic,
      purchaseDate: purchaseDate,
      duration: const Duration(hours: 24),
    );
  }

  void _ensureUserId() {
    if (userId.isEmpty) {
      throw StateError('SubscriptionRepository requires a signed-in user.');
    }
  }
}
