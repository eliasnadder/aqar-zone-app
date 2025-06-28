import 'package:flutter/material.dart';

class AppTheme {
  // Colors inspired by Gemini and ChatGPT
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color backgroundColor = Color(0xFF0F0F0F);
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2D2D2D);

  // Message bubble colors
  static const Color userBubbleColor = Color(0xFF1A73E8);
  static const Color assistantBubbleColor = Color(0xFF2D2D2D);
  static const Color systemBubbleColor = Color(0xFF34A853);

  // Text colors
  static const Color primaryTextColor = Color(0xFFE8EAED);
  static const Color secondaryTextColor = Color(0xFF9AA0A6);
  static const Color accentTextColor = Color(0xFF8AB4F8);

  // Voice animation colors
  static const List<Color> voiceWaveColors = [
    Color(0xFF1A73E8),
    Color(0xFF4285F4),
    Color(0xFF8AB4F8),
    Color(0xFFAAC7FF),
  ];

  // Status colors
  static const Color successColor = Color(0xFF34A853);
  static const Color errorColor = Color(0xFFEA4335);
  static const Color warningColor = Color(0xFFFFBF00);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryTextColor,
        onBackground: primaryTextColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: primaryTextColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: secondaryTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class AppConstants {
  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Border radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 16.0;
  static const double largeRadius = 24.0;
  static const double circularRadius = 50.0;

  // Message bubble constraints
  static const double maxBubbleWidth = 280.0;
  static const double minBubbleHeight = 48.0;

  // Voice animation
  static const int voiceWaveCount = 5;
  static const double voiceWaveMaxHeight = 60.0;
  static const double voiceWaveMinHeight = 4.0;
  static const double voiceWaveWidth = 4.0;
  static const double voiceWaveSpacing = 6.0;

  // API Configuration
  static const String geminiModel = 'gemini-1.5-flash';
  static const String arabicLocale = 'ar-SA';

  // Voice settings
  static const Duration listenTimeout = Duration(seconds: 15);
  static const Duration pauseTimeout = Duration(seconds: 3);

  // Messages
  static const String welcomeMessage =
      "مرحباً! أنا مساعدك العقاري الذكي. كيف يمكنني مساعدتك اليوم؟";
  static const String listeningMessage = "أستمع إليك...";
  static const String processingMessage = "أعالج طلبك...";
  static const String errorMessage = "عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.";
  static const String noDataMessage = "يرجى جلب بيانات العقارات أولاً.";
}
