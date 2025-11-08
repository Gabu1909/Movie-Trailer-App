import 'package:flutter/material.dart';
import 'dart:async'; // Import Timer

/// Provider để quản lý trạng thái hiển thị của BottomNavigationBar.
class BottomNavVisibilityProvider with ChangeNotifier {
  bool _isVisible = true;
  // Luôn trả về true để thanh điều hướng luôn hiển thị.
  bool get isVisible => _isVisible;

  Timer? _hideTimer;

  /// Hiển thị thanh điều hướng.
  void show() {
    // Không làm gì cả
  }

  /// Ẩn thanh điều hướng và bắt đầu một timer để tự động hiện lại.
  void hide() {
    // Không làm gì cả
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
