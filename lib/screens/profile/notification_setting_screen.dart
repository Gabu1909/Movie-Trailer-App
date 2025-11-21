import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_themes.dart';
import '../../utils/ui_helpers.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Local state for notifications
  bool _generalNotification = true;
  bool _newArrival = true;
  bool _newServices = true;
  bool _newReleases = true;
  bool _appUpdates = true;
  bool _subscription = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _generalNotification = prefs.getBool('notification_general') ?? true;
      _newArrival = prefs.getBool('notification_new_arrival') ?? true;
      _newServices = prefs.getBool('notification_new_services') ?? true;
      _newReleases = prefs.getBool('notification_new_releases') ?? true;
      _appUpdates = prefs.getBool('notification_app_updates') ?? true;
      _subscription = prefs.getBool('notification_subscription') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Format name for Snackbar
    String settingName =
        key.replaceAll('notification_', '').replaceAll('_', ' ');
    settingName = settingName[0].toUpperCase() + settingName.substring(1);

    if (mounted) {
      // Optional: Show snackbar or just silent save
      // UIHelpers.showSuccessSnackBar(context, '$settingName updated');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                children: [
                  // 1. APPEARANCE & GENERAL GROUP
                  _buildSectionTitle('General & Appearance'),
                  _buildSettingsGroup([
                    _buildValueItem(
                      context, // Sử dụng themeId mới
                      icon: Icons.palette_outlined,
                      iconColor: Colors.amber,
                      title: 'App Theme',
                      value: AppThemes.findById(settings.themeId).name,
                      onTap: () => _showThemePickerDialog(context, settings),
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.volume_up_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Sound Effects',
                      value: settings.soundEnabled,
                      onChanged: (v) => settings.toggleSound(v),
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.vibration_rounded,
                      iconColor: Colors.tealAccent,
                      title: 'Haptic Feedback',
                      value: settings.hapticsEnabled,
                      onChanged: (v) => settings.toggleHaptics(v),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 2. NOTIFICATIONS GROUP
                  _buildSectionTitle('Notifications'),
                  _buildSettingsGroup([
                    _buildSwitchItem(
                      icon: Icons.notifications_active_rounded,
                      iconColor: Colors.pinkAccent,
                      title: 'General Notification',
                      subtitle: 'Enable push notifications',
                      value: _generalNotification,
                      onChanged: (v) {
                        _saveNotificationSetting('notification_general', v);
                        setState(() => _generalNotification = v);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.new_releases_rounded,
                      iconColor: Colors.purpleAccent,
                      title: 'New Arrivals & Releases',
                      value:
                          _newArrival, // Combining new arrival & releases for cleaner UI logic if wanted, or keep separate
                      onChanged: (v) {
                        _saveNotificationSetting('notification_new_arrival', v);
                        setState(() => _newArrival = v);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.update_rounded,
                      iconColor: Colors.greenAccent,
                      title: 'App Updates',
                      value: _appUpdates,
                      onChanged: (v) {
                        _saveNotificationSetting('notification_app_updates', v);
                        setState(() => _appUpdates = v);
                      },
                    ),
                    _buildDivider(),
                    _buildSwitchItem(
                      icon: Icons.card_membership_rounded,
                      iconColor: Colors.orangeAccent,
                      title: 'Subscription',
                      subtitle: 'Renewal reminders',
                      value: _subscription,
                      onChanged: (v) {
                        _saveNotificationSetting(
                            'notification_subscription', v);
                        setState(() => _subscription = v);
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 3. DOWNLOADS GROUP
                  _buildSectionTitle('Content'),
                  _buildSettingsGroup([
                    _buildValueItem(
                      context,
                      icon: Icons.high_quality_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Download Quality',
                      value: _getQualityName(settings.downloadQuality),
                      onTap: () => _showQualityDialog(settings.downloadQuality),
                    ),
                  ]),

                  const SizedBox(height: 40),
                ],
              );
            },
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
      title: const Text(
        'Settings',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white),
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

  // Item hiển thị giá trị + mũi tên (Dùng cho Theme, Quality)
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

  // Item hiển thị Switch (On/Off)
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

  // --- HELPER METHODS ---

  String _getQualityName(DownloadQuality quality) {
    switch (quality) {
      case DownloadQuality.high:
        return 'High';
      case DownloadQuality.medium:
        return 'Medium';
      case DownloadQuality.low:
        return 'Low';
    }
  }

  // --- DIALOGS (Tùy chỉnh lại cho đẹp hơn) ---

  // --- Dialog chọn theme mới ---
  void _showThemePickerDialog(BuildContext context, SettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1D0B3C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        ? const Icon(Icons.check_circle,
                            color: Colors.pinkAccent)
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

  void _showQualityDialog(DownloadQuality currentQuality) {
    final settings = context.read<SettingsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1D0B3C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Download Quality',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              ...DownloadQuality.values.map((q) => ListTile(
                    title: Text(_getQualityName(q),
                        style: TextStyle(
                            color: settings.downloadQuality == q
                                ? Colors.pinkAccent
                                : Colors.white)),
                    trailing: settings.downloadQuality == q
                        ? const Icon(Icons.check, color: Colors.pinkAccent)
                        : null,
                    onTap: () {
                      settings.setDownloadQuality(q);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
