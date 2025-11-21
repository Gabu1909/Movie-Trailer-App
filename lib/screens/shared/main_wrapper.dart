import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/coming-soon')) return 2;
    if (location.startsWith('/my-list')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/coming-soon');
        break;
      case 3:
        context.go('/my-list');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? null : Theme.of(context).scaffoldBackgroundColor,
        gradient: isDarkMode
            ? const LinearGradient(
                colors: [Color(0xFF240046), Color(0xFF5A189A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
        bottomNavigationBar: Container(
          // 1. QUAN TRỌNG: Bỏ height cố định và Bỏ Padding luôn
          // Để nó tự co giãn theo kích thước icon bên trong -> Sẽ mỏng nhất có thể
          // padding: const EdgeInsets.only(top: 10, bottom: 10), // <-- XÓA DÒNG NÀY

          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A189A).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.transparent,
            unselectedItemColor: Colors.transparent,

            // Tắt label để tiết kiệm diện tích
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedFontSize: 0,
            unselectedFontSize: 0,

            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
            items: [
              _buildNavItem(Icons.home, "Home", 0, selectedIndex),
              _buildNavItem(Icons.explore, "Explore", 1, selectedIndex),
              _buildNavItem(
                  Icons.new_releases, "Coming Soon", 2, selectedIndex),
              _buildNavItem(Icons.list, "My List", 3, selectedIndex),
              _buildNavItem(Icons.person, "Profile", 4, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
    int selectedIndex,
  ) {
    final isSelected = index == selectedIndex;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // 2. GIẢM PADDING ICON: Giảm từ 8 xuống 6 để vòng tròn bé lại => Thanh bar sẽ thấp xuống
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF006E).withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF6EC7).withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isSelected
                ? [Colors.white, Colors.white]
                : [Colors.grey.shade400, Colors.grey.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Icon(
            icon,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
      label: label,
    );
  }
}

// Widget riêng cho custom bottom nav bar (tùy chọn nâng cao)
class GlowingIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const GlowingIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFFF006E), Color(0xFFFF6EC7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFFF006E).withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey,
        size: 26,
      ),
    );
  }
}
