import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AccessibilityService extends ChangeNotifier {
  // Accessibility settings
  bool _isHighContrastEnabled = false;
  bool _isLargeFontEnabled = false;
  bool _isScreenReaderEnabled = false;
  bool _isVisualCaptionsEnabled = false;
  bool _isHapticFeedbackEnabled = true;
  bool _isVoiceNavigationEnabled = false;
  
  // Caption settings
  double _captionFontSize = 16.0;
  String _captionPosition = 'bottom';
  bool _showSpeakerLabels = true;
  bool _showTimestamps = false;
  
  // Screen reader
  String _currentScreenReaderText = '';
  Timer? _screenReaderTimer;
  
  // Visual indicators
  bool _showVoiceActivityIndicator = true;
  bool _showConnectionStatus = true;
  bool _showVolumeIndicator = true;
  
  // Getters
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get isLargeFontEnabled => _isLargeFontEnabled;
  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  bool get isVisualCaptionsEnabled => _isVisualCaptionsEnabled;
  bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;
  bool get isVoiceNavigationEnabled => _isVoiceNavigationEnabled;
  double get captionFontSize => _captionFontSize;
  String get captionPosition => _captionPosition;
  bool get showSpeakerLabels => _showSpeakerLabels;
  bool get showTimestamps => _showTimestamps;
  String get currentScreenReaderText => _currentScreenReaderText;
  bool get showVoiceActivityIndicator => _showVoiceActivityIndicator;
  bool get showConnectionStatus => _showConnectionStatus;
  bool get showVolumeIndicator => _showVolumeIndicator;
  
  void initialize() {
    _loadAccessibilitySettings();
    _setupScreenReader();
  }
  
  void _loadAccessibilitySettings() {
    // In a real app, load from SharedPreferences
    // For now, we'll use default values
    
    // Check system accessibility settings
    _checkSystemAccessibilitySettings();
  }
  
  void _checkSystemAccessibilitySettings() {
    // In a real app, you'd check system accessibility settings
    // For demo purposes, we'll simulate some settings
    
    if (kDebugMode) {
      print("Checking system accessibility settings...");
    }
  }
  
  void _setupScreenReader() {
    if (_isScreenReaderEnabled) {
      _startScreenReaderAnnouncements();
    }
  }
  
  void _startScreenReaderAnnouncements() {
    _screenReaderTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isScreenReaderEnabled && _currentScreenReaderText.isNotEmpty) {
        _announceToScreenReader(_currentScreenReaderText);
      }
    });
  }
  
  // High contrast mode
  void enableHighContrast() {
    _isHighContrastEnabled = true;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم تفعيل الوضع عالي التباين");
    }
  }
  
  void disableHighContrast() {
    _isHighContrastEnabled = false;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم إلغاء الوضع عالي التباين");
    }
  }
  
  // Large font mode
  void enableLargeFont() {
    _isLargeFontEnabled = true;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم تفعيل الخط الكبير");
    }
  }
  
  void disableLargeFont() {
    _isLargeFontEnabled = false;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم إلغاء الخط الكبير");
    }
  }
  
  // Screen reader
  void enableScreenReader() {
    _isScreenReaderEnabled = true;
    _setupScreenReader();
    notifyListeners();
    
    announceToScreenReader("تم تفعيل قارئ الشاشة");
  }
  
  void disableScreenReader() {
    _isScreenReaderEnabled = false;
    _screenReaderTimer?.cancel();
    notifyListeners();
  }
  
  void announceToScreenReader(String text) {
    if (!_isScreenReaderEnabled) return;
    
    _currentScreenReaderText = text;
    _announceToScreenReader(text);
    notifyListeners();
  }
  
  void _announceToScreenReader(String text) {
    if (kDebugMode) {
      print("Screen Reader: $text");
    }
    
    // In a real app, you'd use platform-specific TTS or accessibility APIs
    // For now, we'll just log the announcement
  }
  
  // Visual captions
  void enableVisualCaptions() {
    _isVisualCaptionsEnabled = true;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم تفعيل التسميات التوضيحية المرئية");
    }
  }
  
  void disableVisualCaptions() {
    _isVisualCaptionsEnabled = false;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم إلغاء التسميات التوضيحية المرئية");
    }
  }
  
  void setCaptionFontSize(double size) {
    _captionFontSize = size.clamp(12.0, 24.0);
    notifyListeners();
  }
  
  void setCaptionPosition(String position) {
    if (['top', 'bottom', 'center'].contains(position)) {
      _captionPosition = position;
      notifyListeners();
    }
  }
  
  void toggleSpeakerLabels() {
    _showSpeakerLabels = !_showSpeakerLabels;
    notifyListeners();
  }
  
  void toggleTimestamps() {
    _showTimestamps = !_showTimestamps;
    notifyListeners();
  }
  
  // Haptic feedback
  void enableHapticFeedback() {
    _isHapticFeedbackEnabled = true;
    notifyListeners();
    
    // Test haptic feedback
    _triggerHapticFeedback();
  }
  
  void disableHapticFeedback() {
    _isHapticFeedbackEnabled = false;
    notifyListeners();
  }
  
  void _triggerHapticFeedback() {
    if (_isHapticFeedbackEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (e) {
        if (kDebugMode) {
          print("Haptic feedback error: $e");
        }
      }
    }
  }
  
  // Voice navigation
  void enableVoiceNavigation() {
    _isVoiceNavigationEnabled = true;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم تفعيل التنقل الصوتي");
    }
  }
  
  void disableVoiceNavigation() {
    _isVoiceNavigationEnabled = false;
    notifyListeners();
    
    if (_isScreenReaderEnabled) {
      announceToScreenReader("تم إلغاء التنقل الصوتي");
    }
  }
  
  // Visual indicators
  void toggleVoiceActivityIndicator() {
    _showVoiceActivityIndicator = !_showVoiceActivityIndicator;
    notifyListeners();
  }
  
  void toggleConnectionStatus() {
    _showConnectionStatus = !_showConnectionStatus;
    notifyListeners();
  }
  
  void toggleVolumeIndicator() {
    _showVolumeIndicator = !_showVolumeIndicator;
    notifyListeners();
  }
  
  // Get accessibility description for UI elements
  String getAccessibilityLabel(String elementType, {Map<String, dynamic>? context}) {
    switch (elementType) {
      case 'voice_button':
        final isListening = context?['isListening'] ?? false;
        return isListening ? "إيقاف الاستماع" : "بدء الاستماع";
        
      case 'volume_control':
        final volume = context?['volume'] ?? 0.5;
        return "مستوى الصوت ${(volume * 100).round()} بالمئة";
        
      case 'speed_control':
        final speed = context?['speed'] ?? 0.5;
        return "سرعة الكلام ${(speed * 100).round()} بالمئة";
        
      case 'property_card':
        final title = context?['title'] ?? 'عقار';
        final price = context?['price'] ?? '';
        return "$title، السعر $price";
        
      case 'chat_message':
        final isUser = context?['isUser'] ?? false;
        final text = context?['text'] ?? '';
        final speaker = isUser ? "أنت" : "المساعد الذكي";
        return "$speaker يقول: $text";
        
      default:
        return elementType;
    }
  }
  
  // Get voice navigation commands
  List<String> getVoiceNavigationCommands() {
    return [
      "اذهب إلى الرئيسية",
      "افتح الإعدادات",
      "اعرض العقارات",
      "ابدأ محادثة جديدة",
      "اعرض المفضلة",
      "تغيير مستوى الصوت",
      "تغيير سرعة الكلام",
      "تفعيل الوضع عالي التباين",
      "تفعيل الخط الكبير",
    ];
  }
  
  // Process voice navigation command
  bool processVoiceNavigationCommand(String command) {
    if (!_isVoiceNavigationEnabled) return false;
    
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('تباين')) {
      if (lowerCommand.contains('تفعيل')) {
        enableHighContrast();
      } else if (lowerCommand.contains('إلغاء')) {
        disableHighContrast();
      }
      return true;
    }
    
    if (lowerCommand.contains('خط كبير')) {
      if (lowerCommand.contains('تفعيل')) {
        enableLargeFont();
      } else if (lowerCommand.contains('إلغاء')) {
        disableLargeFont();
      }
      return true;
    }
    
    if (lowerCommand.contains('تسميات') || lowerCommand.contains('ترجمة')) {
      if (lowerCommand.contains('تفعيل')) {
        enableVisualCaptions();
      } else if (lowerCommand.contains('إلغاء')) {
        disableVisualCaptions();
      }
      return true;
    }
    
    return false;
  }
  
  // Get accessibility settings summary
  Map<String, dynamic> getAccessibilitySettings() {
    return {
      'highContrast': _isHighContrastEnabled,
      'largeFont': _isLargeFontEnabled,
      'screenReader': _isScreenReaderEnabled,
      'visualCaptions': _isVisualCaptionsEnabled,
      'hapticFeedback': _isHapticFeedbackEnabled,
      'voiceNavigation': _isVoiceNavigationEnabled,
      'captionFontSize': _captionFontSize,
      'captionPosition': _captionPosition,
      'showSpeakerLabels': _showSpeakerLabels,
      'showTimestamps': _showTimestamps,
      'showVoiceActivityIndicator': _showVoiceActivityIndicator,
      'showConnectionStatus': _showConnectionStatus,
      'showVolumeIndicator': _showVolumeIndicator,
    };
  }
  
  @override
  void dispose() {
    _screenReaderTimer?.cancel();
    super.dispose();
  }
}
