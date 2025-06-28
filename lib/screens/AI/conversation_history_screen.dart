import 'package:flutter/material.dart';
import '../../models/chat_message_model.dart';
import '../../core/theme/app_theme.dart';

class ConversationHistoryScreen extends StatelessWidget {
  final List<ChatMessage> conversation;
  final String title;

  const ConversationHistoryScreen({
    super.key,
    required this.conversation,
    this.title = "محادثة صوتية",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.primaryTextColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "${conversation.length ~/ 2} رسائل",
            style: const TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        // Voice button to speak the conversation
        IconButton(
          icon: const Icon(Icons.volume_up, color: AppTheme.primaryColor),
          onPressed: () => _speakConversation(context),
          tooltip: "استماع للمحادثة",
        ),

        // Share button
        IconButton(
          icon: const Icon(Icons.share, color: AppTheme.primaryTextColor),
          onPressed: () => _shareConversation(context),
          tooltip: "مشاركة المحادثة",
        ),

        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.primaryTextColor),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 12),
                      Text('نسخ المحادثة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('حذف المحادثة', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (conversation.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.secondaryTextColor,
            ),
            SizedBox(height: 16),
            Text(
              "لا توجد رسائل في هذه المحادثة",
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Chat ended notice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "انتهت المحادثة الصوتية. يمكنك مراجعة المحادثة أدناه.",
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: conversation.length,
            itemBuilder: (context, index) {
              final message = conversation[index];
              return _buildMessageBubble(message, index);
            },
          ),
        ),

        // Action buttons at bottom
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    final isLastMessage = index == conversation.length - 1;

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastMessage ? 16 : 8,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft:
                    isUser
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                bottomRight:
                    isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : AppTheme.primaryTextColor,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
            child: Text(
              _formatTime(message.timestamp),
              style: const TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Start new chat button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('new_chat'),
              icon: const Icon(Icons.add_comment),
              label: const Text("محادثة جديدة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Continue chat button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop('continue_chat'),
              icon: const Icon(Icons.mic),
              label: const Text("متابعة المحادثة"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return "الآن";
    } else if (difference.inHours < 1) {
      return "منذ ${difference.inMinutes} دقيقة";
    } else if (difference.inDays < 1) {
      return "منذ ${difference.inHours} ساعة";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year}";
    }
  }

  void _speakConversation(BuildContext context) {
    // TODO: Implement text-to-speech for the entire conversation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("سيتم تشغيل المحادثة صوتياً"),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _shareConversation(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("سيتم مشاركة المحادثة"),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'copy':
        // TODO: Copy conversation to clipboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم نسخ المحادثة"),
            backgroundColor: AppTheme.successColor,
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("حذف المحادثة"),
            content: const Text(
              "هل أنت متأكد من حذف هذه المحادثة؟ لا يمكن التراجع عن هذا الإجراء.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("إلغاء"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop('delete');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("حذف"),
              ),
            ],
          ),
    );
  }
}
