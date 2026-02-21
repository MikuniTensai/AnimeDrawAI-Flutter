import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    debugPrint("NativeAdCard: initState called");
    _loadAd();
  }

  void _loadAd() {
    debugPrint("NativeAdCard: _loadAd started");
    // We use a predefined template style
    final templateStyle = NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: Colors.transparent,
      cornerRadius: 12.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: Colors.blue, // Primary color
        style: NativeTemplateFontStyle.bold,
        size: 16.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.bold,
        size: 16.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.grey,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 14.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.grey,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 14.0,
      ),
    );

    _nativeAd = NativeAd(
      adUnitId: AdManager.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: templateStyle,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint("NativeAdCard: Ad loaded successfully");
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Native ad failed to load: ${error.message}");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isFailed = true;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    debugPrint("NativeAdCard: disposed");
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The placeholder must always maintain minimum bounds (e.g., 320 height)
    // to prevent the AdMob Validator from flagging the widget as too small.
    debugPrint(
      "NativeAdCard: building with height bounds (failed: $_isFailed, loaded: $_isLoaded)",
    );

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 320.0, maxHeight: 400.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: _isFailed
              ? Text(
                  "Ad Failed to Load",
                  style: TextStyle(color: theme.colorScheme.error),
                )
              : (_isLoaded && _nativeAd != null
                    ? AdWidget(ad: _nativeAd!)
                    : const CircularProgressIndicator()),
        ),
      ),
    );
  }
}
