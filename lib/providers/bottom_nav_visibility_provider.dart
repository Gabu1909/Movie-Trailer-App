import 'package:flutter/material.dart';
import 'dart:async';

class BottomNavVisibilityProvider with ChangeNotifier {
  bool _isVisible = true;
  bool get isVisible => _isVisible;

  Timer? _hideTimer;

  void show() {}

  void hide() {}

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
