import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Một lớp helper để tạo các hiệu ứng chuyển trang tùy chỉnh.
class PageTransitions {
  /// Tạo một trang với hiệu ứng Shared Axis.
  static CustomTransitionPage<T> buildSharedAxisTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.scaled, // Mặc định là Z-axis
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
      // Tùy chỉnh thời gian chuyển đổi nếu muốn
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }
}
