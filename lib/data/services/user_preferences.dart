import 'package:shared_preferences/shared_preferences.dart';

/// Manages user preferences stored locally using SharedPreferences.
/// Equivalent to Android's UserPreferences class.
class UserPreferences {
  static const String _keyGalleryPin = 'gallery_pin';
  static const String _keyGalleryPinEnabled = 'gallery_pin_enabled';
  static const String _keyAgeVerified = 'age_verified';
  static const String _keyAgeVerifiedDate = 'age_verified_date';
  static const String _keyNsfwEnabled = 'nsfw_enabled';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keySelectedLanguage = 'selected_language';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLastDailyRewardDate = 'last_daily_reward_date';
  static const String _keyTotalGenerations = 'total_generations_local';

  // ─── Gallery PIN ──────────────────────────────────────────────────────────

  Future<String?> getGalleryPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGalleryPin);
  }

  Future<void> setGalleryPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGalleryPin, pin);
    await prefs.setBool(_keyGalleryPinEnabled, true);
  }

  Future<void> clearGalleryPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGalleryPin);
    await prefs.setBool(_keyGalleryPinEnabled, false);
  }

  Future<bool> isGalleryPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGalleryPinEnabled) ?? false;
  }

  Future<bool> verifyGalleryPin(String pin) async {
    final stored = await getGalleryPin();
    return stored != null && stored == pin;
  }

  // ─── Age Verification ─────────────────────────────────────────────────────

  Future<bool> isAgeVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAgeVerified) ?? false;
  }

  Future<void> setAgeVerified(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAgeVerified, verified);
    if (verified) {
      await prefs.setString(
        _keyAgeVerifiedDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  Future<DateTime?> getAgeVerifiedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyAgeVerifiedDate);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  // ─── NSFW ─────────────────────────────────────────────────────────────────

  Future<bool> isNsfwEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNsfwEnabled) ?? false;
  }

  Future<void> setNsfwEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNsfwEnabled, enabled);
  }

  // ─── Onboarding ───────────────────────────────────────────────────────────

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  // ─── Language ─────────────────────────────────────────────────────────────

  Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedLanguage) ?? 'id'; // Default: Indonesian
  }

  Future<void> setSelectedLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedLanguage, languageCode);
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // ─── Dark Mode ────────────────────────────────────────────────────────────

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? true; // Default: dark
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
  }

  // ─── Daily Reward ─────────────────────────────────────────────────────────

  Future<String?> getLastDailyRewardDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastDailyRewardDate);
  }

  Future<void> setLastDailyRewardDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDailyRewardDate, date);
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Future<int> getTotalGenerationsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalGenerations) ?? 0;
  }

  Future<void> incrementTotalGenerationsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalGenerations) ?? 0;
    await prefs.setInt(_keyTotalGenerations, current + 1);
  }

  // ─── Clear All ────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
