import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceSettingsService extends ChangeNotifier {
  static const String _speechRateKey = 'speech_rate';
  static const String _pitchKey = 'pitch';
  static const String _volumeKey = 'volume';
  static const String _voiceTypeKey = 'voice_type';
  static const String _languageKey = 'language';
  static const String _autoVolumeKey = 'auto_volume';
  static const String _echoCancellationKey = 'echo_cancellation';
  static const String _noiseSuppressionKey = 'noise_suppression';

  // Voice settings
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 0.8;
  VoiceType _voiceType = VoiceType.neutral;
  String _language = 'ar-SA';
  bool _autoVolumeAdjustment = true;
  bool _echoCancellation = true;
  bool _noiseSuppression = true;

  // Audio monitoring
  double _ambientNoiseLevel = 0.0;
  bool _isPhoneCallActive = false;
  bool _hasNotificationInterruption = false;

  // Getters
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  VoiceType get voiceType => _voiceType;
  String get language => _language;
  bool get autoVolumeAdjustment => _autoVolumeAdjustment;
  bool get echoCancellation => _echoCancellation;
  bool get noiseSuppression => _noiseSuppression;
  double get ambientNoiseLevel => _ambientNoiseLevel;
  bool get isPhoneCallActive => _isPhoneCallActive;
  bool get hasNotificationInterruption => _hasNotificationInterruption;

  Future<void> initialize() async {
    await _loadSettings();
    _startAudioMonitoring();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
      _pitch = prefs.getDouble(_pitchKey) ?? 1.0;
      _volume = prefs.getDouble(_volumeKey) ?? 0.8;
      _voiceType = VoiceType.values[prefs.getInt(_voiceTypeKey) ?? 0];
      _language = prefs.getString(_languageKey) ?? 'ar-SA';
      _autoVolumeAdjustment = prefs.getBool(_autoVolumeKey) ?? true;
      _echoCancellation = prefs.getBool(_echoCancellationKey) ?? true;
      _noiseSuppression = prefs.getBool(_noiseSuppressionKey) ?? true;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading voice settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble(_speechRateKey, _speechRate);
      await prefs.setDouble(_pitchKey, _pitch);
      await prefs.setDouble(_volumeKey, _volume);
      await prefs.setInt(_voiceTypeKey, _voiceType.index);
      await prefs.setString(_languageKey, _language);
      await prefs.setBool(_autoVolumeKey, _autoVolumeAdjustment);
      await prefs.setBool(_echoCancellationKey, _echoCancellation);
      await prefs.setBool(_noiseSuppressionKey, _noiseSuppression);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving voice settings: $e');
      }
    }
  }

  // Speech rate control (0.1 to 2.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 2.0);
    await _saveSettings();
    notifyListeners();
  }

  // Pitch control (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _saveSettings();
    notifyListeners();
  }

  // Volume control (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _saveSettings();
    notifyListeners();
  }

  // Voice type selection
  Future<void> setVoiceType(VoiceType type) async {
    _voiceType = type;
    await _saveSettings();
    notifyListeners();
  }

  // Language selection
  Future<void> setLanguage(String language) async {
    _language = language;
    await _saveSettings();
    notifyListeners();
  }

  // Auto volume adjustment
  Future<void> setAutoVolumeAdjustment(bool enabled) async {
    _autoVolumeAdjustment = enabled;
    await _saveSettings();
    notifyListeners();
  }

  // Echo cancellation
  Future<void> setEchoCancellation(bool enabled) async {
    _echoCancellation = enabled;
    await _saveSettings();
    notifyListeners();
  }

  // Noise suppression
  Future<void> setNoiseSuppression(bool enabled) async {
    _noiseSuppression = enabled;
    await _saveSettings();
    notifyListeners();
  }

  // Get optimal volume based on ambient noise
  double getOptimalVolume() {
    if (!_autoVolumeAdjustment) return _volume;

    // Adjust volume based on ambient noise level
    double adjustedVolume = _volume;

    if (_ambientNoiseLevel > 0.7) {
      adjustedVolume = (_volume * 1.3).clamp(0.0, 1.0);
    } else if (_ambientNoiseLevel > 0.4) {
      adjustedVolume = (_volume * 1.1).clamp(0.0, 1.0);
    } else if (_ambientNoiseLevel < 0.1) {
      adjustedVolume = (_volume * 0.8).clamp(0.0, 1.0);
    }

    return adjustedVolume;
  }

  // Get speech rate with emotion adjustment
  double getEmotionalSpeechRate(EmotionType emotion) {
    double baseRate = _speechRate;

    switch (emotion) {
      case EmotionType.excited:
        return (baseRate * 1.2).clamp(0.1, 2.0);
      case EmotionType.calm:
        return (baseRate * 0.9).clamp(0.1, 2.0);
      case EmotionType.urgent:
        return (baseRate * 1.3).clamp(0.1, 2.0);
      case EmotionType.sad:
        return (baseRate * 0.8).clamp(0.1, 2.0);
      case EmotionType.neutral:
        return baseRate;
    }
  }

  // Get pitch with emotion adjustment
  double getEmotionalPitch(EmotionType emotion) {
    double basePitch = _pitch;

    switch (emotion) {
      case EmotionType.excited:
        return (basePitch * 1.1).clamp(0.5, 2.0);
      case EmotionType.calm:
        return (basePitch * 0.95).clamp(0.5, 2.0);
      case EmotionType.urgent:
        return (basePitch * 1.15).clamp(0.5, 2.0);
      case EmotionType.sad:
        return (basePitch * 0.9).clamp(0.5, 2.0);
      case EmotionType.neutral:
        return basePitch;
    }
  }

  void _startAudioMonitoring() {
    // Simulate ambient noise monitoring
    // In a real app, you'd use audio recording permissions to monitor ambient noise
    _simulateAmbientNoise();

    // Monitor phone call state
    _monitorPhoneCallState();

    // Monitor notification interruptions
    _monitorNotificationInterruptions();
  }

  void _simulateAmbientNoise() {
    // Simulate changing ambient noise levels
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _ambientNoiseLevel =
            0.2 + (DateTime.now().millisecondsSinceEpoch % 1000) / 1000 * 0.6;
        notifyListeners();
        _simulateAmbientNoise();
      }
    });
  }

  void _monitorPhoneCallState() {
    // In a real app, you'd use platform channels to monitor phone call state
    // For now, we'll simulate occasional phone call interruptions
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _isPhoneCallActive = false; // Reset after simulation
        notifyListeners();
        _monitorPhoneCallState();
      }
    });
  }

  void _monitorNotificationInterruptions() {
    // Monitor for notification interruptions
    // In a real app, you'd listen to system notification events
  }

  // Simulate phone call interruption
  void simulatePhoneCallInterruption() {
    _isPhoneCallActive = true;
    notifyListeners();

    // Auto-resume after call ends (simulated)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _isPhoneCallActive = false;
        notifyListeners();
      }
    });
  }

  // Simulate notification interruption
  void simulateNotificationInterruption() {
    _hasNotificationInterruption = true;
    notifyListeners();

    // Clear interruption flag after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hasNotificationInterruption = false;
        notifyListeners();
      }
    });
  }

  // Get voice settings for TTS engine
  Map<String, dynamic> getTTSSettings() {
    return {
      'speechRate': getOptimalSpeechRate(),
      'pitch': _pitch,
      'volume': getOptimalVolume(),
      'language': _language,
      'voiceType': _voiceType.name,
    };
  }

  double getOptimalSpeechRate() {
    // Adjust speech rate based on ambient noise
    if (_ambientNoiseLevel > 0.6) {
      return (_speechRate * 0.9).clamp(
        0.1,
        2.0,
      ); // Slower in noisy environments
    }
    return _speechRate;
  }

  bool get mounted => true; // Simplified for this example
}

enum VoiceType { neutral, friendly, professional, calm, energetic }

enum EmotionType { neutral, excited, calm, urgent, sad }

extension VoiceTypeExtension on VoiceType {
  String get name {
    switch (this) {
      case VoiceType.neutral:
        return 'Neutral';
      case VoiceType.friendly:
        return 'Friendly';
      case VoiceType.professional:
        return 'Professional';
      case VoiceType.calm:
        return 'Calm';
      case VoiceType.energetic:
        return 'Energetic';
    }
  }

  String get description {
    switch (this) {
      case VoiceType.neutral:
        return 'Standard voice tone';
      case VoiceType.friendly:
        return 'Warm and welcoming';
      case VoiceType.professional:
        return 'Business-like and formal';
      case VoiceType.calm:
        return 'Soothing and relaxed';
      case VoiceType.energetic:
        return 'Upbeat and enthusiastic';
    }
  }
}
