import 'package:flutter/material.dart';
import '../../models/chat_message_model.dart';
import '../../core/theme/app_theme.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final VoidCallback? onTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = false,
    this.onTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildBubbleContent(),
          ),
        );
      },
    );
  }

  Widget _buildBubbleContent() {
    final isUser = widget.message.isFromUser;
    
    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: AppConstants.smallSpacing,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && widget.showAvatar) _buildAvatar(),
          if (!isUser && widget.showAvatar) const SizedBox(width: AppConstants.smallSpacing),
          Flexible(child: _buildMessageBubble()),
          if (isUser && widget.showAvatar) const SizedBox(width: AppConstants.smallSpacing),
          if (isUser && widget.showAvatar) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.message.bubbleColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.message.bubbleColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        widget.message.messageIcon,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageBubble() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxBubbleWidth,
          minHeight: AppConstants.minBubbleHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.mediumSpacing,
          vertical: AppConstants.smallSpacing + 4,
        ),
        decoration: BoxDecoration(
          color: widget.message.bubbleColor,
          borderRadius: _getBorderRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.isTyping)
              _buildTypingIndicator()
            else
              _buildMessageContent(),
            if (widget.showTimestamp) ...[
              const SizedBox(height: 4),
              _buildTimestamp(),
            ],
          ],
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    const radius = AppConstants.mediumRadius;
    final isUser = widget.message.isFromUser;
    
    return BorderRadius.only(
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: Radius.circular(isUser ? radius : 4),
      bottomRight: Radius.circular(isUser ? 4 : radius),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      widget.message.content,
      style: TextStyle(
        color: widget.message.textColor,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "يكتب",
          style: TextStyle(
            color: widget.message.textColor.withOpacity(0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          height: 16,
          child: _buildTypingDots(),
        ),
      ],
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_animationController.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + (0.5 * (1 + (animationValue * 2 - 1).abs()));
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.message.textColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildTimestamp() {
    final time = TimeOfDay.fromDateTime(widget.message.timestamp);
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return Text(
      timeString,
      style: TextStyle(
        color: widget.message.textColor.withOpacity(0.6),
        fontSize: 11,
      ),
    );
  }
}

class MessagesList extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool showAvatars;
  final bool showTimestamps;
  final ScrollController? scrollController;
  final Function(ChatMessage)? onMessageTap;

  const MessagesList({
    super.key,
    required this.messages,
    this.showAvatars = true,
    this.showTimestamps = false,
    this.scrollController,
    this.onMessageTap,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppConstants.normalAnimation,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text(
          "ابدأ محادثة جديدة",
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return ChatBubble(
          message: message,
          showAvatar: widget.showAvatars,
          showTimestamp: widget.showTimestamps,
          onTap: widget.onMessageTap != null 
              ? () => widget.onMessageTap!(message)
              : null,
        );
      },
    );
  }
}
