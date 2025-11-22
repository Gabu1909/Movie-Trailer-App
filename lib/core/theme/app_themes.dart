import 'package:flutter/material.dart';

class AppThemeDefinition {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color primaryColor;
  final Color surfaceColor;
  final Color scaffoldColor;

  const AppThemeDefinition({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.primaryColor,
    required this.surfaceColor,
    required this.scaffoldColor,
  });
}

class AppThemes {
  static const List<AppThemeDefinition> themes = [
    AppThemeDefinition(
      id: 'midnight_purple',
      name: 'Midnight Purple',
      gradientColors: [Color(0xFF240046), Color(0xFF5A189A)],
      primaryColor: Color(0xFFE91E63),
      surfaceColor: Color(0xFF2A1B4E),
      scaffoldColor: Color(0xFF1A0933),
    ),
    AppThemeDefinition(
      id: 'dim_blue',
      name: 'Dim Blue',
      gradientColors: [Color(0xFF2C2C54), Color(0xFF2C2C54)], 
      primaryColor: Color(0xFFE91E63),
      surfaceColor: Color(0xFF40407A),
      scaffoldColor: Color(0xFF2C2C54),
    ),
    AppThemeDefinition(
      id: 'forest_green',
      name: 'Forest Green',
      gradientColors: [Color(0xFF003D33), Color(0xFF00796B)],
      primaryColor: Color(0xFF4CAF50),
      surfaceColor: Color(0xFF00695C),
      scaffoldColor: Color(0xFF003D33),
    ),
    AppThemeDefinition(
      id: 'ocean_blue',
      name: 'Ocean Blue',
      gradientColors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      primaryColor: Color(0xFF2196F3),
      surfaceColor: Color(0xFF1565C0),
      scaffoldColor: Color(0xFF0C3A8A),
    ),
    AppThemeDefinition(
      id: 'sunset_orange',
      name: 'Sunset Orange',
      gradientColors: [Color(0xFFBF360C), Color(0xFFF4511E)],
      primaryColor: Color(0xFFFF7043),
      surfaceColor: Color(0xFFE64A19),
      scaffoldColor: Color(0xFFAC300A),
    ),
    AppThemeDefinition(
      id: 'ruby_red',
      name: 'Ruby Red',
      gradientColors: [Color(0xFF6A0000), Color(0xFFC62828)],
      primaryColor: Color(0xFFE53935),
      surfaceColor: Color(0xFFB71C1C),
      scaffoldColor: Color(0xFF5A0000),
    ),
    AppThemeDefinition(
      id: 'royal_gold',
      name: 'Royal Gold',
      gradientColors: [Color(0xFF4A3700), Color(0xFFC09000)],
      primaryColor: Color(0xFFFFD700),
      surfaceColor: Color(0xFFAD8000),
      scaffoldColor: Color(0xFF3D2E00),
    ),
    AppThemeDefinition(
      id: 'deep_space',
      name: 'Deep Space',
      gradientColors: [Color(0xFF121212), Color(0xFF2C2C2C)],
      primaryColor: Color(0xFFBB86FC),
      surfaceColor: Color(0xFF1E1E1E),
      scaffoldColor: Color(0xFF121212),
    ),
    AppThemeDefinition(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      gradientColors: [Color(0xFF000B3D), Color(0xFFF700FF)],
      primaryColor: Color(0xFF00F6FF),
      surfaceColor: Color(0xFF3D006A),
      scaffoldColor: Color(0xFF000B3D),
    ),
    AppThemeDefinition(
      id: 'mocha',
      name: 'Mocha',
      gradientColors: [Color(0xFF3E2723), Color(0xFF5D4037)],
      primaryColor: Color(0xFFD7CCC8),
      surfaceColor: Color(0xFF4E342E),
      scaffoldColor: Color(0xFF3E2723),
    ),
  ];

  static AppThemeDefinition findById(String id) {
    return themes.firstWhere((theme) => theme.id == id,
        orElse: () => themes.first); 
  }
}