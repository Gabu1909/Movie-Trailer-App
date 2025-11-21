import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;

  const CustomAppBar({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            // 1. Nút Menu: Dùng hiệu ứng KÍNH (Glass) để chìm xuống
            _buildGlassButton(
              icon: Icons.sort_rounded,
              onTap: onMenuPressed,
            ),

            const SizedBox(width: 12),

            // 2. Thanh tìm kiếm: Dùng hiệu ứng KÍNH (Glass)
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05), // Nền rất nhạt
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: Colors.white.withOpacity(0.7), size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Search movies...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 3. Nút Thông báo: Duy nhất nút này có MÀU (Gradient)
            Stack(
              children: [
                _buildGradientButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => context.push('/notifications'),
                ),
                // Chấm đỏ báo hiệu
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white, // Chấm trắng trên nền hồng
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFF006E), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✨ Hàm tạo nút KÍNH (cho Menu)
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), // Màu nền trong suốt nhạt
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 Hàm tạo nút MÀU (cho Thông báo)
  Widget _buildGradientButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF006E), // Hồng đậm
              Color(0xFFFF6EC7), // Hồng nhạt
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF006E).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
