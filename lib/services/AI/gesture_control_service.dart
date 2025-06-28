import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GestureControlService extends ChangeNotifier {
  // Gesture detection state
  bool _isGestureEnabled = true;
  bool _isShakeDetectionEnabled = true;
  bool _isSwipeControlEnabled = true;
  bool _isTapControlEnabled = true;
  
  // Gesture callbacks
  VoidCallback? _onShakeDetected;
  VoidCallback? _onDoubleTap;
  VoidCallback? _onLongPress;
  Function(SwipeDirection)? _onSwipe;
  Function(double)? _onVolumeGesture;
  Function(double)? _onSpeedGesture;
  VoidCallback? _onClearGesture;
  
  // Shake detection
  Timer? _shakeTimer;
  List<double> _accelerometerValues = [];
  double _shakeThreshold = 15.0;
  
  // Swipe detection
  double _swipeThreshold = 100.0;
  double _swipeVelocityThreshold = 1000.0;
  
  // Volume and speed control
  double _currentVolume = 0.8;
  double _currentSpeed = 0.5;
  
  // Getters
  bool get isGestureEnabled => _isGestureEnabled;
  bool get isShakeDetectionEnabled => _isShakeDetectionEnabled;
  bool get isSwipeControlEnabled => _isSwipeControlEnabled;
  bool get isTapControlEnabled => _isTapControlEnabled;
  double get currentVolume => _currentVolume;
  double get currentSpeed => _currentSpeed;
  
  void initialize({
    VoidCallback? onShakeDetected,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
    Function(SwipeDirection)? onSwipe,
    Function(double)? onVolumeGesture,
    Function(double)? onSpeedGesture,
    VoidCallback? onClearGesture,
  }) {
    _onShakeDetected = onShakeDetected;
    _onDoubleTap = onDoubleTap;
    _onLongPress = onLongPress;
    _onSwipe = onSwipe;
    _onVolumeGesture = onVolumeGesture;
    _onSpeedGesture = onSpeedGesture;
    _onClearGesture = onClearGesture;
    
    _startShakeDetection();
  }
  
  void _startShakeDetection() {
    if (!_isShakeDetectionEnabled) return;
    
    // Simulate accelerometer data for shake detection
    _shakeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isShakeDetectionEnabled) {
        _simulateAccelerometerData();
      }
    });
  }
  
  void _simulateAccelerometerData() {
    // In a real app, you'd use sensors_plus package to get real accelerometer data
    // For demo purposes, we'll simulate occasional shake events
    final random = Random();
    final x = (random.nextDouble() - 0.5) * 2;
    final y = (random.nextDouble() - 0.5) * 2;
    final z = (random.nextDouble() - 0.5) * 2;
    
    _accelerometerValues.add(sqrt(x * x + y * y + z * z));
    
    if (_accelerometerValues.length > 10) {
      _accelerometerValues.removeAt(0);
    }
    
    // Check for shake pattern
    if (_accelerometerValues.length >= 5) {
      final avgAcceleration = _accelerometerValues.reduce((a, b) => a + b) / _accelerometerValues.length;
      
      if (avgAcceleration > _shakeThreshold) {
        _handleShakeDetected();
      }
    }
  }
  
  void _handleShakeDetected() {
    if (kDebugMode) {
      print("Shake detected!");
    }
    
    _onShakeDetected?.call();
    
    // Provide haptic feedback
    _triggerHapticFeedback(HapticType.medium);
    
    // Clear accelerometer values to prevent multiple triggers
    _accelerometerValues.clear();
  }
  
  // Handle swipe gestures
  void handleSwipe(SwipeDirection direction, double velocity) {
    if (!_isSwipeControlEnabled) return;
    
    if (kDebugMode) {
      print("Swipe detected: $direction with velocity: $velocity");
    }
    
    switch (direction) {
      case SwipeDirection.up:
        _handleVolumeUp();
        break;
      case SwipeDirection.down:
        _handleVolumeDown();
        break;
      case SwipeDirection.left:
        _handleSpeedDown();
        break;
      case SwipeDirection.right:
        _handleSpeedUp();
        break;
    }
    
    _onSwipe?.call(direction);
    _triggerHapticFeedback(HapticType.light);
  }
  
  void _handleVolumeUp() {
    _currentVolume = (_currentVolume + 0.1).clamp(0.0, 1.0);
    _onVolumeGesture?.call(_currentVolume);
    
    if (kDebugMode) {
      print("Volume increased to: ${(_currentVolume * 100).round()}%");
    }
  }
  
  void _handleVolumeDown() {
    _currentVolume = (_currentVolume - 0.1).clamp(0.0, 1.0);
    _onVolumeGesture?.call(_currentVolume);
    
    if (kDebugMode) {
      print("Volume decreased to: ${(_currentVolume * 100).round()}%");
    }
  }
  
  void _handleSpeedUp() {
    _currentSpeed = (_currentSpeed + 0.1).clamp(0.1, 2.0);
    _onSpeedGesture?.call(_currentSpeed);
    
    if (kDebugMode) {
      print("Speed increased to: ${(_currentSpeed * 100).round()}%");
    }
  }
  
  void _handleSpeedDown() {
    _currentSpeed = (_currentSpeed - 0.1).clamp(0.1, 2.0);
    _onSpeedGesture?.call(_currentSpeed);
    
    if (kDebugMode) {
      print("Speed decreased to: ${(_currentSpeed * 100).round()}%");
    }
  }
  
  // Handle tap gestures
  void handleDoubleTap() {
    if (!_isTapControlEnabled) return;
    
    if (kDebugMode) {
      print("Double tap detected");
    }
    
    _onDoubleTap?.call();
    _triggerHapticFeedback(HapticType.light);
  }
  
  void handleLongPress() {
    if (!_isTapControlEnabled) return;
    
    if (kDebugMode) {
      print("Long press detected");
    }
    
    _onLongPress?.call();
    _triggerHapticFeedback(HapticType.heavy);
  }
  
  // Handle pinch gestures for zoom
  void handlePinch(double scale) {
    if (!_isGestureEnabled) return;
    
    if (kDebugMode) {
      print("Pinch gesture detected with scale: $scale");
    }
    
    // Could be used for zooming property images or adjusting UI scale
    _triggerHapticFeedback(HapticType.light);
  }
  
  // Shake to clear functionality
  void simulateShake() {
    if (kDebugMode) {
      print("Simulating shake gesture");
    }
    
    _onClearGesture?.call();
    _triggerHapticFeedback(HapticType.heavy);
  }
  
  // Haptic feedback
  void _triggerHapticFeedback(HapticType type) {
    try {
      switch (type) {
        case HapticType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Haptic feedback error: $e");
      }
    }
  }
  
  // Enable/disable gesture controls
  void enableGestures() {
    _isGestureEnabled = true;
    notifyListeners();
  }
  
  void disableGestures() {
    _isGestureEnabled = false;
    notifyListeners();
  }
  
  void enableShakeDetection() {
    _isShakeDetectionEnabled = true;
    _startShakeDetection();
    notifyListeners();
  }
  
  void disableShakeDetection() {
    _isShakeDetectionEnabled = false;
    _shakeTimer?.cancel();
    notifyListeners();
  }
  
  void enableSwipeControl() {
    _isSwipeControlEnabled = true;
    notifyListeners();
  }
  
  void disableSwipeControl() {
    _isSwipeControlEnabled = false;
    notifyListeners();
  }
  
  void enableTapControl() {
    _isTapControlEnabled = true;
    notifyListeners();
  }
  
  void disableTapControl() {
    _isTapControlEnabled = false;
    notifyListeners();
  }
  
  // Sensitivity settings
  void setShakeThreshold(double threshold) {
    _shakeThreshold = threshold.clamp(5.0, 30.0);
    notifyListeners();
  }
  
  void setSwipeThreshold(double threshold) {
    _swipeThreshold = threshold.clamp(50.0, 200.0);
    notifyListeners();
  }
  
  // Get gesture help text
  String getGestureHelp() {
    final help = StringBuffer();
    help.writeln('الإيماءات المتاحة:');
    help.writeln();
    
    if (_isSwipeControlEnabled) {
      help.writeln('• اسحب لأعلى: زيادة الصوت');
      help.writeln('• اسحب لأسفل: تقليل الصوت');
      help.writeln('• اسحب يميناً: زيادة السرعة');
      help.writeln('• اسحب يساراً: تقليل السرعة');
      help.writeln();
    }
    
    if (_isTapControlEnabled) {
      help.writeln('• نقرة مزدوجة: تكرار آخر رد');
      help.writeln('• ضغطة طويلة: إيقاف/تشغيل');
      help.writeln();
    }
    
    if (_isShakeDetectionEnabled) {
      help.writeln('• هز الجهاز: مسح المحادثة');
      help.writeln();
    }
    
    return help.toString();
  }
  
  // Get current gesture settings
  Map<String, dynamic> getGestureSettings() {
    return {
      'gesturesEnabled': _isGestureEnabled,
      'shakeDetectionEnabled': _isShakeDetectionEnabled,
      'swipeControlEnabled': _isSwipeControlEnabled,
      'tapControlEnabled': _isTapControlEnabled,
      'shakeThreshold': _shakeThreshold,
      'swipeThreshold': _swipeThreshold,
      'currentVolume': _currentVolume,
      'currentSpeed': _currentSpeed,
    };
  }
  
  @override
  void dispose() {
    _shakeTimer?.cancel();
    super.dispose();
  }
}

enum SwipeDirection {
  up,
  down,
  left,
  right,
}

enum HapticType {
  light,
  medium,
  heavy,
  selection,
}
