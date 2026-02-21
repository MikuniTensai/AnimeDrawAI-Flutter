import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/generation_limit_model.dart';

class GenerationRepository {
  static const String _collectionLimits = "generation_limits";
  static const int _freeUserDailyLimit = 5;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<void> _expirationController =
      StreamController.broadcast();

  Stream<void> get onSubscriptionExpired => _expirationController.stream;

  Future<GenerationLimit> getGenerationLimit(String userId) async {
    try {
      final docRef = _firestore.collection(_collectionLimits).doc(userId);
      final snapshot = await docRef.get();

      // Fetch latest subscription status from 'users' collection for sync
      final userDoc = await _firestore.collection("users").doc(userId).get();
      String? actualSubscriptionType;
      DateTime? subscriptionEndDate;
      int? subscriptionLimit;

      if (userDoc.exists) {
        final userData = userDoc.data();
        actualSubscriptionType =
            (userData?["subscriptionType"]?.toString().toLowerCase()) ?? "free";
        final expiry = userData?["subscriptionExpiryDate"];
        if (expiry is String) {
          subscriptionEndDate = DateTime.tryParse(expiry);
        } else if (expiry is Timestamp) {
          subscriptionEndDate = expiry.toDate();
        }

        // Check for expiration
        if (subscriptionEndDate != null &&
            subscriptionEndDate.isBefore(DateTime.now())) {
          debugPrint("Subscription expired for $userId. Downgrading to FREE.");
          final batch = _firestore.batch();

          batch.update(_firestore.collection("users").doc(userId), {
            "subscriptionType": "free",
            "isPremium": false,
            "subscriptionActive": false,
            "subscriptionExpiryDate": null,
          });

          batch.set(docRef, {
            "subscriptionType": "free",
            "maxDailyLimit": _freeUserDailyLimit,
            "subscriptionLimit": 0,
            "subscriptionUsed": 0,
            "dailyGenerations": 0,
            "isPremium": false,
            "subscriptionEndDate": null,
          }, SetOptions(merge: true));

          await batch.commit();
          actualSubscriptionType = "free";
          subscriptionEndDate = null;
          // Notify listeners about expiration
          _expirationController.add(null);
        }

        // Set limits if missing or zero in users collection (fallbacks)
        if (actualSubscriptionType == "pro") {
          subscriptionLimit = 600;
        } else if (actualSubscriptionType == "basic") {
          subscriptionLimit = 200;
        } else {
          subscriptionLimit = 0;
        }
      }

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data == null) throw Exception("Empty limit data");

        var limit = GenerationLimit.fromJson(data);

        // SYNC: Check if subscription type in 'generation_limits' matches 'users' collection
        // Safeguard: Only sync if we explicitly found a plan in the users doc
        if (actualSubscriptionType != null &&
            actualSubscriptionType.isNotEmpty &&
            actualSubscriptionType != limit.subscriptionType) {
          debugPrint(
            "Syncing subscription: ${limit.subscriptionType} -> $actualSubscriptionType",
          );
          final updates = {
            "subscriptionType": actualSubscriptionType,
            "isPremium": actualSubscriptionType != "free",
            "subscriptionEndDate": subscriptionEndDate != null
                ? Timestamp.fromDate(subscriptionEndDate)
                : null,
            "subscriptionLimit": subscriptionLimit ?? limit.subscriptionLimit,
            "updatedAt": Timestamp.now(),
          };
          await docRef.update(updates);
          limit = limit.copyWith(
            subscriptionType: actualSubscriptionType,
            isPremium: actualSubscriptionType != "free",
            subscriptionEndDate: subscriptionEndDate,
            subscriptionLimit: subscriptionLimit ?? limit.subscriptionLimit,
          );
        }

        // Auto-fix inconsistency (redundant but safe)
        if (!limit.isPremium && limit.subscriptionType != "free") {
          await docRef.update({"isPremium": true});
          limit = limit.copyWith(isPremium: true);
        }

        // Auto-fix maxDailyLimit for free users
        if (limit.subscriptionType == "free" &&
            limit.maxDailyLimit < _freeUserDailyLimit) {
          await docRef.update({"maxDailyLimit": _freeUserDailyLimit});
          limit = limit.copyWith(maxDailyLimit: _freeUserDailyLimit);
        }

        // Check if needs reset
        final currentDate = _getCurrentDate();
        if (limit.needsReset(currentDate)) {
          return await resetDailyLimit(userId);
        }

        return limit;
      } else {
        final newLimit = await _createGenerationLimit(userId);
        // If we found subscription info in the users doc, sync it immediately
        if (actualSubscriptionType != null &&
            actualSubscriptionType != "free") {
          await docRef.update({
            "subscriptionType": actualSubscriptionType,
            "isPremium": true,
            "subscriptionEndDate": subscriptionEndDate != null
                ? Timestamp.fromDate(subscriptionEndDate)
                : null,
            "subscriptionLimit": subscriptionLimit ?? 0,
          });
          return newLimit.copyWith(
            subscriptionType: actualSubscriptionType,
            isPremium: true,
            subscriptionEndDate: subscriptionEndDate,
            subscriptionLimit: subscriptionLimit ?? 0,
          );
        }
        return newLimit;
      }
    } catch (e) {
      debugPrint("Error getting generation limit: $e");
      rethrow;
    }
  }

  Future<GenerationLimit> _createGenerationLimit(String userId) async {
    final currentDate = _getCurrentDate();
    final now = DateTime.now();

    final newLimit = GenerationLimit(
      userId: userId,
      dailyGenerations: 0,
      maxDailyLimit: _freeUserDailyLimit,
      lastResetDate: currentDate,
      isPremium: false,
      totalGenerations: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(_collectionLimits)
        .doc(userId)
        .set(newLimit.toJson());
    return newLimit;
  }

  Future<GenerationLimit> checkAndIncrementGeneration(String userId) async {
    final limit = await getGenerationLimit(userId);

    if (!limit.canGenerate()) {
      throw Exception(
        "Daily generation limit reached (${limit.maxDailyLimit}).",
      );
    }

    final docRef = _firestore.collection(_collectionLimits).doc(userId);
    final isFree = limit.subscriptionType == "free";

    final updates = {
      isFree ? "dailyGenerations" : "subscriptionUsed": FieldValue.increment(1),
      "totalGenerations": FieldValue.increment(1),
      "updatedAt": Timestamp.now(),
    };

    await docRef.update(updates);
    return await getGenerationLimit(userId);
  }

  Future<GenerationLimit> resetDailyLimit(String userId) async {
    final currentDate = _getCurrentDate();
    final updates = {
      "dailyGenerations": 0,
      "bonusGenerations": 0,
      "purchasedGenerations": 0,
      "lastResetDate": currentDate,
      "updatedAt": Timestamp.now(),
    };

    await _firestore.collection(_collectionLimits).doc(userId).update(updates);
    return await getGenerationLimit(userId);
  }

  Future<void> addBonusGeneration(String userId) async {
    final limit = await getGenerationLimit(userId);
    if (limit.subscriptionType == "free" && limit.bonusGenerations >= 50) {
      throw Exception("Maximum bonus generations reached (50)");
    }

    await _firestore.collection(_collectionLimits).doc(userId).update({
      "bonusGenerations": FieldValue.increment(1),
      "updatedAt": Timestamp.now(),
    });
  }

  /// Purchase Daily Limit Booster
  /// Cost: 50 Gems -> Reward: +5 Generations (This day only)
  Future<void> purchaseDailyBooster(String userId) async {
    final userRef = _firestore.collection("users").doc(userId);
    final limitRef = _firestore.collection(_collectionLimits).doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) throw Exception("User not found");

      // 1. Check Gems
      final data = userSnapshot.data();
      final currentGems = (data?['gems'] as num?)?.toInt() ?? 0;
      if (currentGems < 50) {
        throw Exception("Insufficient gems. You need 50 gems.");
      }

      // 2. Deduct Gems
      transaction.update(userRef, {'gems': currentGems - 50});

      // 3. Increment usage limit (purchasedGenerations)
      transaction.set(limitRef, {
        'purchasedGenerations': FieldValue.increment(5),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Stream<GenerationLimit> getGenerationLimitStream(String userId) {
    // Fire and forget sync to ensure the stream gets the latest data
    getGenerationLimit(userId).catchError((e) {
      debugPrint("Error syncing generation limit: $e");
      return GenerationLimit();
    });

    return _firestore.collection(_collectionLimits).doc(userId).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return GenerationLimit();
        return GenerationLimit.fromJson(snapshot.data()!);
      },
    );
  }
}
