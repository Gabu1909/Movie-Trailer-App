import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadQuality { high, medium, low }

enum AppThemeMode { light, dark, system }

class SettingsProvider with ChangeNotifier {
  static const String _soundKey = 'sound_enabled';
  static const String _hapticsKey = 'haptics_enabled';
  static const String _qualityKey = 'download_quality';
  static const String _themeModeKey = 'theme_mode';

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  DownloadQuality _downloadQuality = DownloadQuality.medium;
  AppThemeMode _themeMode = AppThemeMode.dark;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  DownloadQuality get downloadQuality => _downloadQuality;
  AppThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  // Tải cài đặt từ SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true; // Mặc định là bật
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true; // Mặc định là bật
    final qualityIndex =
        prefs.getInt(_qualityKey) ?? DownloadQuality.medium.index;
    _downloadQuality = DownloadQuality.values[qualityIndex];
    final themeModeIndex =
        prefs.getInt(_themeModeKey) ?? AppThemeMode.dark.index;
    _themeMode = AppThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  // Lưu cài đặt vào SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
    await prefs.setBool(_hapticsKey, _hapticsEnabled);
    await prefs.setInt(_qualityKey, _downloadQuality.index);
    await prefs.setInt(_themeModeKey, _themeMode.index);
  }

  // Bật/tắt âm thanh
  void toggleSound(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  // Bật/tắt rung
  void toggleHaptics(bool value) {
    _hapticsEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  // Thay đổi chất lượng tải xuống
  void setDownloadQuality(DownloadQuality quality) {
    _downloadQuality = quality;
    _saveSettings();
    notifyListeners();
  }

  // Thay đổi chế độ sáng/tối
  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  // Toggle giữa Light và Dark mode
  void toggleTheme() {
    if (_themeMode == AppThemeMode.dark) {
      _themeMode = AppThemeMode.light;
    } else {
      _themeMode = AppThemeMode.dark;
    }
    _saveSettings();
    notifyListeners();
  }
}
