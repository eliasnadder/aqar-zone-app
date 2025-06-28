import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/chat_message_model.dart';
import '../../core/theme/app_theme.dart';
import 'voice_settings_service.dart';
import 'auto_pause_service.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  VoiceStatus _voiceStatus = const VoiceStatus(
    state: VoiceState.idle,
    message: "اضغط للبدء",
  );

  bool _isContinuousMode = false;
  bool _isInitialized = false;
  StreamController<String>? _speechController;
  Timer? _silenceTimer;

  // Enhanced services
  VoiceSettingsService? _voiceSettings;
  AutoPauseService? _autoPauseService;
  bool _isPausedBySystem = false;

  // Getters
  VoiceStatus get voiceStatus => _voiceStatus;
  bool get isContinuousMode => _isContinuousMode;
  bool get isInitialized => _isInitialized;
  bool get isListening => _voiceStatus.state == VoiceState.listening;
  bool get isSpeaking => _voiceStatus.state == VoiceState.speaking;
  bool get isProcessing => _voiceStatus.state == VoiceState.processing;

  // Stream for speech results
  Stream<String> get speechStream =>
      _speechController?.stream ?? const Stream.empty();

  Future<bool> initialize({
    VoiceSettingsService? voiceSettings,
    AutoPauseService? autoPauseService,
  }) async {
    try {
      if (kDebugMode) {
        print("Initializing voice service...");
      }

      // Store enhanced services
      _voiceSettings = voiceSettings;
      _autoPauseService = autoPauseService;

      _isInitialized = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
      );

      if (kDebugMode) {
        print("Speech to text initialized: $_isInitialized");
      }

      if (_isInitialized) {
        await _initializeTts();
        _speechController = StreamController<String>.broadcast();
        _setupAutoPauseIntegration();
        _updateStatus(VoiceState.idle, "جاهز للاستخدام");
      } else {
        _updateStatus(VoiceState.error, "فشل في تهيئة خدمة التعرف على الصوت");
      }

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing voice service: $e");
      }
      _updateStatus(VoiceState.error, "خطأ في تهيئة الخدمة");
      return false;
    }
  }

  Future<void> _initializeTts() async {
    // Use voice settings if available, otherwise use defaults
    final settings =
        _voiceSettings?.getTTSSettings() ??
        {
          'speechRate': 0.35,
          'pitch': 0.85,
          'volume': 0.85,
          'language': AppConstants.arabicLocale,
        };

    await _flutterTts.setLanguage(settings['language']);
    await _flutterTts.setSpeechRate(settings['speechRate']);
    await _flutterTts.setPitch(settings['pitch']);
    await _flutterTts.setVolume(settings['volume']);

    // Basic settings for natural speech
    await _flutterTts.awaitSpeakCompletion(true);

    _flutterTts.setCompletionHandler(() {
      _updateStatus(VoiceState.idle, "انتهى التحدث");
      if (_isContinuousMode && !_isPausedBySystem) {
        _startListening();
      }
    });

    _flutterTts.setStartHandler(() {
      _updateStatus(VoiceState.speaking, "أتحدث...");
    });

    _flutterTts.setErrorHandler((message) {
      if (kDebugMode) {
        print("TTS Error: $message");
      }
      _updateStatus(VoiceState.error, "خطأ في التحدث: $message");
    });
  }

  void _setupAutoPauseIntegration() {
    if (_autoPauseService != null) {
      // Initialize auto-pause service with callbacks
      _autoPauseService!.initialize(
        onPauseRequested: _handleSystemPause,
        onResumeRequested: _handleSystemResume,
      );
    }
  }

  void _handleSystemPause() {
    if (kDebugMode) {
      print("System pause requested");
    }

    _isPausedBySystem = true;

    if (isListening) {
      _stopListening();
    }

    if (isSpeaking) {
      _stopSpeaking();
    }

    _updateStatus(VoiceState.idle, "متوقف مؤقتاً");
    notifyListeners();
  }

  void _handleSystemResume() {
    if (kDebugMode) {
      print("System resume requested");
    }

    _isPausedBySystem = false;

    if (_isContinuousMode) {
      _startListening();
    }

    _updateStatus(VoiceState.idle, "تم الاستئناف");
    notifyListeners();
  }

  void toggleContinuousMode() {
    if (kDebugMode) {
      print("toggleContinuousMode called. Initialized: $_isInitialized");
    }

    if (!_isInitialized) {
      if (kDebugMode) {
        print("Voice service not initialized!");
      }
      _updateStatus(VoiceState.error, "الخدمة غير مهيأة");
      return;
    }

    _isContinuousMode = !_isContinuousMode;
    if (kDebugMode) {
      print("Continuous mode toggled to: $_isContinuousMode");
    }

    if (_isContinuousMode) {
      if (kDebugMode) {
        print("Starting continuous mode...");
      }
      _startContinuousMode();
    } else {
      if (kDebugMode) {
        print("Stopping continuous mode...");
      }
      _stopContinuousMode();
    }

    notifyListeners();
  }

  void _startContinuousMode() {
    _updateStatus(VoiceState.idle, "بدء الوضع المستمر...");
    // Start listening immediately when continuous mode is enabled
    _startListening();
  }

  void _stopContinuousMode() {
    _stopListening();
    _stopSpeaking();
    _updateStatus(VoiceState.idle, "تم إيقاف الوضع المستمر");
  }

  Future<void> startListening() async {
    if (!_isInitialized || isListening) return;

    await _stopSpeaking();
    _startListening();
  }

  void _startListening() async {
    if (kDebugMode) {
      print(
        "_startListening called. Initialized: $_isInitialized, isListening: $isListening",
      );
    }

    if (!_isInitialized || isListening) {
      if (kDebugMode) {
        print(
          "Cannot start listening. Initialized: $_isInitialized, isListening: $isListening",
        );
      }
      return;
    }

    try {
      if (kDebugMode) {
        print("Starting speech recognition...");
      }
      _updateStatus(VoiceState.listening, AppConstants.listeningMessage);

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: AppConstants.listenTimeout,
        pauseFor: AppConstants.pauseTimeout,
        localeId: AppConstants.arabicLocale,
      );

      if (kDebugMode) {
        print("Speech recognition started successfully");
      }
      // Start silence timer
      _startSilenceTimer();
    } catch (e) {
      if (kDebugMode) {
        print("Error starting speech recognition: $e");
      }
      _updateStatus(VoiceState.error, "خطأ في بدء الاستماع");
    }
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 8), () {
      if (isListening) {
        _stopListening();
        if (_isContinuousMode) {
          _startListening();
        }
      }
    });
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    if (_voiceStatus.state == VoiceState.listening) {
      _updateStatus(VoiceState.idle, "توقف الاستماع");
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || text.trim().isEmpty) return;

    await _stopListening();
    _updateStatus(VoiceState.speaking, "أتحدث...");

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _updateStatus(VoiceState.error, "خطأ في التحدث: $e");
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  void _onSpeechResult(result) {
    _silenceTimer?.cancel();

    if (result.finalResult) {
      final recognizedWords = result.recognizedWords.trim();

      if (recognizedWords.isNotEmpty) {
        _speechController?.add(recognizedWords);
        _updateStatus(VoiceState.processing, AppConstants.processingMessage);
      }

      _stopListening();
    } else {
      // Partial result - restart silence timer
      _startSilenceTimer();
    }
  }

  void _onSpeechError(error) {
    _silenceTimer?.cancel();
    _updateStatus(
      VoiceState.error,
      "خطأ في التعرف على الصوت: ${error.errorMsg}",
    );

    if (_isContinuousMode) {
      // Retry after a short delay
      Timer(const Duration(seconds: 2), () {
        if (_isContinuousMode) {
          _startListening();
        }
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (kDebugMode) {
      print('Speech status: $status');
    }
  }

  void _updateStatus(VoiceState state, String message) {
    _voiceStatus = VoiceStatus(
      state: state,
      message: message,
      confidence: _voiceStatus.confidence,
      duration: _voiceStatus.duration,
    );
    notifyListeners();
  }

  void setProcessingState() {
    _updateStatus(VoiceState.processing, AppConstants.processingMessage);
  }

  void setIdleState([String? message]) {
    _updateStatus(VoiceState.idle, message ?? "جاهز");
  }

  void setErrorState(String message) {
    _updateStatus(VoiceState.error, message);
  }

  // Method to adjust speech rate dynamically
  Future<void> setSpeechRate(double rate) async {
    // Clamp rate between 0.1 (very slow) and 2.0 (very fast)
    final clampedRate = rate.clamp(0.1, 2.0);
    await _flutterTts.setSpeechRate(clampedRate);

    if (kDebugMode) {
      print("Speech rate set to: $clampedRate");
    }
  }

  // Method to adjust voice pitch
  Future<void> setPitch(double pitch) async {
    // Clamp pitch between 0.5 and 2.0
    final clampedPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(clampedPitch);

    if (kDebugMode) {
      print("Voice pitch set to: $clampedPitch");
    }
  }

  // Method to update TTS settings from voice settings service
  Future<void> updateTTSSettings() async {
    if (_voiceSettings != null && _isInitialized) {
      final settings = _voiceSettings!.getTTSSettings();

      await _flutterTts.setSpeechRate(settings['speechRate']);
      await _flutterTts.setPitch(settings['pitch']);
      await _flutterTts.setVolume(settings['volume']);
      await _flutterTts.setLanguage(settings['language']);

      if (kDebugMode) {
        print("TTS settings updated: $settings");
      }
    }
  }

  // Method to speak with emotion
  Future<void> speakWithEmotion(String text, EmotionType emotion) async {
    if (!_isInitialized || text.trim().isEmpty) return;

    await _stopListening();

    // Apply emotional adjustments if voice settings available
    if (_voiceSettings != null) {
      final emotionalRate = _voiceSettings!.getEmotionalSpeechRate(emotion);
      final emotionalPitch = _voiceSettings!.getEmotionalPitch(emotion);

      await _flutterTts.setSpeechRate(emotionalRate);
      await _flutterTts.setPitch(emotionalPitch);
    }

    _updateStatus(VoiceState.speaking, "أتحدث...");

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _updateStatus(VoiceState.error, "خطأ في التحدث: $e");
    } finally {
      // Reset to normal settings
      if (_voiceSettings != null) {
        await updateTTSSettings();
      }
    }
  }

  // Check if system pause is active
  bool get isPausedBySystem => _isPausedBySystem;

  // Manual system pause/resume controls
  void pauseBySystem() => _handleSystemPause();
  void resumeBySystem() => _handleSystemResume();

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speechController?.close();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }
}
