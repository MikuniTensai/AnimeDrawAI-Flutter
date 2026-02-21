import 'package:flutter/foundation.dart';
import 'ad_manager.dart';

class AdHelper {
  static const int _interstitialCooldownMs =
      120000; // 2 minutes in milliseconds
  static int _lastInterstitialTime = 0;

  /// Show interstitial ad after successful image save/download
  /// with cooldown to avoid annoying users
  static void showAdAfterSave({Function? onCompleted}) {
    final int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check cooldown
    if (currentTime - _lastInterstitialTime < _interstitialCooldownMs) {
      debugPrint("AdHelper: Interstitial ad on cooldown, skipping");
      onCompleted?.call();
      return;
    }

    if (AdManager.isInterstitialAdReady()) {
      _lastInterstitialTime = currentTime;
      AdManager.showInterstitialAd(
        onAdDismissed: () {
          debugPrint("AdHelper: Interstitial ad shown after save");
          onCompleted?.call();
        },
      );
    } else {
      // Load for next time
      AdManager.loadInterstitialAd();
      debugPrint("AdHelper: Interstitial ad not ready, loading for next time");
      onCompleted?.call();
    }
  }

  /// Preload interstitial ad for next save action
  static void preloadInterstitialAd() {
    if (!AdManager.isInterstitialAdReady()) {
      AdManager.loadInterstitialAd();
    }
  }
}
