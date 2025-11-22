class AppConstants {
  static const double movieCardWidth = 140.0;
  static const double movieCardHeight = 200.0;
  static const double movieCardBorderRadius = 22.0;
  static const double trendingCardWidth = 300.0;
  static const double trendingCardHeight = 450.0;

  static const Duration shortAnimationDuration = Duration(milliseconds: 130);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 250);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration navigationFeedbackDelay = Duration(milliseconds: 50);

  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration longApiTimeout = Duration(seconds: 30);

  static const int maxCacheAge = 7;
  static const int maxCacheSize = 100;

  static const int itemsPerPage = 20;
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 2 / 3;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  static const double defaultBlurRadius = 25.0;
  static const double pressedBlurRadius = 15.0;
  static const double glowSpreadRadius = 2.0;
  static const double pressedGlowSpreadRadius = 3.0;
  static const double defaultGlowOpacity = 0.15;
  static const double maxGlowOpacity = 0.4;

  static const Duration trendingRefreshInterval = Duration(minutes: 15);
  static const Duration notificationCheckInterval = Duration(minutes: 5);

  static const String databaseName = 'favorites.db';
  static const int databaseVersion = 16;

  static const double avatarSizeSmall = 40.0;
  static const double avatarSizeMedium = 60.0;
  static const double avatarSizeLarge = 100.0;
  static const double posterWidthSmall = 92.0;
  static const double posterWidthMedium = 154.0;
  static const double posterWidthLarge = 185.0;

  static const int maxTitleLength = 100;
  static const int maxOverviewLength = 500;
  static const int maxCommentLength = 500;
}
