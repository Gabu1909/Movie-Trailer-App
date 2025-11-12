import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart'; // Chúng ta sẽ tạo model này

class AuthProvider with ChangeNotifier {
  // Dùng Map để lưu trữ người dùng, mô phỏng database
  final Map<String, User> _users = {};
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> login(String email, String password) async {
    // Mô phỏng độ trễ mạng
    await Future.delayed(const Duration(seconds: 1));

    if (!_users.containsKey(email)) {
      throw 'User not found. Please register.';
    }

    final user = _users[email]!;
    if (user.password != password) {
      throw 'Incorrect password.';
    }

    _currentUser = user;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(email)) {
      throw 'An account with this email already exists.';
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password, // Trong thực tế, bạn phải mã hóa mật khẩu này
    );

    _users[email] = newUser;
    _currentUser = newUser;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserProfileImage(File imageFile) async {
    if (_currentUser != null) {
      // Trong ứng dụng thực tế, bạn sẽ tải ảnh này lên server
      // và nhận lại một URL. Ở đây, chúng ta chỉ lưu đường dẫn file local.
      _currentUser!.profileImageUrl = imageFile.path;
      notifyListeners();
    }
  }
}
