import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../screens/AI/voice_chat_screen.dart';
import '../AI/voice_service.dart';
import '../AI/ai_service.dart';
import '../../models/chat_message_model.dart';
import '../../models/property_model.dart';
import '../../screens/AI/live_voice_chat_screen.dart';
import '../../screens/AI/conversation_history_screen.dart';
import '../../core/theme/app_theme.dart';
import '../api_key_service.dart';

/// Integration service that connects the graphic_eq button to the voice chat functionality
class VoiceChatIntegrationService {
  static VoiceChatIntegrationService? _instance;
  static VoiceChatIntegrationService get instance =>
      _instance ??= VoiceChatIntegrationService._();

  VoiceChatIntegrationService._();

  // Services
  VoiceService? _voiceService;
  AIService? _aiService;
  final ApiKeyService _apiKeyService = ApiKeyService.instance;

  /// Initialize the voice chat services
  Future<bool> initializeServices() async {
    try {
      _voiceService = VoiceService();
      _aiService = AIService();

      // Initialize voice service
      final voiceInitialized = await _voiceService!.initialize();
      if (!voiceInitialized) {
        if (kDebugMode) {
          print("Failed to initialize voice service");
        }
        return false;
      }

      // Initialize AI service with API key from ApiKeyService
      final apiKey = _apiKeyService.apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          print("No API key available. Please set up API key first.");
        }
        return false;
      }

      final aiInitialized = await _aiService!.initialize(apiKey);
      if (!aiInitialized) {
        if (kDebugMode) {
          print("Failed to initialize AI service");
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing services: $e");
      }
      return false;
    }
  }

  /// Debug services status
  void _debugServicesStatus() {
    if (kDebugMode) {
      print("=== Services Status Debug ===");
      print("API Key Available: ${_apiKeyService.hasValidApiKey}");
      print("API Key Length: ${_apiKeyService.apiKey?.length ?? 0}");
      print(
        "Voice Service Initialized: ${_voiceService?.isInitialized ?? false}",
      );
      print(
        "Voice Service Status: ${_voiceService?.voiceStatus.state ?? 'Unknown'}",
      );
      print(
        "Voice Service Message: ${_voiceService?.voiceStatus.message ?? 'Unknown'}",
      );
      print("AI Service Has Properties: ${_aiService?.hasProperties ?? false}");
      print("AI Service Initialized: ${_aiService?.isInitialized ?? false}");
      print("Properties Count: ${_aiService?.properties.length ?? 0}");
      print("=============================");
    }
  }

  /// The main voice mode toggle method that replicates your existing functionality
  Future<void> toggleVoiceMode(
    BuildContext context, {
    List<dynamic>? properties,
    dynamic property,
  }) async {
    if (kDebugMode) {
      print("=== VOICE BUTTON PRESSED ===");
    }

    // Check if API key is available
    if (!_apiKeyService.hasValidApiKey) {
      if (kDebugMode) {
        print("No valid API key available");
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("يرجى إعداد مفتاح API أولاً من الإعدادات"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Initialize services if not already done
    if (_voiceService == null || _aiService == null) {
      final initialized = await initializeServices();
      if (!initialized) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("فشل في تهيئة الخدمات. يرجى إعادة المحاولة."),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    // Load properties into AI service if provided
    if (properties != null && properties.isNotEmpty) {
      // Load the provided properties list into AI service
      _aiService?.updateProperties(properties.cast<Property>());
      if (kDebugMode) {
        print("Loaded ${properties.length} properties from global chat drawer");
      }
    } else if (property != null) {
      // Load single property into AI service
      _aiService?.updateProperties([property as Property]);
      if (kDebugMode) {
        print("Loaded single property from property chat drawer");
      }
    }

    _debugServicesStatus();

    // Check if AI service has properties (either loaded or passed)
    bool hasPropertiesData =
        (_aiService?.hasProperties ?? false) ||
        (properties != null && properties.isNotEmpty) ||
        (property != null);

    if (!hasPropertiesData) {
      if (kDebugMode) {
        print("No properties available");
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("يرجى تحميل بيانات العقارات أولاً"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Check if voice service is initialized
    if (!(_voiceService?.isInitialized ?? false)) {
      if (kDebugMode) {
        print("Voice service not initialized");
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("خدمة الصوت غير متاحة. يرجى إعادة تشغيل التطبيق."),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Navigate to live voice chat screen
    if (!context.mounted) return;

    final result = await Navigator.of(context).push<List<ChatMessage>>(
      MaterialPageRoute(
        builder:
            (context) => LiveVoiceChatScreen(
              voiceService: _voiceService!,
              aiService: _aiService!,
            ),
      ),
    );

    // Handle the result from live chat
    if (result != null && result.isNotEmpty && context.mounted) {
      // Show conversation history screen
      final action = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder:
              (context) => ConversationHistoryScreen(
                conversation: result,
                title:
                    "محادثة صوتية - ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
              ),
        ),
      );

      // Handle actions from conversation history
      if (action == 'new_chat') {
        // Could trigger a callback to clear current messages
        if (kDebugMode) {
          print("User requested new chat");
        }
      } else if (action == 'continue_chat') {
        // Could trigger a callback to add conversation to current messages
        if (kDebugMode) {
          print("User requested to continue chat");
        }
      }
    }
  }

  /// Navigate directly to the voice chat screen
  static void navigateToVoiceChatScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoiceChatScreen()),
    );
  }

  /// Quick access method for graphic_eq button integration
  static Future<void> handleGraphicEqButtonPress(
    BuildContext context, {
    List<dynamic>? properties,
    dynamic property,
  }) async {
    await VoiceChatIntegrationService.instance.toggleVoiceMode(
      context,
      properties: properties,
      property: property,
    );
  }

  /// Get services status
  bool get isInitialized =>
      (_voiceService?.isInitialized ?? false) &&
      (_aiService?.isInitialized ?? false);

  bool get hasProperties => _aiService?.hasProperties ?? false;

  /// Dispose services
  void dispose() {
    _voiceService = null;
    _aiService = null;
  }
}

/// Widget wrapper for easy voice chat integration
class VoiceChatWrapper extends StatefulWidget {
  final Widget child;
  final bool autoInitialize;

  const VoiceChatWrapper({
    Key? key,
    required this.child,
    this.autoInitialize = true,
  }) : super(key: key);

  @override
  State<VoiceChatWrapper> createState() => _VoiceChatWrapperState();
}

class _VoiceChatWrapperState extends State<VoiceChatWrapper> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoInitialize) {
      _initializeServices();
    }
  }

  Future<void> _initializeServices() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    await VoiceChatIntegrationService.instance.initializeServices();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    VoiceChatIntegrationService.instance.dispose();
    super.dispose();
  }
}
