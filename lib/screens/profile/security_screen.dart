import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui_helpers.dart';
import '../../theme/app_themes.dart'; // Import theme mới

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _rememberMe = true;
  bool _saveLoginInfo = true;
  bool _twoFactorAuth = false;
  bool _biometricEnabled =
      false; // Thêm cái này cho giao diện xịn (FaceID/TouchID)

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
      _biometricEnabled = prefs.getBool('security_biometric') ?? false;
    });
  }

  Future<void> _saveSecuritySetting(
      String key, bool value, String settingName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Chỉ hiện thông báo, không cần reload lại trang
    // UIHelpers.showSuccessSnackBar(context, '$settingName updated');
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    colors: [
                        Color(0xFF12002F),
                        Color(0xFF2A0955),
                        Color(0xFF12002F)
                      ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            children: [
              // 1. AUTHENTICATION GROUP
              _buildSectionTitle('Authentication'),
              _buildSettingsGroup([
                _buildNavigationItem(
                  context,
                  icon: Icons.lock_outline_rounded,
                  iconColor: Colors.blueAccent,
                  title: 'Change Password',
                  onTap: () => context.push('/change-password'),
                ),
                _buildDivider(),
                _buildSwitchItem(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.orangeAccent,
                  title: 'Two-Factor Authentication',
                  value: _twoFactorAuth,
                  onChanged: (v) {
                    _saveSecuritySetting('security_two_factor_auth', v, '2FA');
                    setState(() => _twoFactorAuth = v);
                  },
                ),
                _buildDivider(),
                _buildSwitchItem(
                  icon: Icons.fingerprint_rounded,
                  iconColor: Colors.pinkAccent,
                  title: 'Biometric ID',
                  subtitle: 'Use FaceID or Fingerprint',
                  value: _biometricEnabled,
                  onChanged: (v) {
                    _saveSecuritySetting('security_biometric', v, 'Biometric');
                    setState(() => _biometricEnabled = v);
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // 2. ACCESS & DEVICES
              _buildSectionTitle('Access Control'),
              _buildSettingsGroup([
                _buildNavigationItem(
                  context,
                  icon: Icons.devices_rounded,
                  iconColor: Colors.tealAccent,
                  title:
                      'Login Activity', // Đổi tên từ Devices cho chuyên nghiệp
                  subtitle: 'Manage your active sessions',
                  onTap: () {
                    UIHelpers.showInfoSnackBar(
                        context, 'Login Activity screen is under development.');
                  },
                ),
                _buildDivider(),
                _buildSwitchItem(
                  icon: Icons.person_pin_circle_outlined,
                  iconColor: Colors.purpleAccent,
                  title: 'Remember Me',
                  value: _rememberMe,
                  onChanged: (v) {
                    _saveSecuritySetting(
                        'security_remember_me', v, 'Remember me');
                    setState(() => _rememberMe = v);
                  },
                ),
                _buildDivider(),
                _buildSwitchItem(
                  icon: Icons.save_as_outlined,
                  iconColor: Colors.indigoAccent,
                  title: 'Save Login Info',
                  value: _saveLoginInfo,
                  onChanged: (v) {
                    _saveSecuritySetting(
                        'security_save_login_info', v, 'Save Login Info');
                    setState(() => _saveLoginInfo = v);
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // 3. APPEARANCE (Theme) - Đưa vào khung đẹp hơn
              _buildSectionTitle('App Interface'),
              _buildSettingsGroup([
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildValueItem(
                    context,
                    icon: Icons.palette_outlined,
                    iconColor: Colors.amberAccent,
                    title: 'App Theme',
                    value: AppThemes.findById(settingsProvider.themeId).name,
                    onTap: () => _showThemePickerDialog(context, settingsProvider),
                  ),
                ),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text('Security'),
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Container bao quanh nhóm settings (Glassmorphism)
  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF251043).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1, color: Colors.white.withOpacity(0.05), indent: 60);
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // Navigation Item (Có mũi tên)
  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              _buildIconBox(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // Switch Item
  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIconBox(icon, iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.pinkAccent,
            activeTrackColor: Colors.pinkAccent.withOpacity(0.4),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  // Thêm phương thức này vào
  Widget _buildValueItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), // Radius cho hiệu ứng ripple
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              _buildIconBox(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // --- Dialog chọn theme mới ---
  void _showThemePickerDialog(BuildContext context, SettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1D0B3C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Select a Theme',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: AppThemes.themes.length,
                itemBuilder: (context, index) {
                  final theme = AppThemes.themes[index];
                  final isSelected = provider.themeId == theme.id;
                  return ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: theme.gradientColors),
                      ),
                    ),
                    title: Text(
                      theme.name,
                      style: TextStyle(
                        color: isSelected ? Colors.pinkAccent : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.pinkAccent)
                        : null,
                    onTap: () {
                      provider.setTheme(theme.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
