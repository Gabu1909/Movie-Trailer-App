import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../utils/ui_helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // Controller dùng chung cho việc xoay Aura và hiệu ứng Sparkle
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Xoay chậm trong 10s
    )..repeat(); // Lặp lại vô hạn
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Demo data
    final watchlistCount = 12;
    final reviewCount = 5;
    // final currentLevel = 12; // Đã bỏ
    // final currentExp = 0.65; // Đã bỏ

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 1. BACKGROUND LAYER (Nền tối)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),

          // 2. CURVED BANNER (Banner cong)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: Theme.of(context).brightness == Brightness.dark ? 280 : 0,
              decoration: BoxDecoration(
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2A0140), // Tím than đậm
                          Color(0xFF12002F),
                        ],
                      )
                    : null, // End gradient
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60), // Move borderRadius inside BoxDecoration
                  bottomRight: Radius.circular(60),
                ), // End borderRadius
              ),
            ),
          ),

          // 3. BLURRY CLOUDS (Đám mây ánh sáng)
          _buildBlurBlob(
              top: 60, left: -50, color: Colors.purpleAccent, radius: 100),
          _buildBlurBlob(
              top: 40, right: -30, color: Colors.blueAccent, radius: 120),
          _buildBlurBlob(
              top: 120, left: 100, color: Colors.pinkAccent, radius: 80),

          // 4. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // AVATAR ASSEMBLY
                  _buildAvatarAssembly(user),

                  const SizedBox(height: 16),

                  // USER INFO + QUOTE
                  _buildUserInfo(user),

                  const SizedBox(height: 30),

                  // --- NEW STATS ROW (ĐÃ NÂNG CẤP) ---
                  _buildStatsRow(
                      reviewCount: reviewCount, watchlistCount: watchlistCount),

                  const SizedBox(height: 30),

                  // SETTINGS GROUPS
                  _buildSectionTitle("Account"),
                  _buildSettingsGroup([
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      text: 'Edit Profile',
                      onTap: () async {
                        final result = await context.push('/profile/edit');
                        if (result == true && context.mounted) {
                          UIHelpers.showSuccessSnackBar(
                              context, 'Profile updated successfully!');
                        }
                      },
                      color: const Color(0xFF448AFF),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.shield_outlined,
                      text: 'Security',
                      onTap: () => context.push('/security'),
                      color: const Color(0xFF00E676),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.card_membership_rounded,
                      text: 'Subscription',
                      subtitle: 'Premium Plan',
                      onTap: () {},
                      color: const Color(0xFFFFD740),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSectionTitle("Content & App"),
                  _buildSettingsGroup([
                    _buildMenuItem(
                      context,
                      icon: Icons.bookmark_border_rounded,
                      text: 'My List',
                      onTap: () => context.push('/my-list'),
                      color: const Color(0xFFFF4081),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.rate_review_outlined,
                      text: 'My Reviews',
                      onTap: () => context.push('/profile/my-reviews'),
                      color: const Color(0xFFE040FB),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      text: 'Settings',
                      onTap: () => context.push('/settings'),
                      color: const Color(0xFF64FFDA),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      text: 'Help Center',
                      onTap: () => context.push('/help_center'),
                      color: const Color(0xFFFFAB40),
                    ),
                  ]),

                  const SizedBox(height: 30),

                  _buildLogoutButton(context),

                  const SizedBox(height: 40),
                  const Text(
                    "PuTa Movies v1.0.0",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VISUAL COMPONENTS ---

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0, // Giữ nguyên
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.transparent),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.go('/'),
        ),
      ),
      title: const Text(
        "Profile",
        // Bỏ style để AppBar tự lấy style từ theme
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.2) : Colors.transparent),
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_none_rounded,
                size: 22, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.push('/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurBlob(
      {double? top,
      double? left,
      double? right,
      required Color color,
      required double radius}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.4),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildAvatarAssembly(dynamic user) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Aura xoay
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animController.value * 2 * math.pi,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFFD500F9),
                        Color(0xFF00E5FF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Avatar
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  Positioned.fill(
                      child: _buildUserImage(user?.profileImageUrl)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.purpleAccent.withOpacity(0.1),
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Sparkles
          _buildSparkle(angle: 0, distance: 75, scale: 1.0),
          _buildSparkle(angle: 2.0, distance: 80, scale: 0.7),
          _buildSparkle(angle: 4.0, distance: 70, scale: 0.5),
        ],
      ),
    );
  }

  Widget _buildSparkle(
      {required double angle,
      required double distance,
      required double scale}) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final currentAngle = angle + (_animController.value * 2 * math.pi);
        final x = distance * math.cos(currentAngle);
        final y = distance * math.sin(currentAngle);
        final opacity =
            (math.sin(_animController.value * 10 * math.pi + angle) + 1) / 2;

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: const Icon(Icons.star, color: Colors.white, size: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(dynamic user) {
    return Column(
      children: [
        Text(
          user?.name ?? 'Guest User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                  color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "“Enjoying movies since 2025 🎬”",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // --- NEW STATS ROW LOGIC ---
  // Đây là phần đã được làm đẹp lại
  Widget _buildStatsRow(
      {required int reviewCount, required int watchlistCount}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Viền gradient nhẹ tạo khối
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        // Nền gradient mờ
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Blur nền mạnh hơn
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reviews Item (Vàng)
                _buildStatItem(
                  value: reviewCount.toString(),
                  label: "Reviews",
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFFD740), // Amber
                ),

                // Divider
                _buildVerticalDivider(),

                // Watchlist Item (Hồng)
                _buildStatItem(
                  value: watchlistCount.toString(),
                  label: "Watchlist",
                  icon: Icons.bookmark_rounded,
                  color: const Color(0xFFFF4081), // Pink
                ),

                // Divider
                _buildVerticalDivider(),

                // Joined Item (Xanh)
                _buildStatItem(
                  value: "2025",
                  label: "Joined",
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF00E5FF), // Cyan
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.2), // Chỉ hiện rõ ở giữa
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Container
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), // Nền icon mờ theo màu
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        // Số liệu
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Nhãn
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  // --- END NEW STATS ROW ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    String? subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                  style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    ]
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final bool confirmLogout = await UIHelpers.showConfirmDialog(
          context,
          'Are you sure you want to log out?',
          title: 'Logout',
          confirmText: 'Yes, Logout',
        );

        if (confirmLogout == true && context.mounted) {
          await Provider.of<AuthProvider>(context, listen: false).logout();
          if (context.mounted) context.go('/login');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border:
              Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5),
          borderRadius: BorderRadius.circular(20),
          color: Colors.redAccent.withOpacity(0.1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text(
              "Log Out",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return CachedNetworkImage( // Giữ nguyên
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: const Color(0xFF2B124C)),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      } else {
        return Image.file(File(url), fit: BoxFit.cover);
      }
    }
    return Image.network('https://i.pravatar.cc/150?img=12', fit: BoxFit.cover);
  }
}
