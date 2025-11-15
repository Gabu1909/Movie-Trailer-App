import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart'; // Chúng ta sẽ tạo model này

class AuthProvider with ChangeNotifier {
  // Dùng Map để lưu trữ người dùng, mô phỏng database
  Map<String, User> _users = {};
  User? _currentUser;
  static const String _usersKey = 'app_users';

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString(_usersKey);
    if (usersString != null) {
      _users = User.mapFromJson(json.decode(usersString));
    }
  }

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
    // Sau khi đăng ký, chúng ta không tự động đăng nhập
    // mà yêu cầu người dùng đến màn hình đăng nhập.
    // _currentUser = newUser;
    await _saveUsers();
    notifyListeners();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, json.encode(User.mapToJson(_users)));
  }

  Future<void> logout() async {
    _currentUser = null;
    // Không cần xóa user khỏi _users khi đăng xuất
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
