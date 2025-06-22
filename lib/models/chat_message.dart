enum MessageSender { user, ai }

class ChatMessage {
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    MessageSender? sender,
    String? text,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] == 'user' ? MessageSender.user : MessageSender.ai,
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isLoading: json['isLoading'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender == MessageSender.user ? 'user' : 'ai',
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
    };
  }
}
