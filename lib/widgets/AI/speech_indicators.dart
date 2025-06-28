import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ConnectionStatus { connected, connecting, disconnected, error, poor }

// Speech confidence indicator
class SpeechConfidenceIndicator extends StatefulWidget {
  final double confidence;
  final bool isVisible;
  final String? recognizedText;

  const SpeechConfidenceIndicator({
    super.key,
    required this.confidence,
    this.isVisible = true,
    this.recognizedText,
  });

  @override
  State<SpeechConfidenceIndicator> createState() =>
      _SpeechConfidenceIndicatorState();
}

class _SpeechConfidenceIndicatorState extends State<SpeechConfidenceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(SpeechConfidenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getConfidenceColor() {
    if (widget.confidence >= 0.8) {
      return AppTheme.successColor;
    } else if (widget.confidence >= 0.6) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  String _getConfidenceText() {
    final percentage = (widget.confidence * 100).round();
    return '$percentage%';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getConfidenceColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getConfidenceColor().withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: 16, color: _getConfidenceColor()),
                const SizedBox(width: 6),
                Text(
                  _getConfidenceText(),
                  style: TextStyle(
                    color: _getConfidenceColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.recognizedText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      widget.recognizedText!,
                      style: const TextStyle(
                        color: AppTheme.primaryTextColor,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Enhanced typing indicator with dots animation
class TypingIndicator extends StatefulWidget {
  final bool isVisible;
  final String message;
  final Color color;

  const TypingIndicator({
    super.key,
    required this.isVisible,
    this.message = "AI is thinking",
    this.color = AppTheme.primaryColor,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
        _dotsController.repeat();
      } else {
        _fadeController.reverse();
        _dotsController.stop();
      }
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final animationValue = (_dotsController.value - delay)
                            .clamp(0.0, 1.0);
                        final scale = sin(animationValue * pi) * 0.5 + 0.5;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Transform.scale(
                            scale: 0.5 + scale * 0.5,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.color.withValues(
                                  alpha: 0.5 + scale * 0.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Connection status indicator
class ConnectionStatusIndicator extends StatefulWidget {
  final ConnectionStatus status;
  final String? customMessage;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.customMessage,
  });

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == ConnectionStatus.connecting) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.status == ConnectionStatus.connecting) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case ConnectionStatus.connected:
        return AppTheme.successColor;
      case ConnectionStatus.connecting:
        return AppTheme.warningColor;
      case ConnectionStatus.disconnected:
        return AppTheme.errorColor;
      case ConnectionStatus.poor:
        return AppTheme.warningColor;
      case ConnectionStatus.error:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case ConnectionStatus.connected:
        return Icons.wifi;
      case ConnectionStatus.connecting:
        return Icons.wifi_find;
      case ConnectionStatus.disconnected:
        return Icons.wifi_off;
      case ConnectionStatus.poor:
        return Icons.signal_wifi_bad;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }

  String _getStatusMessage() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    }

    switch (widget.status) {
      case ConnectionStatus.connected:
        return "Connected";
      case ConnectionStatus.connecting:
        return "Connecting...";
      case ConnectionStatus.disconnected:
        return "Disconnected";
      case ConnectionStatus.poor:
        return "Poor Connection";
      case ConnectionStatus.error:
        return "Connection Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale:
              widget.status == ConnectionStatus.connecting
                  ? _pulseAnimation.value
                  : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(), size: 14, color: _getStatusColor()),
                const SizedBox(width: 4),
                Text(
                  _getStatusMessage(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Real-time transcription widget with word highlighting
class RealtimeTranscription extends StatefulWidget {
  final String text;
  final List<String> words;
  final int currentWordIndex;
  final bool isVisible;

  const RealtimeTranscription({
    super.key,
    required this.text,
    this.words = const [],
    this.currentWordIndex = -1,
    this.isVisible = true,
  });

  @override
  State<RealtimeTranscription> createState() => _RealtimeTranscriptionState();
}

class _RealtimeTranscriptionState extends State<RealtimeTranscription>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RealtimeTranscription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
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
          ),
        );
      },
    );
  }

  Widget _buildWordHighlighting() {
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
                  fontSize: 16,
                  fontWeight:
                      isCurrentWord ? FontWeight.w600 : FontWeight.normal,
                  backgroundColor:
                      isCurrentWord
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : null,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSimpleText() {
    return Text(
      widget.text,
      style: const TextStyle(
        color: AppTheme.primaryTextColor,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }
}
