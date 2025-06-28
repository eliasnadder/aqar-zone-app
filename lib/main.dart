import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/api_key_setup_screen.dart';
import 'services/api_key_service.dart';
import 'bloc/bloc_providers.dart';
import 'bloc/theme/theme_bloc.dart';
import 'bloc/theme/theme_state.dart';
import 'bloc/theme/theme_event.dart';
import 'bloc/api_key/api_key_bloc.dart';
import 'bloc/api_key/api_key_state.dart';
import 'bloc/api_key/api_key_event.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Disable Provider debug check for custom providers
    Provider.debugCheckInvalidValueType = null;

    // Initialize HydratedBloc storage
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    );

    // Set up BLoC observer for debugging
    Bloc.observer = AppBlocObserver();

    // Initialize API key service
    await ApiKeyService.instance.initialize();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Log the error and run a fallback app
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Run a minimal fallback app
    runApp(const FallbackApp());
  }
}

// Fallback app for when initialization fails
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqar Zone - Error',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the app',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Force restart the app
                  SystemNavigator.pop();
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProviders(
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<ApiKeyBloc, ApiKeyState>(
            builder: (context, apiKeyState) {
              // Determine theme data
              ThemeData lightTheme;
              ThemeData darkTheme;
              ThemeMode themeMode;

              if (themeState is ThemeLoaded) {
                lightTheme = themeState.lightTheme;
                darkTheme = themeState.darkTheme;
                themeMode = themeState.themeMode;
              } else {
                // Fallback themes
                lightTheme = _buildLightTheme();
                darkTheme = _buildDarkTheme();
                themeMode = ThemeMode.system;
              }

              return MaterialApp(
                title: 'Aqar Zone - AI Property Assistant',
                themeMode: themeMode,
                theme: lightTheme,
                darkTheme: darkTheme,
                home: _buildHome(context, apiKeyState, themeState),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(
    BuildContext context,
    ApiKeyState apiKeyState,
    ThemeState themeState,
  ) {
    // Show loading screen while initializing
    if (apiKeyState is ApiKeyLoading || themeState is ThemeLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    // Show API key setup if not completed
    if (apiKeyState is ApiKeyEmpty ||
        (apiKeyState is ApiKeyLoaded && !apiKeyState.hasCompletedSetup)) {
      return ApiKeySetupScreen(
        onSetupComplete: () {
          context.read<ApiKeyBloc>().add(const CompleteSetup());
        },
      );
    }

    // Show main app
    return MainNavigationScreen(
      onThemeToggle: () {
        context.read<ThemeBloc>().add(const ToggleTheme());
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
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
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
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
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
