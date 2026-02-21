import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyDarkMode = "isDarkMode";
  static const String _keyAutoSave = "isAutoSave";
  static const String _keyFirstLaunch = "isFirstLaunch";
  static const String _keyThemeColor = "themeColor";
  static const String _keyNotifications = "isNotificationsEnabled";
  static const String _keyReminderTime = "reminderTime";
  static const String _keyRestrictedContent = "isRestrictedContentEnabled";
  static const String _keyAgeVerified = "isAgeVerified";
  static const String _keyGalleryPin = "galleryPin";

  bool _isDarkMode = true;
  bool _isAutoSave = true;
  bool _isFirstLaunch = true;
  Color _themeColor = const Color(0xFF6650a4);
  bool _isNotificationsEnabled = true;
  String _reminderTime = "20:00"; // Format: HH:mm
  bool _isRestrictedContentEnabled = false;
  bool _isAgeVerified = false;
  String? _galleryPin;

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isAutoSave => _isAutoSave;
  bool get isFirstLaunch => _isFirstLaunch;
  Color get themeColor => _themeColor;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  String get reminderTime => _reminderTime;
  bool get isRestrictedContentEnabled => _isRestrictedContentEnabled;
  bool get isAgeVerified => _isAgeVerified;
  String? get galleryPin => _galleryPin;
  bool get isGalleryLocked => _galleryPin != null && _galleryPin!.isNotEmpty;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
    _isAutoSave = prefs.getBool(_keyAutoSave) ?? true;
    _isFirstLaunch = prefs.getBool(_keyFirstLaunch) ?? true;
    _isNotificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    _reminderTime = prefs.getString(_keyReminderTime) ?? "20:00";
    _isRestrictedContentEnabled = prefs.getBool(_keyRestrictedContent) ?? false;
    _isAgeVerified = prefs.getBool(_keyAgeVerified) ?? false;
    _galleryPin = prefs.getString(_keyGalleryPin);

    final colorValue = prefs.getInt(_keyThemeColor);
    if (colorValue != null) {
      _themeColor = Color(colorValue);
    }

    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeColor, color.toARGB32());
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> toggleAutoSave(bool value) async {
    _isAutoSave = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSave, value);
    notifyListeners();
  }

  Future<void> setFirstLaunchComplete() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _isNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final timeStr =
        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
    _reminderTime = timeStr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderTime, timeStr);
    notifyListeners();
  }

  Future<void> setRestrictedContent(bool value) async {
    _isRestrictedContentEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRestrictedContent, value);
    notifyListeners();
  }

  Future<void> setAgeVerified(bool value) async {
    _isAgeVerified = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAgeVerified, value);
    notifyListeners();
  }

  Future<void> setGalleryPin(String? pin) async {
    _galleryPin = pin;
    final prefs = await SharedPreferences.getInstance();
    if (pin == null) {
      await prefs.remove(_keyGalleryPin);
    } else {
      await prefs.setString(_keyGalleryPin, pin);
    }
    notifyListeners();
  }
}
