import 'package:flutter/material.dart';

/// Centralized spacing constants for consistent UI
///
/// Usage:
/// ```dart
/// Padding(padding: AppSpacing.paddingAll16)
/// SizedBox(height: AppSpacing.height16)
/// ```
class AppSpacing {
  AppSpacing._();

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  static const SizedBox height4 = SizedBox(height: space4);
  static const SizedBox height8 = SizedBox(height: space8);
  static const SizedBox height12 = SizedBox(height: space12);
  static const SizedBox height16 = SizedBox(height: space16);
  static const SizedBox height20 = SizedBox(height: space20);
  static const SizedBox height24 = SizedBox(height: space24);
  static const SizedBox height32 = SizedBox(height: space32);
  static const SizedBox height40 = SizedBox(height: space40);

  static const SizedBox width4 = SizedBox(width: space4);
  static const SizedBox width8 = SizedBox(width: space8);
  static const SizedBox width10 = SizedBox(width: 10);
  static const SizedBox width12 = SizedBox(width: space12);
  static const SizedBox width16 = SizedBox(width: space16);
  static const SizedBox width20 = SizedBox(width: space20);
  static const SizedBox width24 = SizedBox(width: space24);
  static const SizedBox width40 = SizedBox(width: space40);

  static const EdgeInsets paddingAll4 = EdgeInsets.all(space4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(space8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(space12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(space16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(space20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(space24);

  static const EdgeInsets paddingH8 = EdgeInsets.symmetric(horizontal: space8);
  static const EdgeInsets paddingH12 =
      EdgeInsets.symmetric(horizontal: space12);
  static const EdgeInsets paddingH14 = EdgeInsets.symmetric(horizontal: 14);
  static const EdgeInsets paddingH16 =
      EdgeInsets.symmetric(horizontal: space16);
  static const EdgeInsets paddingH20 =
      EdgeInsets.symmetric(horizontal: space20);
  static const EdgeInsets paddingH24 =
      EdgeInsets.symmetric(horizontal: space24);

  static const EdgeInsets paddingV8 = EdgeInsets.symmetric(vertical: space8);
  static const EdgeInsets paddingV10 = EdgeInsets.symmetric(vertical: 10);
  static const EdgeInsets paddingV12 = EdgeInsets.symmetric(vertical: space12);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: space16);
  static const EdgeInsets paddingV20 = EdgeInsets.symmetric(vertical: space20);
  static const EdgeInsets paddingV24 = EdgeInsets.symmetric(vertical: space24);

  static const EdgeInsets paddingH16V10 = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: 10,
  );

  static const EdgeInsets paddingH14V12 = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: space12,
  );

  static const EdgeInsets paddingH16V8 = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space8,
  );

  static const BorderRadius radius4 = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radius8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radius12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radius16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radius20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radius24 = BorderRadius.all(Radius.circular(24));

  static const BorderRadius radiusTop20 = BorderRadius.vertical(
    top: Radius.circular(20),
  );
}
