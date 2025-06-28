import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SmartInterruptionHandler extends StatefulWidget {
  final bool isAiSpeaking;
  final bool isUserSpeaking;
  final VoidCallback? onInterruptionDetected;
  final VoidCallback? onContinueRequested;
  final VoidCallback? onStopRequested;
  final String? currentAiText;

  const SmartInterruptionHandler({
    super.key,
    required this.isAiSpeaking,
    required this.isUserSpeaking,
    this.onInterruptionDetected,
    this.onContinueRequested,
    this.onStopRequested,
    this.currentAiText,
  });

  @override
  State<SmartInterruptionHandler> createState() => _SmartInterruptionHandlerState();
}

class _SmartInterruptionHandlerState extends State<SmartInterruptionHandler>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isInterruptionDetected = false;
  bool _isShowingOptions = false;
  Timer? _interruptionTimer;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(SmartInterruptionHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detect interruption: user starts speaking while AI is speaking
    if (widget.isAiSpeaking && widget.isUserSpeaking && 
        (!oldWidget.isUserSpeaking || !oldWidget.isAiSpeaking)) {
      _handleInterruption();
    }
    
    // Reset when AI stops speaking or user stops speaking
    if (!widget.isAiSpeaking || !widget.isUserSpeaking) {
      _resetInterruption();
    }
  }

  void _handleInterruption() {
    if (_isInterruptionDetected) return;
    
    setState(() {
      _isInterruptionDetected = true;
    });
    
    // Delay showing options to avoid false positives
    _interruptionTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && widget.isUserSpeaking && widget.isAiSpeaking) {
        _showInterruptionOptions();
        widget.onInterruptionDetected?.call();
      }
    });
  }

  void _showInterruptionOptions() {
    setState(() {
      _isShowingOptions = true;
    });
    
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    
    // Auto-hide after 5 seconds if no action taken
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _hideInterruptionOptions();
      }
    });
  }

  void _hideInterruptionOptions() {
    _fadeController.reverse();
    _pulseController.stop();
    
    setState(() {
      _isShowingOptions = false;
    });
  }

  void _resetInterruption() {
    _interruptionTimer?.cancel();
    _autoHideTimer?.cancel();
    
    if (_isInterruptionDetected || _isShowingOptions) {
      _hideInterruptionOptions();
      
      setState(() {
        _isInterruptionDetected = false;
      });
    }
  }

  void _handleContinue() {
    _hideInterruptionOptions();
    widget.onContinueRequested?.call();
    _resetInterruption();
  }

  void _handleStop() {
    _hideInterruptionOptions();
    widget.onStopRequested?.call();
    _resetInterruption();
  }

  @override
  void dispose() {
    _interruptionTimer?.cancel();
    _autoHideTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isShowingOptions) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInterruptionIndicator(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterruptionIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم اكتشاف مقاطعة - هل تريد إيقاف الذكي الاصطناعي؟',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          label: 'إيقاف',
          icon: Icons.stop,
          color: AppTheme.errorColor,
          onTap: _handleStop,
        ),
        _buildActionButton(
          label: 'متابعة',
          icon: Icons.play_arrow,
          color: AppTheme.successColor,
          onTap: _handleContinue,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced interruption handler with context awareness
class ContextAwareInterruptionHandler extends StatefulWidget {
  final bool isAiSpeaking;
  final bool isUserSpeaking;
  final String? currentAiText;
  final String? userInput;
  final VoidCallback? onInterruptionDetected;
  final VoidCallback? onContinueRequested;
  final VoidCallback? onStopRequested;
  final Function(String)? onTopicChange;

  const ContextAwareInterruptionHandler({
    super.key,
    required this.isAiSpeaking,
    required this.isUserSpeaking,
    this.currentAiText,
    this.userInput,
    this.onInterruptionDetected,
    this.onContinueRequested,
    this.onStopRequested,
    this.onTopicChange,
  });

  @override
  State<ContextAwareInterruptionHandler> createState() => _ContextAwareInterruptionHandlerState();
}

class _ContextAwareInterruptionHandlerState extends State<ContextAwareInterruptionHandler> {
  InterruptionType _interruptionType = InterruptionType.unknown;
  String _suggestedAction = '';

  @override
  void didUpdateWidget(ContextAwareInterruptionHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isUserSpeaking && widget.isAiSpeaking && widget.userInput != null) {
      _analyzeInterruption();
    }
  }

  void _analyzeInterruption() {
    if (widget.userInput == null) return;
    
    final userInput = widget.userInput!.toLowerCase();
    
    // Analyze the type of interruption
    if (userInput.contains('توقف') || userInput.contains('اسكت') || userInput.contains('كفى')) {
      _interruptionType = InterruptionType.stop;
      _suggestedAction = 'إيقاف الذكي الاصطناعي';
    } else if (userInput.contains('لكن') || userInput.contains('بس') || userInput.contains('انتظر')) {
      _interruptionType = InterruptionType.clarification;
      _suggestedAction = 'إيقاف للتوضيح';
    } else if (userInput.contains('أريد') || userInput.contains('أبحث') || userInput.contains('ابحث')) {
      _interruptionType = InterruptionType.topicChange;
      _suggestedAction = 'تغيير الموضوع';
    } else if (userInput.contains('نعم') || userInput.contains('موافق') || userInput.contains('تمام')) {
      _interruptionType = InterruptionType.agreement;
      _suggestedAction = 'متابعة الحديث';
    } else {
      _interruptionType = InterruptionType.question;
      _suggestedAction = 'إيقاف للسؤال';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartInterruptionHandler(
      isAiSpeaking: widget.isAiSpeaking,
      isUserSpeaking: widget.isUserSpeaking,
      currentAiText: widget.currentAiText,
      onInterruptionDetected: widget.onInterruptionDetected,
      onContinueRequested: () {
        if (_interruptionType == InterruptionType.agreement) {
          widget.onContinueRequested?.call();
        } else {
          widget.onStopRequested?.call();
        }
      },
      onStopRequested: () {
        if (_interruptionType == InterruptionType.topicChange && widget.userInput != null) {
          widget.onTopicChange?.call(widget.userInput!);
        } else {
          widget.onStopRequested?.call();
        }
      },
    );
  }
}

enum InterruptionType {
  stop,
  clarification,
  topicChange,
  question,
  agreement,
  unknown,
}
