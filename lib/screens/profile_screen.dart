import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Phung Tan Phat';
  String _userEmail = 'phungtanphat@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('profile_name') ?? 'Phung Tan Phat';
      _userEmail =
          prefs.getString('profile_email') ?? 'phungtanphat@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Giao diện màn hình hồ sơ
    return Scaffold(
      body: Container(
        // Sử dụng gradient nền tương tự HomeScreen để đồng nhất
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF12002F),
              Color(0xFF3A0CA3),
              Color(0xFF7209B7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar tùy chỉnh
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    const SizedBox(height: 20),
                    // Thông tin người dùng (Avatar, Tên, Email)
                    _buildUserInfo(), // Cập nhật để sử dụng _userName và _userEmail
                    const SizedBox(height: 30),
                    // Menu các tùy chọn
                    _buildProfileMenu(context),
                    const SizedBox(height: 40),
                    // Nút Đăng xuất
                    _buildLogoutButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget cho AppBar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nút quay lại
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
          // Tiêu đề
          const Text(
            // Translated from 'Hồ Sơ'
            'Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget cho thông tin người dùng
  Widget _buildUserInfo() {
    return Column(
      children: [
        // Ảnh đại diện
        const CircleAvatar(
          radius: 60,
          backgroundImage:
              NetworkImage('https://i.pravatar.cc/150?img=12'), // Ảnh mẫu
          backgroundColor: Colors.white24,
        ),
        const SizedBox(height: 16),
        // Tên người dùng
        Text(
          _userName, // Sử dụng tên từ state
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Email
        Text(
          _userEmail, // Sử dụng email từ state
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Widget cho menu các mục
  Widget _buildProfileMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(context,
              icon: Icons.person_outline, // Translated from 'Chỉnh sửa hồ sơ'
              text: 'Edit Profile', onTap: () async {
            await context.push('/profile/edit');
            _loadUserInfo(); // Tải lại thông tin sau khi quay lại từ màn hình chỉnh sửa
          }),
          _buildMenuItem(context,
              icon: Icons.security_outlined,
              text: 'Security',
              onTap: () => context.push('/security')),
          _buildMenuItem(context,
              icon: Icons.notifications_outlined,
              text: 'Notifications',
              onTap: () => context.push('/notifications')),
          _buildMenuItem(context,
              icon: Icons.list_alt_outlined,
              text: 'My List',
              onTap: () => context.push('/my-list')),
          _buildMenuItem(context,
              icon: Icons.help_outline,
              text: 'Help Center',
              onTap: () => context.push('/help-center')),
        ],
      ),
    );
  }

  // Widget cho một mục trong menu
  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: Colors.white70),
      title:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
    );
  }

  // Widget cho nút đăng xuất
  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        // Hiển thị hộp thoại xác nhận
        final bool? confirmLogout = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2B124C),
              title: const Text('Confirm Logout',
                  style: TextStyle(color: Colors.white)),
              content: const Text('Are you sure you want to log out?',
                  style: TextStyle(color: Colors.white70)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout',
                      style: TextStyle(color: Colors.pinkAccent)),
                ),
              ],
            );
          },
        );

        // Nếu người dùng xác nhận, thực hiện đăng xuất
        if (confirmLogout == true && context.mounted) {
          // Trong ứng dụng thực tế, bạn sẽ xóa token, xóa dữ liệu người dùng, v.v.

          // Xóa SharedPreferences khi đăng xuất
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('profile_name');
          await prefs.remove('profile_email');
          // Có thể dùng await prefs.clear() nếu muốn xóa tất cả

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'You have been logged out successfully.',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            backgroundColor: Colors.white,
          ));
          context.go('/home'); // Điều hướng về màn hình chính
        }
      },
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text('Logout', // Translated from 'Đăng xuất'
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pinkAccent.withOpacity(0.8),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
