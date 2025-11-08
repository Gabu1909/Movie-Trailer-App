import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Biến trạng thái cho các nút switch (dựa trên ảnh)
  bool _rememberMe = true;
  bool _saveLoginInfo = true;
  bool _twoFactorAuth = false; // Thêm biến trạng thái cho 2FA

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('security_remember_me') ?? true;
      _saveLoginInfo = prefs.getBool('security_save_login_info') ?? true;
      _twoFactorAuth = prefs.getBool('security_two_factor_auth') ?? false;
    });
  }

  Future<void> _saveSecuritySetting(
      String key, bool value, String settingName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              '$settingName updated successfully!',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
        backgroundColor: Colors.white, // Nền trắng
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Nền gradient đồng nhất
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF12002F), Color(0xFF3A0CA3), Color(0xFF7209B7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  children: [
                    // Nhóm "Account Security"
                    _buildSectionHeader('Account Security'),
                    _buildNavigationItem(
                      context,
                      title: 'Change Password',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Change Password functionality is under development.')),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      context,
                      title: 'Two-Factor Authentication',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Two-Factor Authentication setup is under development.')),
                        );
                      },
                    ),
                    _buildNavigationItem(
                      context,
                      title: 'Login Activity',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Login Activity screen is under development.')),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Nhóm "Login Preferences"
                    _buildSectionHeader('Login Preferences'),
                    _buildSwitchItem(
                      'Remember me',
                      _rememberMe,
                      (newValue) {
                        _saveSecuritySetting(
                            'security_remember_me', newValue, 'Remember me');
                        setState(() {
                          _rememberMe = newValue;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'Save Login Info',
                      _saveLoginInfo,
                      (newValue) {
                        _saveSecuritySetting('security_save_login_info',
                            newValue, 'Save Login Info');
                        setState(() {
                          _saveLoginInfo = newValue;
                        });
                      },
                    ),
                    // Thêm Switch cho Two-Factor Authentication
                    _buildSwitchItem(
                      'Two-Factor Authentication',
                      _twoFactorAuth,
                      (newValue) {
                        _saveSecuritySetting('security_two_factor_auth',
                            newValue, 'Two-Factor Authentication');
                        setState(() {
                          _twoFactorAuth = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget xây dựng AppBar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          const Text(
            'Security', // Tiêu đề
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Widget xây dựng tiêu đề cho một nhóm
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 8.0, top: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white, // Chữ trắng rõ hơn
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget xây dựng một mục cài đặt có nút Switch (bật/tắt)
  Widget _buildSwitchItem(
      String title, bool currentValue, ValueChanged<bool> onChanged) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Switch(
          value: currentValue,
          onChanged: onChanged,
          activeColor: Colors.pinkAccent, // Màu chủ đạo
          inactiveTrackColor: Colors.white30,
        ),
      ),
    );
  }

  // Widget xây dựng một mục cài đặt dùng để điều hướng (có mũi tên)
  Widget _buildNavigationItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white70, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Widget cho các nút "Change PIN" và "Change Password"
  Widget _buildActionButton(BuildContext context,
      {required String title, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.15), // Màu xám tối
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
