import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AutoPauseService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('auto_pause_service');
  
  bool _isPhoneCallActive = false;
  bool _hasNotificationInterruption = false;
  bool _isAppInBackground = false;
  bool _isHeadphonesConnected = false;
  bool _isBluetoothConnected = false;
  
  StreamSubscription<bool>? _phoneCallSubscription;
  StreamSubscription<bool>? _notificationSubscription;
  StreamSubscription<bool>? _appStateSubscription;
  StreamSubscription<bool>? _audioDeviceSubscription;
  
  Timer? _resumeTimer;
  
  // Callbacks for voice service integration
  VoidCallback? _onPauseRequested;
  VoidCallback? _onResumeRequested;
  
  // Getters
  bool get isPhoneCallActive => _isPhoneCallActive;
  bool get hasNotificationInterruption => _hasNotificationInterruption;
  bool get isAppInBackground => _isAppInBackground;
  bool get isHeadphonesConnected => _isHeadphonesConnected;
  bool get isBluetoothConnected => _isBluetoothConnected;
  bool get shouldPauseVoice => _isPhoneCallActive || _hasNotificationInterruption || _isAppInBackground;
  
  Future<void> initialize({
    VoidCallback? onPauseRequested,
    VoidCallback? onResumeRequested,
  }) async {
    _onPauseRequested = onPauseRequested;
    _onResumeRequested = onResumeRequested;
    
    await _setupPlatformChannels();
    _startMonitoring();
  }
  
  Future<void> _setupPlatformChannels() async {
    try {
      // Set up method channel for native platform integration
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Initialize platform-specific monitoring
      await _channel.invokeMethod('initialize');
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up platform channels: $e');
      }
    }
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPhoneCallStateChanged':
        _handlePhoneCallStateChange(call.arguments as bool);
        break;
      case 'onNotificationReceived':
        _handleNotificationInterruption();
        break;
      case 'onAppStateChanged':
        _handleAppStateChange(call.arguments as bool);
        break;
      case 'onAudioDeviceChanged':
        _handleAudioDeviceChange(call.arguments as Map);
        break;
      default:
        if (kDebugMode) {
          print('Unknown method call: ${call.method}');
        }
    }
  }
  
  void _startMonitoring() {
    // Start simulated monitoring for demo purposes
    // In a real app, these would be connected to actual platform events
    _simulatePhoneCallMonitoring();
    _simulateNotificationMonitoring();
    _simulateAppStateMonitoring();
    _simulateAudioDeviceMonitoring();
  }
  
  void _handlePhoneCallStateChange(bool isActive) {
    if (_isPhoneCallActive != isActive) {
      _isPhoneCallActive = isActive;
      
      if (isActive) {
        _requestPause('Phone call detected');
      } else {
        _scheduleResume('Phone call ended', const Duration(seconds: 2));
      }
      
      notifyListeners();
    }
  }
  
  void _handleNotificationInterruption() {
    _hasNotificationInterruption = true;
    _requestPause('Notification received');
    
    // Clear interruption flag after a short delay
    _scheduleResume('Notification cleared', const Duration(seconds: 3));
    
    notifyListeners();
  }
  
  void _handleAppStateChange(bool isInBackground) {
    if (_isAppInBackground != isInBackground) {
      _isAppInBackground = isInBackground;
      
      if (isInBackground) {
        _requestPause('App moved to background');
      } else {
        _scheduleResume('App returned to foreground', const Duration(seconds: 1));
      }
      
      notifyListeners();
    }
  }
  
  void _handleAudioDeviceChange(Map deviceInfo) {
    final bool headphonesConnected = deviceInfo['headphones'] ?? false;
    final bool bluetoothConnected = deviceInfo['bluetooth'] ?? false;
    
    bool shouldNotify = false;
    
    if (_isHeadphonesConnected != headphonesConnected) {
      _isHeadphonesConnected = headphonesConnected;
      shouldNotify = true;
      
      if (headphonesConnected) {
        _showAudioDeviceNotification('Headphones connected');
      } else {
        _showAudioDeviceNotification('Headphones disconnected');
        _requestPause('Audio device disconnected');
      }
    }
    
    if (_isBluetoothConnected != bluetoothConnected) {
      _isBluetoothConnected = bluetoothConnected;
      shouldNotify = true;
      
      if (bluetoothConnected) {
        _showAudioDeviceNotification('Bluetooth audio connected');
      } else {
        _showAudioDeviceNotification('Bluetooth audio disconnected');
        _requestPause('Bluetooth audio disconnected');
      }
    }
    
    if (shouldNotify) {
      notifyListeners();
    }
  }
  
  void _requestPause(String reason) {
    if (kDebugMode) {
      print('Auto-pause requested: $reason');
    }
    
    _onPauseRequested?.call();
  }
  
  void _scheduleResume(String reason, Duration delay) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(delay, () {
      if (kDebugMode) {
        print('Auto-resume scheduled: $reason');
      }
      
      // Clear interruption flags
      _hasNotificationInterruption = false;
      
      // Only resume if no other interruptions are active
      if (!shouldPauseVoice) {
        _onResumeRequested?.call();
      }
      
      notifyListeners();
    });
  }
  
  void _showAudioDeviceNotification(String message) {
    if (kDebugMode) {
      print('Audio device change: $message');
    }
    // In a real app, you might show a toast or notification
  }
  
  // Simulation methods for demo purposes
  void _simulatePhoneCallMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        // Simulate occasional phone calls
        if (!_isPhoneCallActive && DateTime.now().second % 30 == 0) {
          simulatePhoneCall();
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  void _simulateNotificationMonitoring() {
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        // Simulate occasional notifications
        if (DateTime.now().second % 45 == 0) {
          simulateNotification();
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  void _simulateAppStateMonitoring() {
    // App state changes are typically handled by the Flutter framework
    // This is just for demonstration
  }
  
  void _simulateAudioDeviceMonitoring() {
    Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        // Simulate occasional audio device changes
        if (DateTime.now().second % 60 == 0) {
          simulateAudioDeviceChange();
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  // Public methods for testing/simulation
  void simulatePhoneCall() {
    _handlePhoneCallStateChange(true);
    
    // Simulate call ending after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _handlePhoneCallStateChange(false);
      }
    });
  }
  
  void simulateNotification() {
    _handleNotificationInterruption();
  }
  
  void simulateAppBackground() {
    _handleAppStateChange(true);
    
    // Simulate returning to foreground after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _handleAppStateChange(false);
      }
    });
  }
  
  void simulateAudioDeviceChange() {
    final Map<String, dynamic> deviceInfo = {
      'headphones': !_isHeadphonesConnected,
      'bluetooth': _isBluetoothConnected,
    };
    _handleAudioDeviceChange(deviceInfo);
  }
  
  // Manual control methods
  void manualPause(String reason) {
    _requestPause('Manual pause: $reason');
  }
  
  void manualResume(String reason) {
    _resumeTimer?.cancel();
    
    // Clear all interruption flags
    _hasNotificationInterruption = false;
    
    if (kDebugMode) {
      print('Manual resume: $reason');
    }
    
    _onResumeRequested?.call();
    notifyListeners();
  }
  
  // Status information
  String getStatusMessage() {
    if (_isPhoneCallActive) {
      return 'Paused: Phone call active';
    } else if (_hasNotificationInterruption) {
      return 'Paused: Notification received';
    } else if (_isAppInBackground) {
      return 'Paused: App in background';
    } else {
      return 'Active';
    }
  }
  
  List<String> getActiveInterruptions() {
    List<String> interruptions = [];
    
    if (_isPhoneCallActive) interruptions.add('Phone call');
    if (_hasNotificationInterruption) interruptions.add('Notification');
    if (_isAppInBackground) interruptions.add('Background');
    
    return interruptions;
  }
  
  bool get mounted => true; // Simplified for this example
  
  @override
  void dispose() {
    _resumeTimer?.cancel();
    _phoneCallSubscription?.cancel();
    _notificationSubscription?.cancel();
    _appStateSubscription?.cancel();
    _audioDeviceSubscription?.cancel();
    super.dispose();
  }
}
