import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// BLoCs
import 'properties/properties_bloc.dart';
import 'properties/properties_state.dart';
import 'properties/properties_event.dart';
import 'currency/currency_bloc.dart';
import 'currency/currency_state.dart';
import 'currency/currency_event.dart';
import 'theme/theme_bloc.dart';
import 'theme/theme_state.dart';
import 'theme/theme_event.dart';
import 'api_key/api_key_bloc.dart';
import 'api_key/api_key_state.dart';
import 'api_key/api_key_event.dart';

// Services
import '../services/properties_service.dart';
import '../services/api_key_service.dart';

// Legacy Providers (to be migrated)
import '../providers/currency_provider.dart';

class BlocProviders extends StatelessWidget {
  final Widget child;

  const BlocProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services as providers
        RepositoryProvider<PropertiesService>(
          create: (context) => PropertiesService(),
        ),
        ChangeNotifierProvider<ApiKeyService>(
          create: (context) => ApiKeyService.instance,
        ),

        // Legacy providers for backward compatibility
        ChangeNotifierProvider<CurrencyProvider>(
          create: (context) => CurrencyProvider(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Theme BLoC - Initialize first as it affects the entire app
          BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),

          // API Key BLoC - Critical for app functionality
          BlocProvider<ApiKeyBloc>(
            create:
                (context) =>
                    ApiKeyBloc(apiKeyService: context.read<ApiKeyService>()),
          ),

          // Currency BLoC - For currency conversion functionality
          BlocProvider<CurrencyBloc>(create: (context) => CurrencyBloc()),

          // Properties BLoC - Main app functionality
          BlocProvider<PropertiesBloc>(
            create:
                (context) => PropertiesBloc(
                  propertiesService: context.read<PropertiesService>(),
                ),
          ),
        ],
        child: child,
      ),
    );
  }
}

// Extension to easily access BLoCs from context
extension BlocExtensions on BuildContext {
  // Theme BLoC
  ThemeBloc get themeBloc => read<ThemeBloc>();

  // API Key BLoC
  ApiKeyBloc get apiKeyBloc => read<ApiKeyBloc>();

  // Currency BLoC
  CurrencyBloc get currencyBloc => read<CurrencyBloc>();

  // Properties BLoC
  PropertiesBloc get propertiesBloc => read<PropertiesBloc>();

  // Services
  PropertiesService get propertiesService => read<PropertiesService>();
  ApiKeyService get apiKeyService => read<ApiKeyService>();
}

// BLoC Observer for debugging and analytics
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    debugPrint('🔵 BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('🔴 BLoC Error: ${bloc.runtimeType}');
    debugPrint('  Error: $error');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    debugPrint('⚫ BLoC Closed: ${bloc.runtimeType}');
  }
}

// Helper class for BLoC state management utilities
class BlocUtils {
  // Check if any BLoC is in loading state
  static bool isAnyBlocLoading(BuildContext context) {
    final themeBlocState = context.read<ThemeBloc>().state;
    final apiKeyBlocState = context.read<ApiKeyBloc>().state;
    final currencyBlocState = context.read<CurrencyBloc>().state;
    final propertiesBlocState = context.read<PropertiesBloc>().state;

    return themeBlocState is ThemeLoading ||
        apiKeyBlocState is ApiKeyLoading ||
        currencyBlocState is CurrencyLoading ||
        propertiesBlocState is PropertiesLoading;
  }

  // Check if any BLoC has errors
  static bool hasAnyBlocError(BuildContext context) {
    final themeBlocState = context.read<ThemeBloc>().state;
    final apiKeyBlocState = context.read<ApiKeyBloc>().state;
    final currencyBlocState = context.read<CurrencyBloc>().state;
    final propertiesBlocState = context.read<PropertiesBloc>().state;

    return themeBlocState is ThemeError ||
        apiKeyBlocState is ApiKeyError ||
        currencyBlocState is CurrencyError ||
        propertiesBlocState is PropertiesError;
  }

