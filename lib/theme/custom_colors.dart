import 'package:flutter/material.dart';

/// Định nghĩa một ThemeExtension để chứa các màu sắc tùy chỉnh của ứng dụng.
/// Điều này giúp truy cập màu một cách nhất quán và dễ dàng thay đổi
/// giữa các theme (light/dark).
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.subtitleStyle,
  });

  final Color? success;
  final Color? warning;
  final Color? info;
  final Color? shimmerBase;
  final Color? shimmerHighlight;
  final TextStyle? subtitleStyle;

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? shimmerBase,
    Color? shimmerHighlight,
    TextStyle? subtitleStyle,
  }) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      info: Color.lerp(info, other.info, t),
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t),
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t),
      subtitleStyle: TextStyle.lerp(subtitleStyle, other.subtitleStyle, t),
    );
  }

  // (Tùy chọn) Thêm một getter tĩnh để truy cập dễ dàng hơn
  static CustomColors of(BuildContext context) {
    return Theme.of(context).extension<CustomColors>()!;
  }
}
