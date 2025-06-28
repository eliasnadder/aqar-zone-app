import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/AI/accessibility_service.dart';

class VisualCaptions extends StatefulWidget {
  final String? currentText;
  final bool isUserSpeaking;
  final bool isAiSpeaking;
  final bool isVisible;
  final AccessibilityService? accessibilityService;

  const VisualCaptions({
    super.key,
    this.currentText,
    this.isUserSpeaking = false,
    this.isAiSpeaking = false,
    this.isVisible = true,
    this.accessibilityService,
  });

  @override
  State<VisualCaptions> createState() => _VisualCaptionsState();
}

class _VisualCaptionsState extends State<VisualCaptions>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _typewriterController;
  late Animation<double> _fadeAnimation;
  late Animation<int> _typewriterAnimation;

  String _displayedText = '';
  String _currentSpeaker = '';
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _typewriterAnimation = IntTween(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.easeOut),
    );

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(VisualCaptions oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentText != oldWidget.currentText &&
        widget.currentText != null) {
      _updateCaption(widget.currentText!);
    }

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }

    if (widget.isUserSpeaking != oldWidget.isUserSpeaking ||
        widget.isAiSpeaking != oldWidget.isAiSpeaking) {
      _updateSpeaker();
    }
  }

  void _updateCaption(String text) {
    if (text.isEmpty) return;

    setState(() {
      _displayedText = text;
    });

    // Update typewriter animation
    _typewriterAnimation = IntTween(begin: 0, end: text.length).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.easeOut),
    );

    _typewriterController.forward(from: 0);

    // Auto-hide after 5 seconds of inactivity
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !widget.isUserSpeaking && !widget.isAiSpeaking) {
        setState(() {
          _displayedText = '';
        });
      }
    });
  }

  void _updateSpeaker() {
    if (widget.isUserSpeaking) {
      _currentSpeaker = 'أنت';
    } else if (widget.isAiSpeaking) {
      _currentSpeaker = 'المساعد الذكي';
    } else {
      _currentSpeaker = '';
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible ||
        widget.accessibilityService?.isVisualCaptionsEnabled != true) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: _buildCaptionContainer(),
        );
      },
    );
  }

  Widget _buildCaptionContainer() {
    final accessibilityService = widget.accessibilityService;
    final position = accessibilityService?.captionPosition ?? 'bottom';

    return Positioned(
      top: position == 'top' ? 100 : null,
      bottom: position == 'bottom' ? 100 : null,
      left: 16,
      right: 16,
      child: _buildCaptionBox(),
    );
  }

  Widget _buildCaptionBox() {
    if (_displayedText.isEmpty) {
      return const SizedBox.shrink();
    }

    final accessibilityService = widget.accessibilityService;
    final fontSize = accessibilityService?.captionFontSize ?? 16.0;
    final showSpeakerLabels = accessibilityService?.showSpeakerLabels ?? true;
    final showTimestamps = accessibilityService?.showTimestamps ?? false;
    final isHighContrast = accessibilityService?.isHighContrastEnabled ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isHighContrast
                ? Colors.black.withValues(alpha: 0.9)
                : AppTheme.cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isHighContrast
                  ? Colors.white
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
          width: isHighContrast ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpeakerLabels && _currentSpeaker.isNotEmpty)
            _buildSpeakerLabel(isHighContrast),

          if (showTimestamps) _buildTimestamp(isHighContrast),

          _buildCaptionText(fontSize, isHighContrast),

          _buildVoiceActivityIndicator(),
        ],
      ),
    );
  }

  Widget _buildSpeakerLabel(bool isHighContrast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isHighContrast
                ? Colors.white
                : AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _currentSpeaker,
        style: TextStyle(
          color: isHighContrast ? Colors.black : AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimestamp(bool isHighContrast) {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        timeString,
        style: TextStyle(
          color:
              isHighContrast
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppTheme.secondaryTextColor,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildCaptionText(double fontSize, bool isHighContrast) {
    return AnimatedBuilder(
      animation: _typewriterAnimation,
      builder: (context, child) {
        final displayLength = _typewriterAnimation.value;
        final visibleText =
            _displayedText.length > displayLength
                ? _displayedText.substring(0, displayLength)
                : _displayedText;

        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: visibleText,
                style: TextStyle(
                  color:
                      isHighContrast ? Colors.white : AppTheme.primaryTextColor,
                  fontSize: fontSize,
                  height: 1.4,
                  fontWeight:
                      isHighContrast ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (displayLength < _displayedText.length)
                TextSpan(
                  text: '|',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: fontSize,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceActivityIndicator() {
    if (widget.accessibilityService?.showVoiceActivityIndicator != true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (widget.isUserSpeaking)
            _buildActivityDot(AppTheme.successColor, 'يتحدث المستخدم'),

          if (widget.isAiSpeaking)
            _buildActivityDot(AppTheme.primaryColor, 'يتحدث المساعد'),

          if (!widget.isUserSpeaking && !widget.isAiSpeaking)
            _buildActivityDot(AppTheme.secondaryTextColor, 'صامت'),
        ],
      ),
    );
  }

  Widget _buildActivityDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

// Live transcription widget with word-by-word highlighting
class LiveTranscriptionWidget extends StatefulWidget {
  final String text;
  final List<String> words;
  final int currentWordIndex;
  final bool isVisible;
  final AccessibilityService? accessibilityService;

  const LiveTranscriptionWidget({
    super.key,
    required this.text,
    this.words = const [],
    this.currentWordIndex = -1,
    this.isVisible = true,
    this.accessibilityService,
  });

  @override
  State<LiveTranscriptionWidget> createState() =>
      _LiveTranscriptionWidgetState();
}

class _LiveTranscriptionWidgetState extends State<LiveTranscriptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();

    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _highlightAnimation = ColorTween(
      begin: AppTheme.primaryColor.withValues(alpha: 0.3),
      end: AppTheme.primaryColor.withValues(alpha: 0.1),
    ).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LiveTranscriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentWordIndex != oldWidget.currentWordIndex) {
      _highlightController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible ||
        widget.accessibilityService?.isVisualCaptionsEnabled != true) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child:
          widget.words.isNotEmpty
              ? _buildWordHighlighting()
              : _buildSimpleText(),
    );
  }

  Widget _buildWordHighlighting() {
    return AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        return RichText(
          text: TextSpan(
            children:
                widget.words.asMap().entries.map((entry) {
                  final index = entry.key;
                  final word = entry.value;
                  final isCurrentWord = index == widget.currentWordIndex;

                  return TextSpan(
                    text: '$word ',
                    style: TextStyle(
                      color:
                          isCurrentWord
                              ? AppTheme.primaryColor
                              : AppTheme.primaryTextColor,
                      fontSize:
                          widget.accessibilityService?.captionFontSize ?? 16,
                      fontWeight:
                          isCurrentWord ? FontWeight.w600 : FontWeight.normal,
                      backgroundColor:
                          isCurrentWord ? _highlightAnimation.value : null,
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSimpleText() {
    return Text(
      widget.text,
      style: TextStyle(
        color: AppTheme.primaryTextColor,
        fontSize: widget.accessibilityService?.captionFontSize ?? 16,
        height: 1.4,
      ),
    );
  }
}
