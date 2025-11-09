import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../providers/bottom_nav_visibility_provider.dart';

/// Một widget bọc (wrapper) để tự động ẩn/hiện BottomNavigationBar
/// khi người dùng cuộn nội dung bên trong nó.
class ScrollHidingNavWrapper extends StatelessWidget {
  /// Widget con có khả năng cuộn (ví dụ: ListView, CustomScrollView).
  final Widget child;

  const ScrollHidingNavWrapper({
    super.key,
    required this.child,
  });

  bool _handleScrollNotification(
      ScrollNotification notification, BuildContext context) {
    // Chỉ xử lý cho widget cuộn chính (không phải các list con lồng nhau).
    if (notification.depth == 0) {
      final provider = context.read<BottomNavVisibilityProvider>();
      if (notification is UserScrollNotification) {
        if (notification.direction == ScrollDirection.reverse) {
          provider.hide();
        } else if (notification.direction == ScrollDirection.forward) {
          provider.show();
        }
      } else if (notification is ScrollEndNotification) {
        // Khi cuộn dừng, bắt đầu timer để hiện lại thanh nav.
        provider.hide();
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) =>
          _handleScrollNotification(notification, context),
      child: child,
    );
  }
}
