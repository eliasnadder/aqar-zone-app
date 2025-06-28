import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'voice_service.dart';
import 'ai_service.dart';

class BackgroundConversationService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel(
    'background_conversation',
  );

  bool _isBackgroundModeEnabled = false;
  bool _isCurrentlyInBackground = false;
  bool _isConversationActive = false;
  bool _allowBackgroundListening = true;
  bool _showFloatingWidget = false;

  VoiceService? _voiceService;
  AIService? _aiService;

  Timer? _backgroundTimer;
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;

  // Background conversation state
  String _lastUserMessage = '';
  String _lastAiResponse = '';
  int _backgroundMessageCount = 0;
  DateTime? _backgroundStartTime;

  // Callbacks
  Function(String)? _onBackgroundMessage;
  Function(String)? _onBackgroundResponse;
  VoidCallback? _onBackgroundModeChanged;

  // Getters
  bool get isBackgroundModeEnabled => _isBackgroundModeEnabled;
  bool get isCurrentlyInBackground => _isCurrentlyInBackground;
  bool get isConversationActive => _isConversationActive;
  bool get allowBackgroundListening => _allowBackgroundListening;
  bool get showFloatingWidget => _showFloatingWidget;
  String get lastUserMessage => _lastUserMessage;
  String get lastAiResponse => _lastAiResponse;
  int get backgroundMessageCount => _backgroundMessageCount;
  DateTime? get backgroundStartTime => _backgroundStartTime;

  Future<void> initialize({
    required VoiceService voiceService,
    required AIService aiService,
    Function(String)? onBackgroundMessage,
    Function(String)? onBackgroundResponse,
    VoidCallback? onBackgroundModeChanged,
  }) async {
    _voiceService = voiceService;
    _aiService = aiService;
    _onBackgroundMessage = onBackgroundMessage;
    _onBackgroundResponse = onBackgroundResponse;
    _onBackgroundModeChanged = onBackgroundModeChanged;

    await _setupPlatformChannels();
    _setupAppLifecycleListener();
  }

  Future<void> _setupPlatformChannels() async {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _channel.invokeMethod('initialize');
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up background service: $e');
      }
    }
  }

  void _setupAppLifecycleListener() {
    // In a real app, you'd use WidgetsBindingObserver
    // For demo purposes, we'll simulate lifecycle changes
    _simulateAppLifecycleChanges();
  }

  void _simulateAppLifecycleChanges() {
    // Simulate app going to background occasionally
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        final shouldGoBackground = DateTime.now().second % 30 == 0;
        if (shouldGoBackground && !_isCurrentlyInBackground) {
          _handleAppStateChange(AppLifecycleState.paused);
        } else if (!shouldGoBackground && _isCurrentlyInBackground) {
          _handleAppStateChange(AppLifecycleState.resumed);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppStateChanged':
        final state = call.arguments as String;
        _handleAppStateChange(_parseAppLifecycleState(state));
        break;
      case 'onBackgroundVoiceInput':
        final text = call.arguments as String;
        _handleBackgroundVoiceInput(text);
        break;
      case 'onFloatingWidgetTapped':
        _handleFloatingWidgetTap();
        break;
      default:
        if (kDebugMode) {
          print('Unknown method call: ${call.method}');
        }
    }
  }

  AppLifecycleState _parseAppLifecycleState(String state) {
    switch (state) {
      case 'paused':
        return AppLifecycleState.paused;
      case 'resumed':
        return AppLifecycleState.resumed;
      case 'inactive':
        return AppLifecycleState.inactive;
      case 'detached':
        return AppLifecycleState.detached;
      default:
        return AppLifecycleState.resumed;
    }
  }

  void _handleAppStateChange(AppLifecycleState state) {
    final wasInBackground = _isCurrentlyInBackground;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isCurrentlyInBackground = true;
        if (_isBackgroundModeEnabled && _isConversationActive) {
          _startBackgroundMode();
        }
        break;

      case AppLifecycleState.resumed:
        _isCurrentlyInBackground = false;
        if (wasInBackground) {
          _stopBackgroundMode();
        }
        break;

      case AppLifecycleState.detached:
        _stopBackgroundMode();
        break;
    }

    if (wasInBackground != _isCurrentlyInBackground) {
      _onBackgroundModeChanged?.call();
      notifyListeners();
    }
  }

  void _startBackgroundMode() {
    if (!_allowBackgroundListening || !_isBackgroundModeEnabled) return;

    if (kDebugMode) {
      print('Starting background conversation mode');
    }

    _backgroundStartTime = DateTime.now();
    _backgroundMessageCount = 0;

    // Show floating widget
    _showFloatingWidget = true;
    _showFloatingWidgetUI();

    // Continue voice listening in background
    _continueVoiceListeningInBackground();

    // Start background timer for periodic checks
    _backgroundTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkBackgroundStatus();
    });

    notifyListeners();
  }

  void _stopBackgroundMode() {
    if (kDebugMode) {
      print('Stopping background conversation mode');
    }

    _backgroundTimer?.cancel();
    _hideFloatingWidget();
    _showFloatingWidget = false;

    notifyListeners();
  }

  void _continueVoiceListeningInBackground() {
    // In a real app, you'd configure the voice service for background operation
    // This might involve:
    // 1. Requesting background audio permissions
    // 2. Setting up background audio session
    // 3. Configuring wake word detection

    if (kDebugMode) {
      print('Configuring voice service for background operation');
    }
  }

  void _handleBackgroundVoiceInput(String text) {
    if (!_isCurrentlyInBackground || !_isBackgroundModeEnabled) return;

    _lastUserMessage = text;
    _backgroundMessageCount++;

    if (kDebugMode) {
      print('Background voice input: $text');
    }

    _onBackgroundMessage?.call(text);

    // Process the message with AI
    _processBackgroundMessage(text);

    notifyListeners();
  }

  Future<void> _processBackgroundMessage(String message) async {
    try {
      final response = await _aiService?.processUserMessage(message);

      if (response != null) {
        _lastAiResponse = response;
        _onBackgroundResponse?.call(response);

        // Speak response in background
        await _voiceService?.speak(response);

        // Update floating widget with response
        _updateFloatingWidget(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing background message: $e');
      }
    }
  }

  void _checkBackgroundStatus() {
    if (!_isCurrentlyInBackground) {
      _stopBackgroundMode();
      return;
    }

    // Check if conversation has been inactive for too long
    if (_backgroundStartTime != null) {
      final duration = DateTime.now().difference(_backgroundStartTime!);
      if (duration.inMinutes > 30) {
        // Auto-stop after 30 minutes of background operation
        _stopBackgroundMode();
      }
    }
  }

  void _showFloatingWidgetUI() {
    try {
      _channel.invokeMethod('showFloatingWidget', {
        'title': 'محادثة صوتية نشطة',
        'subtitle': 'اضغط للعودة إلى التطبيق',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error showing floating widget: $e');
      }
    }
  }

  void _hideFloatingWidget() {
    try {
      _channel.invokeMethod('hideFloatingWidget');
    } catch (e) {
      if (kDebugMode) {
        print('Error hiding floating widget: $e');
      }
    }
  }

  void _updateFloatingWidget(String message) {
    try {
      _channel.invokeMethod('updateFloatingWidget', {
        'message':
            message.length > 50 ? '${message.substring(0, 50)}...' : message,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating floating widget: $e');
      }
    }
  }

  void _handleFloatingWidgetTap() {
    // Bring app to foreground
    try {
      _channel.invokeMethod('bringAppToForeground');
    } catch (e) {
      if (kDebugMode) {
        print('Error bringing app to foreground: $e');
      }
    }
  }

  // Public methods
  void enableBackgroundMode() {
    _isBackgroundModeEnabled = true;
    notifyListeners();

    if (kDebugMode) {
      print('Background conversation mode enabled');
    }
  }

  void disableBackgroundMode() {
    _isBackgroundModeEnabled = false;

    if (_isCurrentlyInBackground) {
      _stopBackgroundMode();
    }

    notifyListeners();

    if (kDebugMode) {
      print('Background conversation mode disabled');
    }
  }

  void startConversation() {
    _isConversationActive = true;
    notifyListeners();
  }

  void stopConversation() {
    _isConversationActive = false;

    if (_isCurrentlyInBackground) {
      _stopBackgroundMode();
    }

    notifyListeners();
  }

  void setAllowBackgroundListening(bool allow) {
    _allowBackgroundListening = allow;

    if (!allow && _isCurrentlyInBackground) {
      _stopBackgroundMode();
    }

    notifyListeners();
  }

  // Simulate background mode for testing
  void simulateBackgroundMode() {
    _handleAppStateChange(AppLifecycleState.paused);

    // Simulate voice input after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _handleBackgroundVoiceInput('أريد معلومات عن العقارات المتاحة');
    });
  }

  void simulateForegroundMode() {
    _handleAppStateChange(AppLifecycleState.resumed);
  }

  // Get background conversation statistics
  Map<String, dynamic> getBackgroundStatistics() {
    final duration =
        _backgroundStartTime != null
            ? DateTime.now().difference(_backgroundStartTime!)
            : Duration.zero;

    return {
      'isBackgroundModeEnabled': _isBackgroundModeEnabled,
      'isCurrentlyInBackground': _isCurrentlyInBackground,
      'backgroundMessageCount': _backgroundMessageCount,
      'backgroundDuration': duration.inMinutes,
      'lastUserMessage': _lastUserMessage,
      'lastAiResponse': _lastAiResponse,
    };
  }

  bool get mounted => true; // Simplified for this example

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _lifecycleSubscription?.cancel();
    _hideFloatingWidget();
    super.dispose();
  }
}
