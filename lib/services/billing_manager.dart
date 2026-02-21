import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/models/subscription_model.dart';

class BillingManager extends ChangeNotifier {
  static const String kBasicProductId = "anime_draw_basic_monthly";
  static const String kProProductId = "anime_draw_pro_monthly";
  static const String kChatRandomProductId = "anime_draw_chat_random";
  static const String kChat1ProductId = "anime_draw_chat_1";
  static const String kOneDayProductId = "anime_draw_1_day";

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final SubscriptionRepository _subscriptionRepo;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  // Dynamic values that default to fallback values if the store fetch fails
  String _basicPrice = "IDR 69,000";
  String _proPrice = "IDR 149,000";
  String _chatRandomPrice = "IDR 10,000";
  String _chat1Price = "IDR 3,000";
  String _oneDayPrice =
      "IDR 3,000"; // Setting strictly based on user request ('3ribu')

  String get basicPrice => _basicPrice;
  String get proPrice => _proPrice;
  String get chatRandomPrice => _chatRandomPrice;
  String get chat1Price => _chat1Price;
  String get oneDayPrice => _oneDayPrice;

  Function(String resultMessage)? onPurchaseResult;
  Function(int gachaResult)? onGachaResult;

  BillingManager(this._subscriptionRepo) {
    _initialize();
  }

  void _initialize() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint("Billing stream error: $error");
      },
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      notifyListeners();
      return;
    }

    const Set<String> kIds = {
      kBasicProductId,
      kProProductId,
      kChatRandomProductId,
      kChat1ProductId,
      kOneDayProductId,
    };

    final ProductDetailsResponse response = await _iap.queryProductDetails(
      kIds,
    );
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Products missing in store: ${response.notFoundIDs}");
    }

    _products = response.productDetails;
    for (var prod in _products) {
      switch (prod.id) {
        case kBasicProductId:
          _basicPrice = prod.price;
          break;
        case kProProductId:
          _proPrice = prod.price;
          break;
        case kChatRandomProductId:
          _chatRandomPrice = prod.price;
          break;
        case kChat1ProductId:
          _chat1Price = prod.price;
          break;
        case kOneDayProductId:
          _oneDayPrice = prod.price;
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("Purchase pending: ${purchaseDetails.productID}");
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase error: ${purchaseDetails.error}");
          onPurchaseResult?.call(
            "Purchase failed: ${purchaseDetails.error?.message}",
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _deliverProduct(purchaseDetails);
          } else {
            onPurchaseResult?.call("Purchase verification failed.");
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Basic local stub for receipt validation.
    // In production, send `purchaseDetails.verificationData.serverVerificationData` to backend.
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final String pid = purchaseDetails.productID;

    try {
      if (pid == kBasicProductId) {
        await _subscriptionRepo.upgradePlan(SubscriptionPlan.basic);
        onPurchaseResult?.call("Upgraded to BASIC plan.");
      } else if (pid == kProProductId) {
        await _subscriptionRepo.upgradePlan(SubscriptionPlan.pro);
        onPurchaseResult?.call("Upgraded to PRO plan.");
      } else if (pid == kChat1ProductId) {
        await _subscriptionRepo.addChatLimit(1);
        onPurchaseResult?.call("Added 1 Chat Slot.");
      } else if (pid == kChatRandomProductId) {
        final rand = Random();
        final isJackpot = rand.nextInt(100) < 10; // 10% chance
        final amount = isJackpot ? 9 : (rand.nextInt(8) + 1); // 1 to 8
        await _subscriptionRepo.addChatLimit(amount);
        onGachaResult?.call(amount);
      } else if (pid == kOneDayProductId) {
        await _subscriptionRepo.activateDayPass();
        onPurchaseResult?.call("1-Day Premium Access Activated!");
      }
    } catch (e) {
      debugPrint("Error delivering product: $e");
      onPurchaseResult?.call(
        "Item purchased, but failed to apply to account ($e). Please contact support.",
      );
    }
  }

  Future<void> buyProduct(String productId) async {
    final ProductDetails? product = _products
        .where((p) => p.id == productId)
        .firstOrNull;
    if (product != null) {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      // Determine if consumable (Chat limits and One day pass are consumables)
      final bool isConsumable =
          productId == kChatRandomProductId ||
          productId == kChat1ProductId ||
          productId == kOneDayProductId;

      if (isConsumable) {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } else {
      // Allow fallback testing if not in store
      debugPrint(
        "Product not found in store details, attempting simulated purchase flow callback.",
      );
      onPurchaseResult?.call(
        "Product not found in Google Play/App Store context.",
      );
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
