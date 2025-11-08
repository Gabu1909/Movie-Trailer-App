import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadQuality { high, medium, low }

class SettingsProvider with ChangeNotifier {
  static const String _soundKey = 'sound_enabled';
  static const String _hapticsKey = 'haptics_enabled';
  static const String _qualityKey = 'download_quality';

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  DownloadQuality _downloadQuality = DownloadQuality.medium;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  DownloadQuality get downloadQuality => _downloadQuality;

  SettingsProvider() {
    _loadSettings();
  }

  // Tải cài đặt từ SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true; // Mặc định là bật
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true; // Mặc định là bật
    final qualityIndex = prefs.getInt(_qualityKey) ?? DownloadQuality.medium.index;
    _downloadQuality = DownloadQuality.values[qualityIndex];
    notifyListeners();
  }

  // Lưu cài đặt vào SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
    await prefs.setBool(_hapticsKey, _hapticsEnabled);
    await prefs.setInt(_qualityKey, _downloadQuality.index);
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
}