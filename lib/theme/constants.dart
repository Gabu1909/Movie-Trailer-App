import 'package:flutter/material.dart';

/// Centralized app theme constants
/// Keep all color, text style, and dimension constants here

// ==================== COLORS ====================

// Primary Colors (Pink/Magenta theme)
const kPrimaryColor = Color(0xFFE8005A);
const kPrimaryColorLight = Color(0xFFFF4D94);

// Background Colors - Dark Theme (Purple/Black theme)
const kDarkPurpleColor = Color(0xFF1F1B2E);
const kBlackColor = Color(0xFF111111);
const kLightPurpleColor = Color(0xFF2C2A42); // Used for cards, tabs

// Background Colors - Light Theme
const kLightBackgroundColor = Color(0xFFF5F5F5);
const kLightSurfaceColor = Color(0xFFFFFFFF);
const kLightCardColor = Color(0xFFFFFFFF);

// Text Colors
const kGreyColor = Color(0xFFA9A8B2);
const kSecondaryColor = Color(0xFFF1FAEE); // Near white
const kDarkTextColor = Color(0xFF1F1B2E);
const kLightTextColor = Color(0xFF757575);

// Additional Semantic Colors
const kSuccessColor = Colors.green;
const kErrorColor = Colors.red;
const kWarningColor = Colors.orange;
const kInfoColor = Colors.blue;

// ==================== TEXT STYLES ====================

const kHeadingTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const kTitleTextStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

const kSubtitleTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.white70,
);

const kBodyTextStyle = TextStyle(
  fontSize: 14,
  color: Colors.white,
);

const kCaptionTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.white60,
);

// ==================== DIMENSIONS ====================

// Common sizes used in GridView
const kMovieGridCrossAxisCount = 2;
const kMovieGridChildAspectRatio = 140 / 200;
const kMovieGridCrossAxisSpacing = 16.0;
const kMovieGridMainAxisSpacing = 16.0;

// App Bar
const kAppBarHeight = 56.0;

// Bottom Navigation Bar
const kBottomNavBarHeight = 60.0;
