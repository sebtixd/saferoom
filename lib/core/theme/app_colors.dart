import 'package:material_ui/material_ui.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF6B5CE7);
  static const Color primaryLight = Color(0xFF9D8FFF);
  static const Color primaryDark = Color(0xFF4A3DB5);

  // Secondary Colors
  static const Color secondary = Color(0xFF00BFA5);
  static const Color secondaryLight = Color(0xFF5DFFC7);
  static const Color secondaryDark = Color(0xFF008E76);

  // Emotional State Colors
  static const Color calm = Color(0xFFFFFACD);
  static const Color happy = Color(0xFFFFE4B5);
  static const Color sad = Color(0xFF778899);
  static const Color angry = Color(0xFFCD5C5C);
  static const Color anxious = Color(0xFFDDA0DD);

  // Weather Colors
  static const Color sunny = Color(0xFFFFD700);
  static const Color rainy = Color(0xFF87CEEB);
  static const Color cloudy = Color(0xFFB0C4DE);
  static const Color stormy = Color(0xFF4A4A4A);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF16213E);

  // Text Colors
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Color(0xFFF8F9FA);
  static const Color textMuted = Color(0xFF6C757D);

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF3A3A5A);

  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Room Background Gradients based on emotional state
  static List<Color> calmGradient = [
    const Color(0xFFFFFACD),
    const Color(0xFFE6E6FA),
  ];

  static List<Color> happyGradient = [
    const Color(0xFFFFE4B5),
    const Color(0xFFFFDAB9),
  ];

  static List<Color> sadGradient = [
    const Color(0xFF778899),
    const Color(0xFF696969),
  ];

  static List<Color> angryGradient = [
    const Color(0xFFCD5C5C),
    const Color(0xFF8B0000),
  ];

  static List<Color> anxiousGradient = [
    const Color(0xFFDDA0DD),
    const Color(0xFF9370DB),
  ];
}
