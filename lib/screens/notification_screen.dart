import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Chuyển thành StatefulWidget
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 2. Tạo các biến trạng thái cho các Switch
  // (Giá trị ban đầu dựa trên ảnh của bạn)
  bool _generalNotification = true;
  bool _newArrival = true; // Changed to true based on common default
  bool _newServices = true; // Changed to true based on common default
  bool _newReleases = true;
  bool _appUpdates = true;
  bool _subscription = true; // Changed to true based on common default

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
                '${settingName[0].toUpperCase()}${settingName.substring(1)} setting updated.'),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating, // Để SnackBar nổi lên
      ),
    );
  }

  // ... (phần còn lại của mã)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Nền gradient đồng nhất (giữ nguyên)
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
              // 3. Cập nhật tiêu đề AppBar cho giống ảnh
              _buildAppBar(context),
              // 4. Thay đổi ListView.builder thành ListView tĩnh
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  children: [
                    _buildSwitchItem(
                      'General Notification',
                      _generalNotification,
                      (newValue) {
                        _saveNotificationSetting(
                            'notification_general', newValue);
                        setState(() {
                          _generalNotification = newValue;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'New Arrival',
                      _newArrival,
                      (newValue) {
                        _saveNotificationSetting(
                            'notification_new_arrival', newValue);
                        setState(() {
                          _newArrival = newValue;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'New Services Available',
                      _newServices,
                      (newValue) {
                        _saveNotificationSetting(
                            'notification_new_services', newValue);
                        setState(() {
                          _newServices = newValue;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'New Releases Movie',
                      _newReleases,
                      (newValue) {
                        _saveNotificationSetting(
                            'notification_new_releases', newValue);
                        setState(() {
                          _newReleases = newValue;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'App Updates',
                      _appUpdates,
                      (newValue) {
                        _saveNotificationSetting(
                            'notification_app_updates', newValue);
                        setState(() {
                          _appUpdates = newValue;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'Subscription',
                      _subscription,
                      (newValue) {
                        _saveNotificationSetting(
                            'notification_subscription', newValue);
                        setState(() {
                          _subscription = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            'Notification', // <-- Đã sửa từ "Notifications" thành "Notification"
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 5. Widget mới để tạo dòng cài đặt có Switch
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
          activeColor: Colors.pinkAccent, // Giữ nguyên màu chủ đạo
          inactiveTrackColor: Colors.white30,
        ),
      ),
    );
  }
}
