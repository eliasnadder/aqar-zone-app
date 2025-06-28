import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/AI/voice_service.dart';
import '../../services/AI/ai_service.dart';
import '../../services/AI/context_awareness_service.dart';
import '../../services/AI/voice_shortcuts_service.dart';
import '../../services/AI/emotion_detection_service.dart';
import '../../services/AI/voice_settings_service.dart';

import '../../models/chat_message.dart';
import '../../widgets/chat_message_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/AI/waveform_visualizer.dart';
import '../../widgets/AI/particle_effects.dart';
import '../../widgets/AI/speech_indicators.dart';
import '../../widgets/AI/quick_action_buttons.dart';
import '../../widgets/AI/smart_interruption_handler.dart';

class LiveVoiceChatScreen extends StatefulWidget {
  final VoiceService voiceService;
  final AIService aiService;
  final ContextAwarenessService? contextService;
  final VoiceShortcutsService? shortcutsService;
  final EmotionDetectionService? emotionService;

  const LiveVoiceChatScreen({
    super.key,
    required this.voiceService,
    required this.aiService,
    this.contextService,
    this.shortcutsService,
    this.emotionService,
  });

  @override
  State<LiveVoiceChatScreen> createState() => _LiveVoiceChatScreenState();
}

class _LiveVoiceChatScreenState extends State<LiveVoiceChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // Scroll controller for conversation area
  final ScrollController _conversationScrollController = ScrollController();

  StreamSubscription<String>? _speechSubscription;
  String _currentUserText = "";
  String _currentAiResponse = "";
  bool _isProcessing = false;
  bool _isAiSpeaking = false;
  final List<ChatMessage> _conversationHistory = [];

  // Enhanced visual state
  double _speechConfidence = 0.0;
  double _audioLevel = 0.0;
  final List<double> _audioLevels = [];
  final ConnectionStatus _connectionStatus = ConnectionStatus.connected;

  // AI Intelligence state
  bool _showQuickActions = false;
  bool _isUserInterrupting = false;
  String _detectedEmotion = 'محايد';
  List<String> _suggestedQuestions = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAIServices();
    _startLiveChat();
  }

  void _initializeAIServices() {
    // Initialize context awareness service
    widget.contextService?.initialize();

    // Initialize voice shortcuts service
    widget.shortcutsService?.initialize(
      onShowProperties: () => _handleQuickAction('اعرض العقارات'),
      onCallAgent: () => _handleQuickAction('اتصل بالوكيل'),
      onSaveConversation: () => _handleQuickAction('احفظ المحادثة'),
      onStartOver: () => _handleQuickAction('ابدأ من جديد'),
      onShowFavorites: () => _handleQuickAction('اعرض المفضلة'),
      onSearchProperties: (query) => _handleQuickAction('ابحث عن $query'),
      onFilterByLocation:
          (location) => _handleQuickAction('في منطقة $location'),
      onFilterByPrice: (price) => _handleQuickAction('بسعر $price'),
      onBookmarkText: (text) => _handleQuickAction('احفظ هذا: $text'),
      onRepeatLast: () => _handleQuickAction('كرر آخر رد'),
    );

    // Initialize emotion detection service
    widget.emotionService?.initialize();

    // Enable voice shortcuts listening
    widget.shortcutsService?.enableCommandListening();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _startLiveChat() {
    // Listen to speech results
    _speechSubscription = widget.voiceService.speechStream.listen(
      _onSpeechResult,
      onError: (error) {
        if (kDebugMode) {
          print("Speech stream error: $error");
        }
      },
      cancelOnError: false,
    );

    // Listen to voice service updates
    widget.voiceService.addListener(_onVoiceServiceUpdate);

    // Start continuous listening
    widget.voiceService.toggleContinuousMode();
  }

  void _onSpeechResult(String text) {
    if (!mounted) return;

    // Check for voice shortcuts first
    if (widget.shortcutsService?.processVoiceInput(text) == true) {
      return; // Command was processed, don't continue with normal flow
    }

    setState(() {
      _currentUserText = text;
      // Simulate speech confidence based on text length and clarity
      _speechConfidence =
          text.length > 10 ? 0.85 + (text.length % 10) * 0.01 : 0.6;
      _speechConfidence = _speechConfidence.clamp(0.0, 1.0);

      // Detect user interruption
      _isUserInterrupting = widget.voiceService.isSpeaking;
    });

    // Analyze emotion from text
    widget.emotionService?.analyzeEmotion(text: text);

    if (text.isNotEmpty) {
      _processUserInput(text);
    }
  }

  void _handleQuickAction(String action) {
    if (kDebugMode) {
      print('Quick action triggered: $action');
    }

    // Process the action as if it was spoken
    _processUserInput(action);

    setState(() {
      _showQuickActions = false;
    });
  }

  void _onVoiceServiceUpdate() {
    // Defer setState to avoid calling it during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isAiSpeaking = widget.voiceService.isSpeaking;

          // Simulate audio levels when listening
          if (widget.voiceService.isListening) {
            _audioLevel =
                0.3 +
                (DateTime.now().millisecondsSinceEpoch % 1000) / 1000 * 0.7;
            _audioLevels.add(_audioLevel);
            if (_audioLevels.length > 50) {
              _audioLevels.removeAt(0);
            }
          } else {
            _audioLevel = 0.0;
          }
        });

        if (widget.voiceService.isListening) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
        }
      }
    });
  }

  Future<void> _processUserInput(String userText) async {
    if (_isProcessing || userText.trim().isEmpty || !mounted) return;

    setState(() {
      _isProcessing = true;
      _currentAiResponse = "";
      _currentUserText = "";
    });

    try {
      // Analyze context and update awareness
      widget.contextService?.analyzeUserMessage(userText);

      // Add user message to history
      final userMessage = ChatMessage(
        sender: MessageSender.user,
        text: userText,
      );
      _conversationHistory.add(userMessage);

      // Add loading message for AI
      final loadingMessage = ChatMessage(
        sender: MessageSender.ai,
        text: "",
        isLoading: true,
      );
      _conversationHistory.add(loadingMessage);

      // Get context summary for AI
      final contextSummary = widget.contextService?.getContextSummary() ?? '';
      final enhancedPrompt =
          contextSummary.isNotEmpty
              ? '$userText\n\nالسياق: $contextSummary'
              : userText;

      // Get AI response with context
      final aiResponse = await widget.aiService.processUserMessage(
        enhancedPrompt,
      );

      if (mounted) {
        setState(() {
          // Replace loading message with actual response
          if (_conversationHistory.isNotEmpty &&
              _conversationHistory.last.isLoading) {
            _conversationHistory.removeLast();
          }

          // Add AI message to history
          final aiMessage = ChatMessage(
            sender: MessageSender.ai,
            text: aiResponse,
          );
          _conversationHistory.add(aiMessage);

          _currentAiResponse = aiResponse;

          // Update suggested questions from context service
          _suggestedQuestions = widget.contextService?.suggestedQuestions ?? [];

          // Update emotion display
          final emotion = widget.emotionService?.currentEmotion.emotion;
          _detectedEmotion =
              widget.emotionService?.getEmotionDescription(
                emotion ?? EmotionType.neutral,
              ) ??
              'محايد';

          // Show quick actions after AI response
          _showQuickActions = true;
        });

        // Auto-scroll to bottom after AI response
        _scrollToBottom();

        // Speak with appropriate emotion
        final responseEmotion =
            widget.emotionService?.getResponseEmotion() ?? EmotionType.neutral;
        await widget.voiceService.speakWithEmotion(aiResponse, responseEmotion);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processing user input: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_conversationScrollController.hasClients) {
      // Add a small delay to ensure the UI has updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_conversationScrollController.hasClients) {
          _conversationScrollController.animateTo(
            _conversationScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _endChat() {
    // Stop voice service
    if (widget.voiceService.isContinuousMode) {
      widget.voiceService.toggleContinuousMode();
    }

    // Navigate back without conversation history to avoid type conflicts
    // The live voice chat maintains its own conversation state
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'voice_settings':
        Navigator.pushNamed(context, '/voice_settings');
        break;
      case 'accessibility':
        Navigator.pushNamed(context, '/accessibility');
        break;
      case 'analytics':
        Navigator.pushNamed(context, '/analytics');
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              'المساعدة',
              style: TextStyle(color: AppTheme.primaryTextColor),
            ),
            content: const Text(
              'للتحدث: اضغط واستمر في الضغط على الزر الأزرق\n'
              'للإيقاف: ارفع إصبعك عن الزر\n'
              'للوضع المستمر: اضغط على زر التشغيل\n'
              'للمساعدة الإضافية: استخدم الإيماءات أو الأوامر الصوتية',
              style: TextStyle(color: AppTheme.secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'حسناً',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // Cancel speech subscription first
    _speechSubscription?.cancel();
    _speechSubscription = null;

    // Remove voice service listener
    widget.voiceService.removeListener(_onVoiceServiceUpdate);

    // Stop continuous mode if active
    if (widget.voiceService.isContinuousMode) {
      widget.voiceService.toggleContinuousMode();
    }

    // Dispose animation controllers
    _pulseController.dispose();
    _waveController.dispose();

    // Dispose scroll controller
    _conversationScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000), // Pure black at top
              Color(0xFF0a0a0a), // Very dark
              Color(0xFF1a1a2e), // Dark blue-purple
              Color(0xFF16213e), // Deeper blue
              Color(0xFF0f3460), // Rich blue at bottom
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGeminiLiveHeader(),
              Expanded(child: _buildGeminiWaveformArea()),
              _buildGeminiBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeminiLiveHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated dots
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  width:
                      widget.voiceService.isListening
                          ? 8 + (index * 4) + (_pulseAnimation.value * 4)
                          : 8 + (index * 2),
                  height:
                      widget.voiceService.isListening
                          ? 8 + (index * 4) + (_pulseAnimation.value * 4)
                          : 8 + (index * 2),
                  decoration: BoxDecoration(
                    color:
                        widget.voiceService.isListening
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            );
          }),

          const SizedBox(width: 8),

          // "Live" text
          const Text(
            'Live',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiWaveformArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          // Large waveform visualization - Fixed height
          Container(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: GeminiWaveformPainter(
                audioLevels: _audioLevels,
                isListening: widget.voiceService.isListening,
                isProcessing: _isProcessing,
                animationValue: _waveAnimation.value,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Scrollable conversation area with chat styling
          Expanded(
            child:
                _conversationHistory.isNotEmpty
                    ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SingleChildScrollView(
                          controller: _conversationScrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _conversationHistory.length,
                            itemBuilder: (context, index) {
                              return ChatMessageWidget(
                                message: _conversationHistory[index],
                                index: index,
                              );
                            },
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: _endChat,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'محادثة صوتية مباشرة',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تحدث بحرية مع الذكاء الاصطناعي',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // ignore: deprecated_member_use
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Settings menu
          Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: theme.colorScheme.primary,
              ),
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: _handleMenuAction,
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'voice_settings',
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings_voice_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'إعدادات الصوت',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'accessibility',
                      child: Row(
                        children: [
                          Icon(
                            Icons.accessibility_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'إمكانية الوصول',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'analytics',
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'التحليلات',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'المساعدة',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Connection status
            ConnectionStatusIndicator(status: _connectionStatus),

            // Speech confidence (only show when listening)
            if (widget.voiceService.isListening &&
                _currentUserText.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                child: SpeechConfidenceIndicator(
                  confidence: _speechConfidence,
                  recognizedText: _currentUserText,
                ),
              ),
            ],

            // Audio level indicator
            if (widget.voiceService.isListening) ...[
              const SizedBox(width: 12),
              AudioLevelIndicator(
                level: _audioLevel,
                isActive: widget.voiceService.isListening,
              ),
            ],

            // Voice state indicator
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getVoiceStateColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getVoiceStateColor(), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getVoiceStateIcon(),
                    size: 12,
                    color: _getVoiceStateColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getVoiceStateText(),
                    style: TextStyle(
                      color: _getVoiceStateColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getVoiceStateColor() {
    if (widget.voiceService.isListening) return AppTheme.successColor;
    if (_isProcessing) return AppTheme.warningColor;
    if (_isAiSpeaking) return AppTheme.primaryColor;
    return AppTheme.secondaryTextColor;
  }

  IconData _getVoiceStateIcon() {
    if (widget.voiceService.isListening) return Icons.mic;
    if (_isProcessing) return Icons.hourglass_empty;
    if (_isAiSpeaking) return Icons.volume_up;
    return Icons.mic_off;
  }

  String _getVoiceStateText() {
    if (widget.voiceService.isListening) return 'يستمع';
    if (_isProcessing) return 'يفكر';
    if (_isAiSpeaking) return 'يتحدث';
    return 'صامت';
  }

  Widget _buildEnhancedChatArea(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced Voice Animation with Particles
          Stack(
            alignment: Alignment.center,
            children: [
              // Particle effects
              ParticleEffects(
                isActive: widget.voiceService.isListening,
                primaryColor: theme.colorScheme.primary,
                size: 160,
              ),

              // Breathing animation for processing
              BreathingAnimation(
                isActive: _isProcessing,
                child: _buildVoiceAnimation(theme),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Waveform Visualizer
          WaveformVisualizer(
            isListening: widget.voiceService.isListening,
            isProcessing: _isProcessing,
            audioLevel: _audioLevel,
            audioLevels: _audioLevels,
            width: 300,
            height: 80,
          ),

          const SizedBox(height: 30),

          // Real-time transcription
          if (_currentUserText.isNotEmpty)
            RealtimeTranscription(
              text: _currentUserText,
              isVisible: _currentUserText.isNotEmpty,
            ),

          const SizedBox(height: 16),

          // AI Response with typing indicator
          if (_isProcessing)
            const TypingIndicator(isVisible: true, message: "AI is thinking")
          else if (_currentAiResponse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _currentAiResponse,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Smart Interruption Handler
          ContextAwareInterruptionHandler(
            isAiSpeaking: _isAiSpeaking,
            isUserSpeaking: widget.voiceService.isListening,
            currentAiText: _currentAiResponse,
            userInput: _currentUserText,
            onInterruptionDetected: () {
              setState(() {
                _isUserInterrupting = true;
              });
            },
            onStopRequested: () {
              // Stop the current voice activity
              if (widget.voiceService.isContinuousMode) {
                widget.voiceService.toggleContinuousMode();
              }
              setState(() {
                _isUserInterrupting = false;
              });
            },
            onContinueRequested: () {
              setState(() {
                _isUserInterrupting = false;
              });
            },
            onTopicChange: (newTopic) {
              _processUserInput(newTopic);
            },
          ),

          // Quick Action Buttons
          if (_showQuickActions && !_isProcessing)
            ContextualQuickActions(
              currentContext: _currentAiResponse,
              isVisible: _showQuickActions,
              onActionSelected: (action) {
                _handleQuickAction(action);
              },
            ),

          // Emotion and Context Indicators
          if (_detectedEmotion != 'محايد' || _suggestedQuestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_detectedEmotion != 'محايد')
                    Row(
                      children: [
                        const Icon(
                          Icons.mood,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المزاج: $_detectedEmotion',
                          style: const TextStyle(
                            color: AppTheme.primaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  if (_suggestedQuestions.isNotEmpty) ...[
                    if (_detectedEmotion != 'محايد') const SizedBox(height: 8),
                    const Text(
                      'اقتراحات:',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...(_suggestedQuestions
                        .take(2)
                        .map(
                          (question) => GestureDetector(
                            onTap: () => _handleQuickAction(question),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceAnimation(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary,
                  // ignore: deprecated_member_use
                  theme.colorScheme.primary.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: widget.voiceService.isListening ? 10 : 2,
                ),
              ],
            ),
            child: Icon(
              widget.voiceService.isListening
                  ? Icons.mic_rounded
                  : _isAiSpeaking
                  ? Icons.volume_up_rounded
                  : Icons.mic_off_rounded,
              color: theme.colorScheme.onPrimary,
              size: 48,
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Secondary actions menu
              _buildSecondaryActionsMenu(),

              // Main voice control button
              _buildMainVoiceButton(),

              // Continuous mode toggle
              _buildContinuousModeButton(),

              // End call button
              _buildEndCallButton(),
            ],
          ),

          const SizedBox(height: 16),

          // Quick action chips
          if (_suggestedQuestions.isNotEmpty) _buildQuickActionChips(),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionsMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
      ),
      color: AppTheme.cardColor,
      onSelected: _handleSecondaryAction,
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'camera',
              child: Row(
                children: [
                  Icon(Icons.videocam, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'تشغيل الكاميرا',
                    style: TextStyle(color: AppTheme.primaryTextColor),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'upload',
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'رفع ملف',
                    style: TextStyle(color: AppTheme.primaryTextColor),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bookmark',
              child: Row(
                children: [
                  Icon(Icons.bookmark_add, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'إضافة إشارة مرجعية',
                    style: TextStyle(color: AppTheme.primaryTextColor),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'تصدير المحادثة',
                    style: TextStyle(color: AppTheme.primaryTextColor),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildMainVoiceButton() {
    return GestureDetector(
      onTap: () {
        if (widget.voiceService.isListening) {
          // If currently listening, stop by toggling continuous mode off
          if (widget.voiceService.isContinuousMode) {
            widget.voiceService.toggleContinuousMode();
          }
        } else {
          // If not listening, start listening
          widget.voiceService.startListening();
        }
      },
      onLongPress: () {
        // Long press toggles continuous mode
        widget.voiceService.toggleContinuousMode();
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color:
              widget.voiceService.isListening
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.voiceService.isListening
                      ? AppTheme.successColor
                      : AppTheme.primaryColor)
                  .withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: widget.voiceService.isListening ? 8 : 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              widget.voiceService.isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 32,
            ),
            if (widget.voiceService.isContinuousMode)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinuousModeButton() {
    return GestureDetector(
      onTap: () => widget.voiceService.toggleContinuousMode(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color:
              widget.voiceService.isContinuousMode
                  ? AppTheme.primaryColor.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border:
              widget.voiceService.isContinuousMode
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
        ),
        child: Icon(
          widget.voiceService.isContinuousMode ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endChat,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildQuickActionChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _suggestedQuestions.take(3).map((question) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    question,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  onPressed: () => _handleQuickAction(question),
                ),
              );
            }).toList(),
      ),
    );
  }

  void _handleSecondaryAction(String action) {
    switch (action) {
      case 'camera':
        // TODO: Implement camera functionality
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ميزة الكاميرا قريباً')));
        break;
      case 'upload':
        // TODO: Implement file upload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ميزة رفع الملفات قريباً')),
        );
        break;
      case 'bookmark':
        // TODO: Implement bookmark functionality
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة إشارة مرجعية')));
        break;
      case 'export':
        // TODO: Implement export functionality
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تصدير المحادثة')));
        break;
    }
  }

  // Gemini-style UI methods
  Widget _buildGeminiHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Live indicator with signal bars
          Row(
            children: [
              // Signal bars animation
              ...List.generate(4, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  margin: EdgeInsets.only(right: index == 3 ? 8 : 2),
                  width: 3,
                  height:
                      widget.voiceService.isListening
                          ? 8 + (index * 4) + (index * 2)
                          : 8 + (index * 2),
                  decoration: BoxDecoration(
                    color:
                        widget.voiceService.isListening
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),

              // "Live" text
              const Text(
                'Live',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiBottomControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera button
          _buildGeminiControlButton(
            icon: Icons.videocam_outlined,
            onTap: () => _handleSecondaryAction('camera'),
          ),

          // Upload button
          _buildGeminiControlButton(
            icon: Icons.upload_file_outlined,
            onTap: () => _handleSecondaryAction('upload'),
          ),

          // Pause/Resume button
          _buildGeminiControlButton(
            icon:
                widget.voiceService.isListening
                    ? Icons.pause
                    : Icons.play_arrow,
            onTap: () {
              if (widget.voiceService.isListening) {
                if (widget.voiceService.isContinuousMode) {
                  widget.voiceService.toggleContinuousMode();
                }
              } else {
                widget.voiceService.startListening();
              }
            },
          ),

          // End call button
          _buildGeminiControlButton(
            icon: Icons.close,
            backgroundColor: Colors.red,
            onTap: _endChat,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Main voice button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              border: Border.all(
                // ignore: deprecated_member_use
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: widget.voiceService.isListening ? 10 : 2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                if (widget.voiceService.isListening) {
                  if (widget.voiceService.isContinuousMode) {
                    widget.voiceService.toggleContinuousMode();
                  }
                } else {
                  widget.voiceService.startListening();
                }
              },
              icon: Icon(
                widget.voiceService.isListening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              iconSize: 64,
            ),
          ),

          // End call button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              border: Border.all(
                // ignore: deprecated_member_use
                color: theme.colorScheme.error.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: _endChat,
              icon: Icon(
                Icons.call_end_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
              iconSize: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera button
          _buildGeminiControlButton(
            icon: Icons.videocam_outlined,
            onTap: () => _handleSecondaryAction('camera'),
          ),

          // Upload button
          _buildGeminiControlButton(
            icon: Icons.upload_outlined,
            onTap: () => _handleSecondaryAction('upload'),
          ),

          // Pause/Resume button
          _buildGeminiControlButton(
            icon:
                widget.voiceService.isContinuousMode
                    ? Icons.pause
                    : Icons.play_arrow,
            onTap: () => widget.voiceService.toggleContinuousMode(),
          ),

          // End call button
          _buildGeminiControlButton(
            icon: Icons.close,
            backgroundColor: const Color(0xFFFF4444),
            onTap: _endChat,
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  String _getGeminiStatusText() {
    if (widget.voiceService.isListening) {
      return 'أستمع إليك...';
    } else if (_isProcessing) {
      return 'أفكر في إجابتك...';
    } else if (_isAiSpeaking) {
      return 'أتحدث معك...';
    } else {
      return 'اضغط على الميكروفون للبدء';
    }
  }
}

// Custom painter for Gemini-style waveform
class GeminiWaveformPainter extends CustomPainter {
  final List<double> audioLevels;
  final bool isListening;
  final bool isProcessing;
  final double animationValue;

  GeminiWaveformPainter({
    required this.audioLevels,
    required this.isListening,
    required this.isProcessing,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = 4.0;
    final barSpacing = 8.0;
    final totalBars = (size.width / (barWidth + barSpacing)).floor();

    // Generate waveform data
    final waveformData = _generateWaveformData(totalBars);

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + barSpacing) + barWidth / 2;

      // Calculate bar height based on audio level and animation
      double baseHeight = 20.0;
      if (isListening && audioLevels.isNotEmpty) {
        final levelIndex = (i * audioLevels.length / totalBars).floor();
        baseHeight =
            20 +
            (audioLevels[levelIndex.clamp(0, audioLevels.length - 1)] * 100);
      } else if (isProcessing) {
        // Animated thinking pattern
        baseHeight =
            20 +
            (math.sin((i * 0.5) + (animationValue * math.pi * 4)) * 30).abs();
      } else {
        // Idle state with subtle animation
        baseHeight =
            20 +
            (math.sin((i * 0.2) + (animationValue * math.pi * 2)) * 10).abs();
      }

      // Apply waveform variation
      baseHeight *= waveformData[i];

      // Color gradient based on position and state
      Color barColor;
      if (isListening) {
        // Blue to cyan gradient when listening
        final t = i / totalBars;
        barColor =
            Color.lerp(
              const Color(0xFF4285F4), // Google Blue
              const Color(0xFF34A853), // Google Green
              t,
            )!;
      } else if (isProcessing) {
        // Purple to blue when processing
        final t =
            (math.sin((i * 0.3) + (animationValue * math.pi * 3)) + 1) / 2;
        barColor =
            Color.lerp(
              const Color(0xFF9C27B0), // Purple
              const Color(0xFF2196F3), // Blue
              t,
            )!;
      } else {
        // Subtle white when idle
        barColor = Colors.white.withOpacity(0.3 + (animationValue * 0.2));
      }

      paint.color = barColor;

      // Draw the bar
      final barHeight = baseHeight.clamp(10.0, size.height * 0.8);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);

      // Add glow effect for active bars
      if (isListening && barHeight > 40) {
        paint.color = barColor.withOpacity(0.3);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(rect, paint);
        paint.maskFilter = null;
      }
    }
  }

  List<double> _generateWaveformData(int count) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    return List.generate(count, (i) {
      // Create a more natural waveform pattern
      final baseWave = math.sin(i * 0.1) * 0.5 + 0.5;
      final noise = (random.nextDouble() - 0.5) * 0.3;
      return (baseWave + noise).clamp(0.2, 1.0);
    });
  }

  @override
  bool shouldRepaint(GeminiWaveformPainter oldDelegate) {
    return oldDelegate.isListening != isListening ||
        oldDelegate.isProcessing != isProcessing ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.audioLevels.length != audioLevels.length;
  }
}
