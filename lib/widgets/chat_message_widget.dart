import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final int index;

  const ChatMessageWidget({Key? key, required this.message, this.index = 0})
    : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800 + (widget.index * 100)),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
      vsync: this,
    );

    // Setup animations
    final isUser = widget.message.sender == MessageSender.user;
    _slideAnimation = Tween<Offset>(
      begin: Offset(isUser ? 1.0 : -1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message.sender == MessageSender.user;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  _buildAvatar(theme, isUser),
                  const SizedBox(width: 12),
                ],
                Flexible(child: _buildMessageBubble(context, theme, isUser)),
                if (isUser) ...[
                  const SizedBox(width: 12),
                  _buildAvatar(theme, isUser),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isUser) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors:
              isUser
                  ? [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withValues(alpha: 0.8),
                  ]
                  : [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUser
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary)
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.transparent,
        child: Icon(
          isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
          size: 20,
          color:
              isUser
                  ? theme.colorScheme.onSecondary
                  : theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ThemeData theme,
    bool isUser,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        gradient:
            isUser
                ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.8,
                    ),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child:
              widget.message.isLoading
                  ? _buildTypingIndicator(theme, isUser)
                  : _buildMessageContent(theme, isUser),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypingDots(
          color:
              isUser
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
        ),
        const SizedBox(width: 8),
        Text(
          'AI is thinking...',
          style: TextStyle(
            color:
                isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(ThemeData theme, bool isUser) {
    return isUser
        ? Text(
          widget.message.text,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        )
        : MarkdownBody(
          data: widget.message.text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 15,
              height: 1.4,
            ),
            listBullet: TextStyle(color: theme.colorScheme.onSurface),
            code: TextStyle(
              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations =
        _controllers.map((controller) {
          return Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < _controllers.length; i++) {
        if (mounted) {
          _controllers[i].forward();
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      await Future.delayed(const Duration(milliseconds: 400));
      for (int i = 0; i < _controllers.length; i++) {
        if (mounted) {
          _controllers[i].reverse();
        }
      }
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: Transform.scale(
                scale: 0.5 + (_animations[index].value * 0.5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: 0.3 + (_animations[index].value * 0.7),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
