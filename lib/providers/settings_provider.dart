import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadQuality { high, medium, low }

class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _downloadQualityKey = 'download_quality';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';

  String _themeId = 'midnight_purple';
  DownloadQuality _downloadQuality = DownloadQuality.medium;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  String get themeId => _themeId;
  DownloadQuality get downloadQuality => _downloadQuality;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeValue = prefs.get(_themeModeKey);
      if (themeValue is String) {
        _themeId = themeValue;
      } else {
        _themeId = 'midnight_purple';
      }

      final qualityValue = prefs.get(_downloadQualityKey);
      String qualityString = 'medium';
      if (qualityValue is String) {
        qualityString = qualityValue;
      }
      _downloadQuality = DownloadQuality.values.firstWhere(
          (e) => e.toString().split('.').last == qualityString,
          orElse: () => DownloadQuality.medium);

      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;

      notifyListeners();
    } catch (e) {
      _themeId = 'midnight_purple';
      _downloadQuality = DownloadQuality.medium;
      _soundEnabled = true;
      _hapticsEnabled = true;
      notifyListeners();
    }
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

enum AppThemeMode { light, dark, system }
