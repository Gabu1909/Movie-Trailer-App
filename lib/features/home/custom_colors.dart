import 'package:flutter/material.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color? success;
  final Color? warning;
  final Color? info;
  final Color? shimmerBase;
  final Color? shimmerHighlight;

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
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
    );
  }

  static CustomColors of(BuildContext context) {
    return Theme.of(context).extension<CustomColors>()!;
  }
}
