import 'package:flutter/material.dart';

class EnhancedChatInput extends StatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final bool isLoading;
  final bool isEnabled;
  final String hintText;

  const EnhancedChatInput({
    Key? key,
    required this.messageController,
    required this.onSendMessage,
    this.isLoading = false,
    this.isEnabled = true,
    this.hintText = 'Type your message...',
  }) : super(key: key);

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    widget.messageController.addListener(_onTextChanged);

    if (widget.isLoading) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _onTextChanged() {
    final hasText = widget.messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void didUpdateWidget(EnhancedChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
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
    _scaleController.dispose();
    widget.messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _handleSendPressed() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      widget.onSendMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: TextField(
                controller: widget.messageController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                onSubmitted:
                    (_) => widget.isEnabled ? _handleSendPressed() : null,
                enabled: widget.isEnabled,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _pulseAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildSendButton(theme),
            ),
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isLoading ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final canSend = widget.isEnabled && _hasText && !widget.isLoading;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            canSend
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      child: IconButton(
        onPressed: canSend ? _handleSendPressed : null,
        icon:
            widget.isLoading
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                : Icon(
                  Icons.send_rounded,
                  size: 16,
                  color:
                      canSend
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.outline,
                ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          maximumSize: const Size(36, 36),
        ),
      ),
    );
  }
}
