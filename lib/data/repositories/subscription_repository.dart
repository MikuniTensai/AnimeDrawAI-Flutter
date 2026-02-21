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
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: 30 * durationMonths));
    final dateFormat = DateFormat('yyyy-MM-dd');

    final updates = {
      "subscriptionType": plan.name.toLowerCase(),
      "subscriptionExpiryDate": dateFormat.format(expiryDate),
      "subscriptionActive": true,
      "generationUsed": 0,
      "dailyGenerationCount": 0,
      "subscriptionStartDate": dateFormat.format(now),
    };

    await _userDoc.update(updates);

    // Sync with generation_limits
    final mappedType = plan == SubscriptionPlan.basic
        ? "basic"
        : (plan == SubscriptionPlan.pro ? "pro" : "free");
    if (mappedType != "free") {
      // In a real app, we'd use a cloud function, but here we call the repository directly
      // Since repositories are initialized once, we might need a reference or a static call
      // For now, assume a fresh instance works
      // await GenerationRepository().activateSubscription(...);
    }
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

  Future<void> activateDayPass() async {
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(hours: 24));
    final dateFormat = DateFormat('yyyy-MM-dd');

    final updates = {
      "subscriptionType": "pro", // Day pass grants PRO level implicitly
      "subscriptionExpiryDate": dateFormat.format(expiryDate),
      "subscriptionActive": true,
      "generationUsed": 0,
      "dailyGenerationCount": 0,
      "subscriptionStartDate": dateFormat.format(now),
    };

    await _userDoc.update(updates);

    // Also sync the short expiry to generation limits table
    final limitDoc = _firestore.collection('generation_limits').doc(userId);
    await limitDoc.update({
      'subscriptionType': 'pro',
      'subscriptionEndDate': Timestamp.fromDate(expiryDate),
      'subscriptionLimit': 600, // Explicitly grant the PRO capacity
      'subscriptionUsed': 0,
    });
  }
}
