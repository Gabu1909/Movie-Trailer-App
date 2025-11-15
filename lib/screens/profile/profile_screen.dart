import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                    _buildUserInfo(context),
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
          // Nút quay lại - navigate to home
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
                onPressed: () => context.go('/'),
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
  Widget _buildUserInfo(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Column(
      children: [
        // Ảnh đại diện
        CircleAvatar(
          radius: 60,
          backgroundImage: user?.profileImageUrl != null
              ? (user!.profileImageUrl!.startsWith('http')
                  ? NetworkImage(user.profileImageUrl!)
                  : FileImage(File(user.profileImageUrl!)) as ImageProvider)
              : const NetworkImage('https://i.pravatar.cc/150?img=12'),
          backgroundColor: Colors.white24,
        ),
        const SizedBox(height: 16),
        // Tên người dùng
        Text(
          user?.name ?? 'Guest User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Email
        Text(
          user?.email ?? 'guest@example.com',
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
              icon: Icons.person_outline,
              text: 'Edit Profile', onTap: () async {
            // Navigate to edit profile and wait for result
            final result = await context.push('/profile/edit');
            // Show success message if update was successful
            if (result == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.check_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profile updated successfully!',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.white,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }),
          _buildMenuItem(context,
              icon: Icons.security_outlined,
              text: 'Security',
              onTap: () => context.push('/security')),
          _buildMenuItem(context,
              icon: Icons.settings_outlined,
              text: 'Settings',
              onTap: () => context.push('/settings')),
          _buildMenuItem(context,
              icon: Icons.list_alt_outlined,
              text: 'My List',
              onTap: () => context.push('/my-list')),
          _buildMenuItem(context,
              icon: Icons.help_outline,
              text: 'Help Center',
              onTap: () => context.push('/help_center')),
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
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2B124C),
              title: const Text('Confirm Logout',
                  style: TextStyle(color: Colors.white)),
              content: const Text('Are you sure you want to log out?',
                  style: TextStyle(color: Colors.white70)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Logout',
                      style: TextStyle(color: Colors.pinkAccent)),
                ),
              ],
            );
          },
        );

        // Nếu người dùng xác nhận, thực hiện đăng xuất
        if (confirmLogout == true) {
          if (!context.mounted) return;

          // Đăng xuất thông qua AuthProvider
          await Provider.of<AuthProvider>(context, listen: false).logout();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Logged out successfully!',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              duration: Duration(seconds: 2),
            ),
          );

          // Delay nhỏ để hiển thị SnackBar
          await Future.delayed(const Duration(milliseconds: 300));

          if (!context.mounted) return;
          context.go('/login');
        }
      },
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text('Logout',
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
