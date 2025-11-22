import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../../providers/bottom_nav_visibility_provider.dart';

class ScrollHidingNavWrapper extends StatelessWidget {
  final Widget child;

  const ScrollHidingNavWrapper({
    super.key,
    required this.child,
  });

  bool _handleScrollNotification(
      ScrollNotification notification, BuildContext context) {
    if (notification.depth == 0) {
      final provider = context.read<BottomNavVisibilityProvider>();
      if (notification is UserScrollNotification) {
        if (notification.direction == ScrollDirection.reverse) {
          provider.hide();
        } else if (notification.direction == ScrollDirection.forward) {
          provider.show();
        }
      } else if (notification is ScrollEndNotification) {
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
