import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadQuality { high, medium, low } // Giữ nguyên

class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _downloadQualityKey = 'download_quality';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';

  // Trạng thái hiện tại
  String _themeId = 'midnight_purple'; // ID của theme mặc định
  DownloadQuality _downloadQuality = DownloadQuality.medium;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  // Getters
  String get themeId => _themeId;
  DownloadQuality get downloadQuality => _downloadQuality;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString(_themeModeKey) ?? 'midnight_purple';

    final qualityString = prefs.getString(_downloadQualityKey) ?? 'medium';
    _downloadQuality = DownloadQuality.values
        .firstWhere((e) => e.toString().split('.').last == qualityString);

    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;

    notifyListeners();
  }

  Future<void> setTheme(String themeId) async {
    if (_themeId == themeId) return;
    _themeId = themeId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeId);
  }

  Future<void> setDownloadQuality(DownloadQuality quality) async {
    if (_downloadQuality == quality) return;
    _downloadQuality = quality;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _downloadQualityKey, quality.toString().split('.').last);
  }

  Future<void> toggleSound(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<void> toggleHaptics(bool enabled) async {
    _hapticsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, enabled);
  }
}

// Chuyển enum này ra ngoài để tránh lỗi
enum AppThemeMode { light, dark, system }