  // Get all error messages
  static List<String> getAllErrorMessages(BuildContext context) {
    final errors = <String>[];

    final themeBlocState = context.read<ThemeBloc>().state;
    if (themeBlocState is ThemeError) {
      errors.add('Theme: ${themeBlocState.message}');
    }

    final apiKeyBlocState = context.read<ApiKeyBloc>().state;
    if (apiKeyBlocState is ApiKeyError) {
      errors.add('API Key: ${apiKeyBlocState.message}');
    }

    final currencyBlocState = context.read<CurrencyBloc>().state;
    if (currencyBlocState is CurrencyError) {
      errors.add('Currency: ${currencyBlocState.message}');
    }

    final propertiesBlocState = context.read<PropertiesBloc>().state;
    if (propertiesBlocState is PropertiesError) {
      errors.add('Properties: ${propertiesBlocState.message}');
    }

    return errors;
  }

  // Refresh all BLoCs
  static void refreshAllBlocs(BuildContext context) {
    context.read<ThemeBloc>().add(const LoadThemePreferences());
    context.read<ApiKeyBloc>().add(const RefreshApiKeyStatus());
    context.read<CurrencyBloc>().add(const RefreshCurrencyRates());
    context.read<PropertiesBloc>().add(const RefreshProperties());
  }

  // Initialize all BLoCs
  static void initializeAllBlocs(BuildContext context) {
    context.read<ThemeBloc>().add(const InitializeTheme());
    context.read<ApiKeyBloc>().add(const InitializeApiKey());
    context.read<CurrencyBloc>().add(const InitializeCurrency());
    context.read<PropertiesBloc>().add(const LoadProperties());
  }
}

// Mixin for widgets that need to listen to multiple BLoCs
mixin MultiBlocListener<T extends StatefulWidget> on State<T> {
  void onThemeStateChanged(ThemeState state) {}
  void onApiKeyStateChanged(ApiKeyState state) {}
  void onCurrencyStateChanged(CurrencyState state) {}
  void onPropertiesStateChanged(PropertiesState state) {}

  @override
  void initState() {
    super.initState();
    _setupBlocListeners();
  }

  void _setupBlocListeners() {
    // Listen to theme changes
    context.read<ThemeBloc>().stream.listen(onThemeStateChanged);

    // Listen to API key changes
    context.read<ApiKeyBloc>().stream.listen(onApiKeyStateChanged);

    // Listen to currency changes
    context.read<CurrencyBloc>().stream.listen(onCurrencyStateChanged);

    // Listen to properties changes
    context.read<PropertiesBloc>().stream.listen(onPropertiesStateChanged);
  }
}

// Custom BLoC builder for handling common states
class AppBlocBuilder<B extends BlocBase<S>, S> extends StatelessWidget {
  final B bloc;
  final Widget Function(BuildContext context, S state) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final BlocBuilderCondition<S>? buildWhen;

  const AppBlocBuilder({
    super.key,
    required this.bloc,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: (context, state) {
        // Handle loading states
        if (_isLoadingState(state) && loadingBuilder != null) {
          return loadingBuilder!(context);
        }

        // Handle error states
        if (_isErrorState(state) && errorBuilder != null) {
          final errorMessage = _getErrorMessage(state);
          return errorBuilder!(context, errorMessage);
        }

        return builder(context, state);
      },
    );
  }

  bool _isLoadingState(S state) {
    return state.toString().contains('Loading');
  }

  bool _isErrorState(S state) {
    return state.toString().contains('Error');
  }

  String _getErrorMessage(S state) {
    if (state is ThemeError) return state.message;
    if (state is ApiKeyError) return state.message;
    if (state is CurrencyError) return state.message;
    if (state is PropertiesError) return state.message;
    return 'Unknown error occurred';
  }
}
