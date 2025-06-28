import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

class ThemeLoading extends ThemeState {
  const ThemeLoading();
}

class ThemeLoaded extends ThemeState {
  final ThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final Color seedColor;
  final double fontSize;
  final String fontFamily;
  final bool highContrast;
  final bool followSystemBrightness;

  const ThemeLoaded({
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
    required this.seedColor,
    this.fontSize = 14.0,
    this.fontFamily = 'Roboto',
    this.highContrast = false,
    this.followSystemBrightness = true,
  });

  ThemeLoaded copyWith({
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    Color? seedColor,
    double? fontSize,
    String? fontFamily,
    bool? highContrast,
    bool? followSystemBrightness,
  }) {
    return ThemeLoaded(
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      seedColor: seedColor ?? this.seedColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      highContrast: highContrast ?? this.highContrast,
      followSystemBrightness:
          followSystemBrightness ?? this.followSystemBrightness,
    );
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;

  ThemeData get currentTheme {
    switch (themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        // This should be handled by the system brightness
        return lightTheme;
    }
  }

  @override
  List<Object?> get props => [
    themeMode,
    lightTheme,
    darkTheme,
    seedColor,
    fontSize,
    fontFamily,
    highContrast,
    followSystemBrightness,
  ];
}

class ThemeError extends ThemeState {
  final String message;
  final ThemeData? fallbackLightTheme;
  final ThemeData? fallbackDarkTheme;

  const ThemeError({
    required this.message,
    this.fallbackLightTheme,
    this.fallbackDarkTheme,
  });

  @override
  List<Object?> get props => [message, fallbackLightTheme, fallbackDarkTheme];
}

class ThemeUpdating extends ThemeState {
  final ThemeMode currentThemeMode;
  final String updateType;

  const ThemeUpdating({
    required this.currentThemeMode,
    required this.updateType,
  });

  @override
  List<Object?> get props => [currentThemeMode, updateType];
}

class ThemePreferencesSaved extends ThemeState {
  final DateTime saveTime;
  final Map<String, dynamic> savedPreferences;

  const ThemePreferencesSaved({
    required this.saveTime,
    required this.savedPreferences,
  });

  @override
  List<Object?> get props => [saveTime, savedPreferences];
}

class ThemePreferencesLoaded extends ThemeState {
  final DateTime loadTime;
  final Map<String, dynamic> loadedPreferences;

  const ThemePreferencesLoaded({
    required this.loadTime,
    required this.loadedPreferences,
  });

  @override
  List<Object?> get props => [loadTime, loadedPreferences];
}

class ThemeColorUpdated extends ThemeState {
  final Color newSeedColor;
  final Color previousSeedColor;
  final DateTime updateTime;

  const ThemeColorUpdated({
    required this.newSeedColor,
    required this.previousSeedColor,
    required this.updateTime,
  });

  @override
  List<Object?> get props => [newSeedColor, previousSeedColor, updateTime];
}

class ThemeFontUpdated extends ThemeState {
  final double? newFontSize;
  final String? newFontFamily;
  final DateTime updateTime;

  const ThemeFontUpdated({
    this.newFontSize,
    this.newFontFamily,
    required this.updateTime,
  });

  @override
  List<Object?> get props => [newFontSize, newFontFamily, updateTime];
}

class ThemeAccessibilityUpdated extends ThemeState {
  final bool highContrast;
  final DateTime updateTime;

  const ThemeAccessibilityUpdated({
    required this.highContrast,
    required this.updateTime,
  });

  @override
  List<Object?> get props => [highContrast, updateTime];
}

class ThemeSystemBrightnessApplied extends ThemeState {
  final Brightness systemBrightness;
  final ThemeMode appliedThemeMode;
  final DateTime applicationTime;

  const ThemeSystemBrightnessApplied({
    required this.systemBrightness,
    required this.appliedThemeMode,
    required this.applicationTime,
  });

  @override
  List<Object?> get props => [
    systemBrightness,
    appliedThemeMode,
    applicationTime,
  ];
}

class ThemeCustomApplied extends ThemeState {
  final ThemeData customLightTheme;
  final ThemeData customDarkTheme;
  final DateTime applicationTime;

  const ThemeCustomApplied({
    required this.customLightTheme,
    required this.customDarkTheme,
    required this.applicationTime,
  });

  @override
  List<Object?> get props => [
    customLightTheme,
    customDarkTheme,
    applicationTime,
  ];
}

class ThemeReset extends ThemeState {
  final DateTime resetTime;
  final ThemeData defaultLightTheme;
  final ThemeData defaultDarkTheme;

  const ThemeReset({
    required this.resetTime,
    required this.defaultLightTheme,
    required this.defaultDarkTheme,
  });

  @override
  List<Object?> get props => [resetTime, defaultLightTheme, defaultDarkTheme];
}

class ThemeSettingsExported extends ThemeState {
  final Map<String, dynamic> exportedSettings;
  final DateTime exportTime;

  const ThemeSettingsExported({
    required this.exportedSettings,
    required this.exportTime,
  });

  @override
  List<Object?> get props => [exportedSettings, exportTime];
}

class ThemeSettingsImported extends ThemeState {
  final Map<String, dynamic> importedSettings;
  final DateTime importTime;

  const ThemeSettingsImported({
    required this.importedSettings,
    required this.importTime,
  });

  @override
  List<Object?> get props => [importedSettings, importTime];
}

class ThemeToggled extends ThemeState {
  final ThemeMode previousMode;
  final ThemeMode newMode;
  final DateTime toggleTime;

  const ThemeToggled({
    required this.previousMode,
    required this.newMode,
    required this.toggleTime,
  });

  @override
  List<Object?> get props => [previousMode, newMode, toggleTime];
}
