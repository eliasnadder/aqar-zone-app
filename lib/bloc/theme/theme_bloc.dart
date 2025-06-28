import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';
  static const String _fontSizeKey = 'font_size';
  static const String _fontFamilyKey = 'font_family';
  static const String _highContrastKey = 'high_contrast';
  static const String _followSystemKey = 'follow_system';

  static const Color _defaultSeedColor = Color(0xFF2563EB);
  static const double _defaultFontSize = 14.0;
  static const String _defaultFontFamily = 'Roboto';

  ThemeBloc() : super(const ThemeInitial()) {
    on<InitializeTheme>(_onInitializeTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetThemeMode>(_onSetThemeMode);
    on<SetLightTheme>(_onSetLightTheme);
    on<SetDarkTheme>(_onSetDarkTheme);
    on<SetSystemTheme>(_onSetSystemTheme);
    on<UpdateThemeColor>(_onUpdateThemeColor);
    on<ResetThemeToDefault>(_onResetThemeToDefault);
    on<SaveThemePreferences>(_onSaveThemePreferences);
    on<LoadThemePreferences>(_onLoadThemePreferences);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateFontFamily>(_onUpdateFontFamily);
    on<EnableHighContrast>(_onEnableHighContrast);
    on<UpdateBrightness>(_onUpdateBrightness);
    on<SetCustomTheme>(_onSetCustomTheme);
    on<ApplySystemBrightness>(_onApplySystemBrightness);
    on<UpdateThemePreferences>(_onUpdateThemePreferences);
    on<ExportThemeSettings>(_onExportThemeSettings);
    on<ImportThemeSettings>(_onImportThemeSettings);

    // Initialize theme on startup
    add(const InitializeTheme());
  }

  Future<void> _onInitializeTheme(
    InitializeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      emit(const ThemeLoading());

      final prefs = await SharedPreferences.getInstance();

      // Load saved preferences
      final themeModeIndex =
          prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
      final themeMode = ThemeMode.values[themeModeIndex];
      final seedColorValue =
          prefs.getInt(_seedColorKey) ?? _defaultSeedColor.value;
      final seedColor = Color(seedColorValue);
      final fontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
      final fontFamily = prefs.getString(_fontFamilyKey) ?? _defaultFontFamily;
      final highContrast = prefs.getBool(_highContrastKey) ?? false;
      final followSystem = prefs.getBool(_followSystemKey) ?? true;

      // Build themes
      final lightTheme = _buildLightTheme(
        seedColor,
        fontSize,
        fontFamily,
        highContrast,
      );
      final darkTheme = _buildDarkTheme(
        seedColor,
        fontSize,
        fontFamily,
        highContrast,
      );

      emit(
        ThemeLoaded(
          themeMode: themeMode,
          lightTheme: lightTheme,
          darkTheme: darkTheme,
          seedColor: seedColor,
          fontSize: fontSize,
          fontFamily: fontFamily,
          highContrast: highContrast,
          followSystemBrightness: followSystem,
        ),
      );
    } catch (e) {
      emit(
        ThemeError(
          message: e.toString(),
          fallbackLightTheme: _buildLightTheme(
            _defaultSeedColor,
            _defaultFontSize,
            _defaultFontFamily,
            false,
          ),
          fallbackDarkTheme: _buildDarkTheme(
            _defaultSeedColor,
            _defaultFontSize,
            _defaultFontFamily,
            false,
          ),
        ),
      );
    }
  }

  Future<void> _onToggleTheme(
    ToggleTheme event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;
      final previousMode = currentState.themeMode;

      ThemeMode newMode;
      switch (currentState.themeMode) {
        case ThemeMode.light:
          newMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          newMode = ThemeMode.system;
          break;
        case ThemeMode.system:
          newMode = ThemeMode.light;
          break;
      }

      emit(
        ThemeToggled(
          previousMode: previousMode,
          newMode: newMode,
          toggleTime: DateTime.now(),
        ),
      );

      add(SetThemeMode(themeMode: newMode));
    }
  }

  Future<void> _onSetThemeMode(
    SetThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      emit(
        ThemeUpdating(
          currentThemeMode: currentState.themeMode,
          updateType: 'theme_mode',
        ),
      );

      final updatedState = currentState.copyWith(themeMode: event.themeMode);
      emit(updatedState);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, event.themeMode.index);
    }
  }

  Future<void> _onSetLightTheme(
    SetLightTheme event,
    Emitter<ThemeState> emit,
  ) async {
    add(const SetThemeMode(themeMode: ThemeMode.light));
  }

  Future<void> _onSetDarkTheme(
    SetDarkTheme event,
    Emitter<ThemeState> emit,
  ) async {
    add(const SetThemeMode(themeMode: ThemeMode.dark));
  }

  Future<void> _onSetSystemTheme(
    SetSystemTheme event,
    Emitter<ThemeState> emit,
  ) async {
    add(const SetThemeMode(themeMode: ThemeMode.system));
  }

  Future<void> _onUpdateThemeColor(
    UpdateThemeColor event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      if (state is ThemeLoaded) {
        final currentState = state as ThemeLoaded;

        emit(
          ThemeColorUpdated(
            newSeedColor: event.seedColor,
            previousSeedColor: currentState.seedColor,
            updateTime: DateTime.now(),
          ),
        );

        final lightTheme = _buildLightTheme(
          event.seedColor,
          currentState.fontSize,
          currentState.fontFamily,
          currentState.highContrast,
        );

        final darkTheme = _buildDarkTheme(
          event.seedColor,
          currentState.fontSize,
          currentState.fontFamily,
          currentState.highContrast,
        );

        final updatedState = currentState.copyWith(
          seedColor: event.seedColor,
          lightTheme: lightTheme,
          darkTheme: darkTheme,
        );

        emit(updatedState);

        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_seedColorKey, event.seedColor.value);
      }
    } catch (e) {
      emit(
        ThemeError(message: 'Failed to update theme color: ${e.toString()}'),
      );
    }
  }

  Future<void> _onResetThemeToDefault(
    ResetThemeToDefault event,
    Emitter<ThemeState> emit,
  ) async {
    final defaultLightTheme = _buildLightTheme(
      _defaultSeedColor,
      _defaultFontSize,
      _defaultFontFamily,
      false,
    );
    final defaultDarkTheme = _buildDarkTheme(
      _defaultSeedColor,
      _defaultFontSize,
      _defaultFontFamily,
      false,
    );

    emit(
      ThemeReset(
        resetTime: DateTime.now(),
        defaultLightTheme: defaultLightTheme,
        defaultDarkTheme: defaultDarkTheme,
      ),
    );

    emit(
      ThemeLoaded(
        themeMode: ThemeMode.system,
        lightTheme: defaultLightTheme,
        darkTheme: defaultDarkTheme,
        seedColor: _defaultSeedColor,
        fontSize: _defaultFontSize,
        fontFamily: _defaultFontFamily,
        highContrast: false,
        followSystemBrightness: true,
      ),
    );

    // Clear saved preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    await prefs.remove(_seedColorKey);
    await prefs.remove(_fontSizeKey);
    await prefs.remove(_fontFamilyKey);
    await prefs.remove(_highContrastKey);
    await prefs.remove(_followSystemKey);
  }

  Future<void> _onSaveThemePreferences(
    SaveThemePreferences event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themeModeKey, currentState.themeMode.index);
        await prefs.setInt(_seedColorKey, currentState.seedColor.value);
        await prefs.setDouble(_fontSizeKey, currentState.fontSize);
        await prefs.setString(_fontFamilyKey, currentState.fontFamily);
        await prefs.setBool(_highContrastKey, currentState.highContrast);
        await prefs.setBool(
          _followSystemKey,
          currentState.followSystemBrightness,
        );

        final savedPreferences = {
          'themeMode': currentState.themeMode.index,
          'seedColor': currentState.seedColor.value,
          'fontSize': currentState.fontSize,
          'fontFamily': currentState.fontFamily,
          'highContrast': currentState.highContrast,
          'followSystemBrightness': currentState.followSystemBrightness,
        };

        emit(
          ThemePreferencesSaved(
            saveTime: DateTime.now(),
            savedPreferences: savedPreferences,
          ),
        );
      } catch (e) {
        emit(ThemeError(message: e.toString()));
      }
    }
  }

  Future<void> _onLoadThemePreferences(
    LoadThemePreferences event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final loadedPreferences = {
        'themeMode': prefs.getInt(_themeModeKey),
        'seedColor': prefs.getInt(_seedColorKey),
        'fontSize': prefs.getDouble(_fontSizeKey),
        'fontFamily': prefs.getString(_fontFamilyKey),
        'highContrast': prefs.getBool(_highContrastKey),
        'followSystemBrightness': prefs.getBool(_followSystemKey),
      };

      emit(
        ThemePreferencesLoaded(
          loadTime: DateTime.now(),
          loadedPreferences: loadedPreferences,
        ),
      );

      // Reinitialize with loaded preferences
      add(const InitializeTheme());
    } catch (e) {
      emit(ThemeError(message: e.toString()));
    }
  }

  Future<void> _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      emit(
        ThemeFontUpdated(
          newFontSize: event.fontSize,
          updateTime: DateTime.now(),
        ),
      );

      final lightTheme = _buildLightTheme(
        currentState.seedColor,
        event.fontSize,
        currentState.fontFamily,
        currentState.highContrast,
      );

      final darkTheme = _buildDarkTheme(
        currentState.seedColor,
        event.fontSize,
        currentState.fontFamily,
        currentState.highContrast,
      );

      final updatedState = currentState.copyWith(
        fontSize: event.fontSize,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );

      emit(updatedState);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, event.fontSize);
    }
  }

  Future<void> _onUpdateFontFamily(
    UpdateFontFamily event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      emit(
        ThemeFontUpdated(
          newFontFamily: event.fontFamily,
          updateTime: DateTime.now(),
        ),
      );

      final lightTheme = _buildLightTheme(
        currentState.seedColor,
        currentState.fontSize,
        event.fontFamily,
        currentState.highContrast,
      );

      final darkTheme = _buildDarkTheme(
        currentState.seedColor,
        currentState.fontSize,
        event.fontFamily,
        currentState.highContrast,
      );

      final updatedState = currentState.copyWith(
        fontFamily: event.fontFamily,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );

      emit(updatedState);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontFamilyKey, event.fontFamily);
    }
  }

  Future<void> _onEnableHighContrast(
    EnableHighContrast event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      emit(
        ThemeAccessibilityUpdated(
          highContrast: event.enabled,
          updateTime: DateTime.now(),
        ),
      );

      final lightTheme = _buildLightTheme(
        currentState.seedColor,
        currentState.fontSize,
        currentState.fontFamily,
        event.enabled,
      );

      final darkTheme = _buildDarkTheme(
        currentState.seedColor,
        currentState.fontSize,
        currentState.fontFamily,
        event.enabled,
      );

      final updatedState = currentState.copyWith(
        highContrast: event.enabled,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
      );

      emit(updatedState);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, event.enabled);
    }
  }

  Future<void> _onUpdateBrightness(
    UpdateBrightness event,
    Emitter<ThemeState> emit,
  ) async {
    final themeMode =
        event.brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark;

    add(SetThemeMode(themeMode: themeMode));
  }

  Future<void> _onSetCustomTheme(
    SetCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    emit(
      ThemeCustomApplied(
        customLightTheme: event.lightTheme,
        customDarkTheme: event.darkTheme,
        applicationTime: DateTime.now(),
      ),
    );

    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;
      emit(
        currentState.copyWith(
          lightTheme: event.lightTheme,
          darkTheme: event.darkTheme,
        ),
      );
    }
  }

  Future<void> _onApplySystemBrightness(
    ApplySystemBrightness event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      if (currentState.followSystemBrightness &&
          currentState.themeMode == ThemeMode.system) {
        final appliedThemeMode =
            event.systemBrightness == Brightness.light
                ? ThemeMode.light
                : ThemeMode.dark;

        emit(
          ThemeSystemBrightnessApplied(
            systemBrightness: event.systemBrightness,
            appliedThemeMode: appliedThemeMode,
            applicationTime: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> _onUpdateThemePreferences(
    UpdateThemePreferences event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      // Update individual preferences
      if (event.themeMode != null) {
        add(SetThemeMode(themeMode: event.themeMode!));
      }

      if (event.seedColor != null) {
        add(UpdateThemeColor(seedColor: event.seedColor!));
      }

      if (event.fontSize != null) {
        add(UpdateFontSize(fontSize: event.fontSize!));
      }

      if (event.fontFamily != null) {
        add(UpdateFontFamily(fontFamily: event.fontFamily!));
      }

      if (event.highContrast != null) {
        add(EnableHighContrast(enabled: event.highContrast!));
      }
    }
  }

  Future<void> _onExportThemeSettings(
    ExportThemeSettings event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is ThemeLoaded) {
      final currentState = state as ThemeLoaded;

      final exportedSettings = {
        'themeMode': currentState.themeMode.index,
        'seedColor': currentState.seedColor.value,
        'fontSize': currentState.fontSize,
        'fontFamily': currentState.fontFamily,
        'highContrast': currentState.highContrast,
        'followSystemBrightness': currentState.followSystemBrightness,
        'exportTime': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      emit(
        ThemeSettingsExported(
          exportedSettings: exportedSettings,
          exportTime: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _onImportThemeSettings(
    ImportThemeSettings event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      emit(
        ThemeSettingsImported(
          importedSettings: event.settings,
          importTime: DateTime.now(),
        ),
      );

      // Apply imported settings
      final themeMode =
          ThemeMode.values[event.settings['themeMode'] ??
              ThemeMode.system.index];
      final seedColor = Color(
        event.settings['seedColor'] ?? _defaultSeedColor.value,
      );
      final fontSize =
          (event.settings['fontSize'] ?? _defaultFontSize).toDouble();
      final fontFamily = event.settings['fontFamily'] ?? _defaultFontFamily;
      final highContrast = event.settings['highContrast'] ?? false;

      add(
        UpdateThemePreferences(
          themeMode: themeMode,
          seedColor: seedColor,
          fontSize: fontSize,
          fontFamily: fontFamily,
          highContrast: highContrast,
        ),
      );
    } catch (e) {
      emit(
        ThemeError(message: 'Failed to import theme settings: ${e.toString()}'),
      );
    }
  }

  // Helper methods for building themes
  ThemeData _buildLightTheme(
    Color seedColor,
    double fontSize,
    String fontFamily,
    bool highContrast,
  ) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: highContrast ? _applyHighContrast(colorScheme) : colorScheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _buildTextTheme(fontSize, fontFamily, colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(
    Color seedColor,
    double fontSize,
    String fontFamily,
    bool highContrast,
  ) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: highContrast ? _applyHighContrast(colorScheme) : colorScheme,
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _buildTextTheme(fontSize, fontFamily, colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  TextTheme _buildTextTheme(
    double fontSize,
    String fontFamily,
    Color textColor,
  ) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSize + 22,
        fontFamily: fontFamily,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: fontSize + 18,
        fontFamily: fontFamily,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: fontSize + 14,
        fontFamily: fontFamily,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: fontSize + 12,
        fontFamily: fontFamily,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: fontSize + 8,
        fontFamily: fontFamily,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: fontSize + 4,
        fontFamily: fontFamily,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: fontSize + 2,
        fontFamily: fontFamily,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: fontSize - 2,
        fontFamily: fontFamily,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSize - 2,
        fontFamily: fontFamily,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: fontSize - 4,
        fontFamily: fontFamily,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: fontSize - 2,
        fontFamily: fontFamily,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: fontSize - 4,
        fontFamily: fontFamily,
        color: textColor,
      ),
    );
  }

  ColorScheme _applyHighContrast(ColorScheme colorScheme) {
    if (colorScheme.brightness == Brightness.light) {
      return colorScheme.copyWith(
        surface: Colors.white,
        onSurface: Colors.black,
        primary: Colors.black,
        onPrimary: Colors.white,
      );
    } else {
      return colorScheme.copyWith(
        surface: Colors.black,
        onSurface: Colors.white,
        primary: Colors.white,
        onPrimary: Colors.black,
      );
    }
  }
}
