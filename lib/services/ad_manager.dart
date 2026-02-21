import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  // Production Ad Unit IDs
  static const String _interstitialAdUnitIdProduction =
      "ca-app-pub-8770525488772470/2618698168";
  static const String _appOpenAdUnitIdProduction =
      "ca-app-pub-8770525488772470/2626722433";
  static const String _bannerAdUnitIdProduction =
      "ca-app-pub-8770525488772470/2600540385";
  static const String _rewardedAdUnitIdProduction =
      "ca-app-pub-8770525488772470/5373139420";
  static const String _nativeAdUnitIdProduction =
      "ca-app-pub-8770525488772470/1059990638";

  // Test Ad Unit IDs (Google's official test ads)
  static const String _interstitialAdUnitIdTest =
      "ca-app-pub-3940256099942544/1033173712";
  static const String _appOpenAdUnitIdTest =
      "ca-app-pub-3940256099942544/9257395921";
  static const String _bannerAdUnitIdTest =
      "ca-app-pub-3940256099942544/6300978111";
  static const String _rewardedAdUnitIdTest =
      "ca-app-pub-3940256099942544/5224354917";
  static const String _nativeAdUnitIdTest =
      "ca-app-pub-3940256099942544/2247696110";

  static String get interstitialAdUnitId {
    if (kDebugMode && Platform.isAndroid) return _interstitialAdUnitIdTest;
    return _interstitialAdUnitIdProduction;
  }

  static String get appOpenAdUnitId {
    if (kDebugMode && Platform.isAndroid) return _appOpenAdUnitIdTest;
    return _appOpenAdUnitIdProduction;
  }

  static String get bannerAdUnitId {
    if (kDebugMode && Platform.isAndroid) return _bannerAdUnitIdTest;
    return _bannerAdUnitIdProduction;
  }

  static String get rewardedAdUnitId {
    if (kDebugMode && Platform.isAndroid) return _rewardedAdUnitIdTest;
    return _rewardedAdUnitIdProduction;
  }

  static String get nativeAdUnitId {
    if (kDebugMode && Platform.isAndroid) return _nativeAdUnitIdTest;
    return _nativeAdUnitIdProduction;
  }

  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;
  static RewardedAd? _rewardedAd;

  static bool _isShowingAppOpenAd = false;
  static bool _isLoadingInterstitialAd = false;
  static bool _isLoadingRewardedAd = false;

  /// Initialize AdMob SDK.
  static Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.instance.initialize();
      // Test devices configuration can be set here if needed like Android did
      debugPrint("========================================");
      debugPrint("🎬 AdMob Initialized Successfully!");
      debugPrint("📱 Mode: ${kDebugMode ? "TEST ADS" : "PRODUCTION ADS"}");
      debugPrint("========================================");
    }
  }

  // ==========================================
  // INTERSTITIAL AD
  // ==========================================

  static void loadInterstitialAd({Function? onAdLoaded}) {
    if (_interstitialAd != null || _isLoadingInterstitialAd) return;
    _isLoadingInterstitialAd = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("Interstitial ad loaded");
          _interstitialAd = ad;
          _isLoadingInterstitialAd = false;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint("Interstitial ad failed to load: ${error.message}");
          _interstitialAd = null;
          _isLoadingInterstitialAd = false;
        },
      ),
    );
  }

  static void showInterstitialAd({Function? onAdDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("Interstitial ad dismissed");
          ad.dispose();
          _interstitialAd = null;
          onAdDismissed?.call();
          // Preload next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("Interstitial ad failed to show: ${error.message}");
          ad.dispose();
          _interstitialAd = null;
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint("Interstitial ad showed");
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint("Interstitial ad not ready");
      onAdDismissed?.call();
      loadInterstitialAd();
    }
  }

  static bool isInterstitialAdReady() => _interstitialAd != null;

  // ==========================================
  // APP OPEN AD
  // ==========================================

  static void loadAppOpenAd({Function? onAdLoaded}) {
    if (_appOpenAd != null || _isShowingAppOpenAd) return;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("App open ad loaded");
          _appOpenAd = ad;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint("App open ad failed to load: ${error.message}");
          _appOpenAd = null;
        },
      ),
    );
  }

  static void showAppOpenAd({Function? onAdDismissed}) {
    if (_appOpenAd != null && !_isShowingAppOpenAd) {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("App open ad dismissed");
          ad.dispose();
          _appOpenAd = null;
          _isShowingAppOpenAd = false;
          onAdDismissed?.call();
          loadAppOpenAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("App open ad failed to show: ${error.message}");
          ad.dispose();
          _appOpenAd = null;
          _isShowingAppOpenAd = false;
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint("App open ad showed");
          _isShowingAppOpenAd = true;
        },
      );
      _appOpenAd!.show();
    } else {
      debugPrint("App open ad not ready or already showing");
      onAdDismissed?.call();
      if (!_isShowingAppOpenAd) {
        loadAppOpenAd();
      }
    }
  }

  static bool isAppOpenAdReady() => _appOpenAd != null && !_isShowingAppOpenAd;

  // ==========================================
  // REWARDED AD
  // ==========================================

  static void loadRewardedAd({Function? onAdLoaded}) {
    if (_rewardedAd != null || _isLoadingRewardedAd) return;
    _isLoadingRewardedAd = true;
    debugPrint("🔄 Loading rewarded ad...");

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("========================================");
          debugPrint("✅ Rewarded Ad Loaded Successfully!");
          debugPrint("🎬 Ad is ready to show");
          debugPrint("========================================");
          _rewardedAd = ad;
          _isLoadingRewardedAd = false;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint("❌ Rewarded Ad Failed to Load: ${error.message}");
          _rewardedAd = null;
          _isLoadingRewardedAd = false;
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(int) onUserEarnedReward,
    Function? onAdDismissed,
  }) {
    if (_rewardedAd != null) {
      debugPrint("🎬 Showing rewarded ad...");

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("✅ Rewarded Ad Dismissed");
          ad.dispose();
          _rewardedAd = null;
          onAdDismissed?.call();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("❌ Rewarded Ad Failed to Show: ${error.message}");
          ad.dispose();
          _rewardedAd = null;
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint("🎬 Rewarded Ad Showing Now!");
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint("========================================");
          debugPrint("🎁 REWARD EARNED!");
          debugPrint("Amount: ${reward.amount}");
          debugPrint("Type: ${reward.type}");
          debugPrint("========================================");
          // Android reward was usually 1 generation. We pipe it through.
          onUserEarnedReward(reward.amount.toInt());
        },
      );
    } else {
      debugPrint("⚠️ Rewarded Ad Not Ready. Loading ad now...");
      onAdDismissed?.call();
      loadRewardedAd();
    }
  }

  // ==========================================
  // BANNER AD
  // ==========================================

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint("Banner ad loaded"),
        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner ad failed to load: ${error.message}");
          ad.dispose();
        },
      ),
    );
  }

  // ==========================================
  // NATIVE AD
  // ==========================================

  static NativeAd createNativeAd({required NativeTemplateStyle templateStyle}) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: templateStyle,
      listener: NativeAdListener(
        onAdLoaded: (ad) => debugPrint("Native ad loaded"),
        onAdFailedToLoad: (ad, error) {
          debugPrint("Native ad failed to load: ${error.message}");
          ad.dispose();
        },
      ),
    );
  }
}
