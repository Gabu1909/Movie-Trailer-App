import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
    final settingName =
        key.replaceAll('notification_', '').replaceAll('_', ' ');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                  '${settingName[0].toUpperCase()}${settingName.substring(1)} updated'),
            ],
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B124C), Color(0xFF5B2A9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Appearance Section
                  _buildSectionTitle('Appearance'),
                  _buildThemeModeTile(
                    title: 'Theme Mode',
                    subtitle: 'Choose light or dark theme',
                    icon: settings.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    currentMode: settings.themeMode,
                  ),

                  const Divider(color: Colors.white24, height: 32),

                  // General Section
                  _buildSectionTitle('General'),
                  _buildSwitchTile(
                    title: 'Sound Effects',
                    subtitle: 'Enable sound on button clicks',
                    icon: Icons.volume_up_outlined,
                    value: settings.soundEnabled,
                    onChanged: (value) => settings.toggleSound(value),
                  ),
                  _buildSwitchTile(
                    title: 'Haptic Feedback',
                    subtitle: 'Enable vibration on interactions',
                    icon: Icons.vibration,
                    value: settings.hapticsEnabled,
                    onChanged: (value) => settings.toggleHaptics(value),
                  ),

                  const Divider(color: Colors.white24, height: 32),

                  // Notifications Section
                  _buildSectionTitle('Notifications'),
                  _buildNotificationSwitchTile(
                    title: 'General Notification',
                    subtitle: 'Enable all notifications',
                    icon: Icons.notifications_outlined,
                    value: _generalNotification,
                    onChanged: (value) {
                      _saveNotificationSetting('notification_general', value);
                      setState(() => _generalNotification = value);
                    },
                  ),
                  _buildNotificationSwitchTile(
                    title: 'New Arrival',
                    subtitle: 'New movies added to catalog',
                    icon: Icons.fiber_new_outlined,
                    value: _newArrival,
                    onChanged: (value) {
                      _saveNotificationSetting(
                          'notification_new_arrival', value);
                      setState(() => _newArrival = value);
                    },
                  ),
                  _buildNotificationSwitchTile(
                    title: 'New Services Available',
                    subtitle: 'Updates about new features',
                    icon: Icons.stars_outlined,
                    value: _newServices,
                    onChanged: (value) {
                      _saveNotificationSetting(
                          'notification_new_services', value);
                      setState(() => _newServices = value);
                    },
                  ),
                  _buildNotificationSwitchTile(
                    title: 'New Releases Movie',
                    subtitle: 'Latest movie releases',
                    icon: Icons.movie_outlined,
                    value: _newReleases,
                    onChanged: (value) {
                      _saveNotificationSetting(
                          'notification_new_releases', value);
                      setState(() => _newReleases = value);
                    },
                  ),
                  _buildNotificationSwitchTile(
                    title: 'App Updates',
                    subtitle: 'New app versions available',
                    icon: Icons.system_update_outlined,
                    value: _appUpdates,
                    onChanged: (value) {
                      _saveNotificationSetting(
                          'notification_app_updates', value);
                      setState(() => _appUpdates = value);
                    },
                  ),
                  _buildNotificationSwitchTile(
                    title: 'Subscription',
                    subtitle: 'Subscription renewal reminders',
                    icon: Icons.card_membership_outlined,
                    value: _subscription,
                    onChanged: (value) {
                      _saveNotificationSetting(
                          'notification_subscription', value);
                      setState(() => _subscription = value);
                    },
                  ),

                  const Divider(color: Colors.white24, height: 32),

                  // Downloads Section
                  _buildSectionTitle('Downloads'),
                  _buildQualitySettingTile(
                    title: 'Video Quality',
                    subtitle: 'Select quality for downloaded videos',
                    icon: Icons.high_quality_outlined,
                    currentQuality: settings.downloadQuality,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      secondary: Icon(icon, color: Colors.pinkAccent),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pinkAccent,
    );
  }

  Widget _buildNotificationSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      secondary: Icon(icon, color: Colors.purpleAccent),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.purpleAccent,
    );
  }

  Widget _buildThemeModeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemeMode currentMode,
  }) {
    String themeModeToString(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.light:
          return 'Light';
        case AppThemeMode.dark:
          return 'Dark';
        case AppThemeMode.system:
          return 'System';
      }
    }

    return ListTile(
      leading: Icon(icon, color: Colors.amberAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            themeModeToString(currentMode),
            style: const TextStyle(
                color: Colors.amberAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
      onTap: () => _showThemeModeDialog(currentMode),
    );
  }

  Widget _buildQualitySettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required DownloadQuality currentQuality,
  }) {
    String qualityToString(DownloadQuality quality) {
      switch (quality) {
        case DownloadQuality.high:
          return 'High';
        case DownloadQuality.medium:
          return 'Medium';
        case DownloadQuality.low:
          return 'Low';
      }
    }

    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            qualityToString(currentQuality),
            style: const TextStyle(
                color: Colors.pinkAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
      onTap: () => _showQualityDialog(currentQuality),
    );
  }

  void _showThemeModeDialog(AppThemeMode currentMode) {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A0CA3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Theme Mode',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              IconData icon;
              String description;
              switch (mode) {
                case AppThemeMode.light:
                  icon = Icons.light_mode;
                  description = 'Always use light theme';
                  break;
                case AppThemeMode.dark:
                  icon = Icons.dark_mode;
                  description = 'Always use dark theme';
                  break;
                case AppThemeMode.system:
                  icon = Icons.brightness_auto;
                  description = 'Follow system setting';
                  break;
              }

              return RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      mode.name[0].toUpperCase() + mode.name.substring(1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(description,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                ),
                value: mode,
                groupValue: settings.themeMode,
                onChanged: (AppThemeMode? value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.of(dialogContext).pop();
                  }
                },
                activeColor: Colors.amberAccent,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showQualityDialog(DownloadQuality currentQuality) {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A0CA3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Video Quality',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: DownloadQuality.values.map((quality) {
              return RadioListTile<DownloadQuality>(
                title: Text(
                  quality.name[0].toUpperCase() + quality.name.substring(1),
                  style: const TextStyle(color: Colors.white),
                ),
                value: quality,
                groupValue: settings.downloadQuality,
                onChanged: (DownloadQuality? value) {
                  if (value != null) {
                    settings.setDownloadQuality(value);
                    Navigator.of(dialogContext).pop();
                  }
                },
                activeColor: Colors.pinkAccent,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }
}
