import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/chat_message_model.dart';
import '../../models/property_model.dart';
import '../../services/AI/voice_service.dart';
import '../../services/AI/ai_service.dart';
import '../../widgets/AI/chat_bubble.dart';
import '../../widgets/AI/voice_animation.dart';
import '../../core/theme/app_theme.dart';
import 'live_voice_chat_screen.dart';
import 'conversation_history_screen.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  // Services
  late VoiceService _voiceService;
  late AIService _aiService;

  // State
  final List<ChatMessage> _messages = [];
  bool _isLoadingProperties = false;
  StreamSubscription<String>? _speechSubscription;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Constants
  static const String geminiApiKey = "AIzaSyA_ov3QMPEE-jWUizb2AMfdusPGlGBqCSU";
  static const String propertiesApiUrl =
      "https://state-ecommerce-production.up.railway.app/api/user/properties";

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _addWelcomeMessage();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: AppConstants.normalAnimation,
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fabAnimationController.forward();
  }

  Future<void> _initializeServices() async {
    _voiceService = VoiceService();
    _aiService = AIService();

    // Initialize voice service
    final voiceInitialized = await _voiceService.initialize();
    if (!voiceInitialized) {
      _addSystemMessage("فشل في تهيئة خدمة الصوت");
    }

    // Initialize AI service
    final aiInitialized = await _aiService.initialize(geminiApiKey);
    if (!aiInitialized) {
      _addSystemMessage("فشل في تهيئة خدمة الذكاء الاصطناعي");
    }

    // Listen to voice service
    _voiceService.addListener(_onVoiceServiceUpdate);
    _speechSubscription = _voiceService.speechStream.listen(_onSpeechResult);

    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onVoiceServiceUpdate() {
    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _debugServicesStatus() {
    if (kDebugMode) {
      print("=== Services Status Debug ===");
      print("Voice Service Initialized: ${_voiceService.isInitialized}");
      print("Voice Service Status: ${_voiceService.voiceStatus.state}");
      print("Voice Service Message: ${_voiceService.voiceStatus.message}");
      print("AI Service Has Properties: ${_aiService.hasProperties}");
      print("AI Service Initialized: ${_aiService.isInitialized}");
      print("Properties Count: ${_aiService.properties.length}");
      print("=============================");
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage.createSystemMessage(
      AppConstants.welcomeMessage,
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  void _addSystemMessage(String content) {
    final message = ChatMessage.createSystemMessage(content);
    setState(() {
      _messages.add(message);
    });
  }

  void _addUserMessage(String content) {
    final message = ChatMessage.createUserMessage(content);
    setState(() {
      _messages.add(message);
    });
  }

  void _addAssistantMessage(String content, {bool isTyping = false}) {
    final message = ChatMessage.createAssistantMessage(
      content,
      isTyping: isTyping,
    );
    setState(() {
      _messages.add(message);
    });
  }

  void _removeTypingMessage() {
    setState(() {
      _messages.removeWhere((message) => message.isTyping);
    });
  }

  Future<void> _onSpeechResult(String recognizedText) async {
    if (recognizedText.trim().isEmpty) return;

    _addUserMessage(recognizedText);
    _addAssistantMessage("", isTyping: true);

    try {
      final response = await _aiService.processUserMessage(recognizedText);
      _removeTypingMessage();
      _addAssistantMessage(response);

      // Speak the response
      await _voiceService.speak(response);
    } catch (e) {
      _removeTypingMessage();
      _addAssistantMessage("عذراً، حدث خطأ أثناء معالجة طلبك.");
      _voiceService.setErrorState("خطأ في معالجة الطلب");
    }
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoadingProperties = true;
    });

    _addSystemMessage("جاري تحميل بيانات العقارات...");

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.get(
        Uri.parse(propertiesApiUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final properties = propertiesFromJson(response.body);
        _aiService.updateProperties(properties);

        _addSystemMessage(
          "تم تحميل ${properties.length} عقار بنجاح. يمكنك الآن طرح أسئلتك.",
        );
      } else {
        _addSystemMessage("فشل في تحميل البيانات: ${response.statusCode}");
      }
    } catch (e) {
      _addSystemMessage("خطأ في الشبكة: $e");
    } finally {
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  Future<void> _toggleVoiceMode() async {
    if (kDebugMode) {
      print("=== VOICE BUTTON PRESSED ===");
    }

    _debugServicesStatus();

    // Check if AI service has properties
    if (!_aiService.hasProperties) {
      if (kDebugMode) {
        print("No properties loaded");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى تحميل بيانات العقارات أولاً"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Check if voice service is initialized
    if (!_voiceService.isInitialized) {
      if (kDebugMode) {
        print("Voice service not initialized");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خدمة الصوت غير متاحة. يرجى إعادة تشغيل التطبيق."),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Navigate to live voice chat screen
    final result = await Navigator.of(context).push<List<ChatMessage>>(
      MaterialPageRoute(
        builder:
            (context) => LiveVoiceChatScreen(
              voiceService: _voiceService,
              aiService: _aiService,
            ),
      ),
    );

    // Handle the result from live chat
    if (result != null && result.isNotEmpty && mounted) {
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
      if (mounted) {
        if (action == 'new_chat') {
          // Clear current messages and start fresh
          setState(() {
            _messages.clear();
          });
          _addWelcomeMessage();
        } else if (action == 'continue_chat') {
          // Add the conversation to current messages
          setState(() {
            _messages.addAll(result);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _voiceService.removeListener(_onVoiceServiceUpdate);
    _voiceService.dispose();
    _aiService.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("مساعدك العقاري الذكي"),
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      actions: [
        if (_isLoadingProperties)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProperties,
            tooltip: "تحديث بيانات العقارات",
          ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfoDialog,
          tooltip: "معلومات",
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_voiceService.voiceStatus.isActive) _buildVoiceStatusBar(),
        Expanded(
          child: MessagesList(
            messages: _messages,
            showAvatars: true,
            showTimestamps: false,
          ),
        ),
        _buildSuggestedQuestions(),
      ],
    );
  }

  Widget _buildVoiceStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: _voiceService.voiceStatus.statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: VoiceStatusIndicator(
        voiceStatus: _voiceService.voiceStatus,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    if (_voiceService.isContinuousMode || _messages.length > 2) {
      return const SizedBox.shrink();
    }

    final suggestions = _aiService.getSuggestedQuestions();

    return Container(
      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "اقتراحات:",
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Wrap(
            spacing: AppConstants.smallSpacing,
            runSpacing: AppConstants.smallSpacing,
            children:
                suggestions.map((suggestion) {
                  return _buildSuggestionChip(suggestion);
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () => _onSpeechResult(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          suggestion,
          style: const TextStyle(color: AppTheme.accentTextColor, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: VoiceAnimationWidget(
        voiceStatus: _voiceService.voiceStatus,
        size: 80,
        onTap: _toggleVoiceMode,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              "معلومات التطبيق",
              style: TextStyle(color: AppTheme.primaryTextColor),
            ),
            content: const Text(
              "مساعد عقاري ذكي يستخدم الذكاء الاصطناعي للإجابة على استفساراتك حول العقارات المتاحة.\n\n"
              "• اضغط على الزر للبدء في المحادثة الصوتية\n"
              "• تحدث بوضوح باللغة العربية\n"
              "• تأكد من تحميل بيانات العقارات أولاً",
              style: TextStyle(color: AppTheme.primaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "حسناً",
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
    );
  }
}
