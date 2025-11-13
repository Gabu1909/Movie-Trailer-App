import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  // Dùng Map để lưu trữ người dùng theo email, mô phỏng database
  final Map<String, User> _users = {};
  // Map để tra cứu username -> email
  final Map<String, String> _usernameToEmail = {};
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Khởi tạo và load dữ liệu từ SharedPreferences
  AuthProvider() {
    _loadFromPrefs();
  }

  // Load dữ liệu người dùng từ SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load danh sách users
    final usersJson = prefs.getString('users');
    if (usersJson != null) {
      final Map<String, dynamic> decoded = json.decode(usersJson);
      decoded.forEach((email, userData) {
        final user = User.fromJson(userData);
        _users[email] = user;
        _usernameToEmail[user.username] = email; // Build username map
      });
    }

    // Load current user
    final currentUserEmail = prefs.getString('currentUserEmail');
    if (currentUserEmail != null && _users.containsKey(currentUserEmail)) {
      _currentUser = _users[currentUserEmail];
      notifyListeners();
    }
  }

  // Lưu dữ liệu vào SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Lưu danh sách users
    final Map<String, dynamic> usersMap = {};
    _users.forEach((email, user) {
      usersMap[email] = user.toJson();
    });
    await prefs.setString('users', json.encode(usersMap));

    // Lưu current user email
    if (_currentUser != null) {
      await prefs.setString('currentUserEmail', _currentUser!.email);
    } else {
      await prefs.remove('currentUserEmail');
    }
  }

  Future<void> login(String usernameOrEmail, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Find user by username or email
    String? email;
    if (_users.containsKey(usernameOrEmail)) {
      // Direct email lookup
      email = usernameOrEmail;
    } else if (_usernameToEmail.containsKey(usernameOrEmail)) {
      // Username lookup
      email = _usernameToEmail[usernameOrEmail];
    }

    // Check if user exists
    if (email == null || !_users.containsKey(email)) {
      throw 'User does not exist. Please sign up.';
    }

    // Check password
    final user = _users[email]!;
    if (user.password != password) {
      throw 'Incorrect password. Please try again.';
    }

    _currentUser = user;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? country,
    String? profileImageUrl,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Check if email already exists
    if (_users.containsKey(email)) {
      throw 'An account with this email already exists.';
    }

    // Check if username already exists
    if (_usernameToEmail.containsKey(username)) {
      throw 'This username is already taken.';
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      username: username,
      email: email,
      password: password,
      profileImageUrl: profileImageUrl,
      phone: phone,
      gender: gender,
      country: country,
    );

    _users[email] = newUser;
    _usernameToEmail[username] = email; // Add to username map
    // Do NOT set _currentUser here - user must login after registration
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateUserProfileImage(String imagePath) async {
    if (_currentUser != null) {
      _currentUser!.profileImageUrl = imagePath;
      _users[_currentUser!.email] = _currentUser!;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  // Cập nhật thông tin profile
  Future<void> updateProfile({
    String? name,
    String? username,
    String? email,
    String? profileImageUrl,
    String? phone,
    String? gender,
    String? country,
  }) async {
    if (_currentUser == null) return;

    final oldEmail = _currentUser!.email;
    final oldUsername = _currentUser!.username;

    // Check if new username is taken by another user
    if (username != null && username != oldUsername) {
      if (_usernameToEmail.containsKey(username) &&
          _usernameToEmail[username] != oldEmail) {
        throw 'This username is already taken by another user.';
      }
    }

    // Check if new email is taken by another user
    if (email != null && email != oldEmail) {
      if (_users.containsKey(email)) {
        throw 'This email is already in use by another account.';
      }
    }

    // Update user data
    if (name != null) {
      _currentUser!.name = name;
    }
    if (username != null && username != oldUsername) {
      _usernameToEmail.remove(oldUsername);
      _currentUser!.username = username;
      _usernameToEmail[username] = email ?? oldEmail;
    }
    if (email != null && email != oldEmail) {
      _users.remove(oldEmail);
      _currentUser!.email = email;
      _users[email] = _currentUser!;
      _usernameToEmail[_currentUser!.username] = email;
    } else {
      _users[oldEmail] = _currentUser!;
    }
    if (profileImageUrl != null) {
      _currentUser!.profileImageUrl = profileImageUrl;
    }
    if (phone != null) {
      _currentUser!.phone = phone;
    }
    if (gender != null) {
      _currentUser!.gender = gender;
    }
    if (country != null) {
      _currentUser!.country = country;
    }

    await _saveToPrefs();
    notifyListeners();
  }
}
