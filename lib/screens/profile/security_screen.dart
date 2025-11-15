import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui_helpers.dart';

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
    UIHelpers.showSuccessSnackBar(
        context, '$settingName updated successfully!');
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
                        context.push('/change-password');
                      },
                    ),
                    _buildNavigationItem(
                      context,
                      title: 'Two-Factor Authentication',
                      onTap: () {
                        UIHelpers.showInfoSnackBar(context,
                            'Two-Factor Authentication setup is under development.');
                      },
                    ),
                    _buildNavigationItem(
                      context,
                      title: 'Login Activity',
                      onTap: () {
                        UIHelpers.showInfoSnackBar(context,
                            'Login Activity screen is under development.');
                      },
                    ),

                    const SizedBox(height: 20),

                    // Nhóm "Appearance"
                    _buildSectionHeader('Appearance'),
                    _buildThemeToggle(context),

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

  // Widget for theme mode toggle
  Widget _buildThemeToggle(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Mode',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildThemeOption(
                  context,
                  'Light',
                  Icons.light_mode,
                  settingsProvider.themeMode == AppThemeMode.light,
                  () => settingsProvider.setThemeMode(AppThemeMode.light),
                ),
                const SizedBox(width: 8),
                _buildThemeOption(
                  context,
                  'Dark',
                  Icons.dark_mode,
                  settingsProvider.themeMode == AppThemeMode.dark,
                  () => settingsProvider.setThemeMode(AppThemeMode.dark),
                ),
                const SizedBox(width: 8),
                _buildThemeOption(
                  context,
                  'System',
                  Icons.brightness_auto,
                  settingsProvider.themeMode == AppThemeMode.system,
                  () => settingsProvider.setThemeMode(AppThemeMode.system),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.pinkAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.pinkAccent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.pinkAccent : Colors.white70,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
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
}
