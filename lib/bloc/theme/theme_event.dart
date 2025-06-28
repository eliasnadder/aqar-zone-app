import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class InitializeTheme extends ThemeEvent {
  const InitializeTheme();
}

class ToggleTheme extends ThemeEvent {
  const ToggleTheme();
}

class SetThemeMode extends ThemeEvent {
  final ThemeMode themeMode;

  const SetThemeMode({required this.themeMode});

  @override
  List<Object?> get props => [themeMode];
}

class SetLightTheme extends ThemeEvent {
  const SetLightTheme();
}

class SetDarkTheme extends ThemeEvent {
  const SetDarkTheme();
}

class SetSystemTheme extends ThemeEvent {
  const SetSystemTheme();
}

class UpdateThemeColor extends ThemeEvent {
  final Color seedColor;

  const UpdateThemeColor({required this.seedColor});

  @override
  List<Object?> get props => [seedColor];
}

class ResetThemeToDefault extends ThemeEvent {
  const ResetThemeToDefault();
}

class SaveThemePreferences extends ThemeEvent {
  const SaveThemePreferences();
}

class LoadThemePreferences extends ThemeEvent {
  const LoadThemePreferences();
}

class UpdateFontSize extends ThemeEvent {
  final double fontSize;

  const UpdateFontSize({required this.fontSize});

  @override
  List<Object?> get props => [fontSize];
}

class UpdateFontFamily extends ThemeEvent {
  final String fontFamily;

  const UpdateFontFamily({required this.fontFamily});

  @override
  List<Object?> get props => [fontFamily];
}

class EnableHighContrast extends ThemeEvent {
  final bool enabled;

  const EnableHighContrast({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class UpdateBrightness extends ThemeEvent {
  final Brightness brightness;

  const UpdateBrightness({required this.brightness});

  @override
  List<Object?> get props => [brightness];
}

class SetCustomTheme extends ThemeEvent {
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const SetCustomTheme({
    required this.lightTheme,
    required this.darkTheme,
  });

  @override
  List<Object?> get props => [lightTheme, darkTheme];
}

class ApplySystemBrightness extends ThemeEvent {
  final Brightness systemBrightness;

  const ApplySystemBrightness({required this.systemBrightness});

  @override
  List<Object?> get props => [systemBrightness];
}

class UpdateThemePreferences extends ThemeEvent {
  final ThemeMode? themeMode;
  final Color? seedColor;
  final double? fontSize;
  final String? fontFamily;
  final bool? highContrast;

  const UpdateThemePreferences({
    this.themeMode,
    this.seedColor,
    this.fontSize,
    this.fontFamily,
    this.highContrast,
  });

  @override
  List<Object?> get props => [
    themeMode,
    seedColor,
    fontSize,
    fontFamily,
    highContrast,
  ];
}

class ExportThemeSettings extends ThemeEvent {
  const ExportThemeSettings();
}

class ImportThemeSettings extends ThemeEvent {
  final Map<String, dynamic> settings;

  const ImportThemeSettings({required this.settings});

  @override
  List<Object?> get props => [settings];
}
