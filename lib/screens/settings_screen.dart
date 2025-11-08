import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  _buildSectionTitle(context, 'General'),
                  _buildSwitchTile(
                    context: context,
                    title: 'Sound Effects',
                    subtitle: 'Enable sound on button clicks',
                    icon: Icons.volume_up_outlined,
                    value: settings.soundEnabled,
                    onChanged: (value) => settings.toggleSound(value),
                  ),
                  _buildSwitchTile(
                    context: context,
                    title: 'Haptic Feedback',
                    subtitle: 'Enable vibration on interactions',
                    icon: Icons.vibration,
                    value: settings.hapticsEnabled,
                    onChanged: (value) => settings.toggleHaptics(value),
                  ),
                  const Divider(color: Colors.white24),
                  _buildSectionTitle(context, 'Downloads'),
                  _buildQualitySettingTile(
                    context: context,
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      secondary: Icon(icon, color: Colors.pinkAccent),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pinkAccent,
    );
  }

  Widget _buildQualitySettingTile({
    required BuildContext context,
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
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: Text(
        qualityToString(currentQuality),
        style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
      ),
      onTap: () => _showQualityDialog(context, currentQuality),
    );
  }

  void _showQualityDialog(BuildContext context, DownloadQuality currentQuality) {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A0CA3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Video Quality', style: TextStyle(color: Colors.white)),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}