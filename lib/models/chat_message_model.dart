import 'package:flutter/material.dart';

enum MessageType { user, assistant, system, error }

enum MessageStatus { sending, sent, delivered, error }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isTyping;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isTyping = false,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isTyping,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isTyping: isTyping ?? this.isTyping,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFromUser => type == MessageType.user;
  bool get isFromAssistant => type == MessageType.assistant;
  bool get isSystemMessage => type == MessageType.system;
  bool get isErrorMessage => type == MessageType.error;

  IconData get messageIcon {
    switch (type) {
      case MessageType.user:
        return Icons.person;
      case MessageType.assistant:
        return Icons.smart_toy;
      case MessageType.system:
        return Icons.info_outline;
      case MessageType.error:
        return Icons.error_outline;
    }
  }

  String get senderName {
    switch (type) {
      case MessageType.user:
        return "أنت";
      case MessageType.assistant:
        return "المساعد";
      case MessageType.system:
        return "النظام";
      case MessageType.error:
        return "خطأ";
    }
  }

  Color get bubbleColor {
    switch (type) {
      case MessageType.user:
        return const Color(0xFF1A73E8);
      case MessageType.assistant:
        return const Color(0xFF2D2D2D);
      case MessageType.system:
        return const Color(0xFF34A853);
      case MessageType.error:
        return const Color(0xFFEA4335);
    }
  }

  Color get textColor {
    switch (type) {
      case MessageType.user:
        return Colors.white;
      case MessageType.assistant:
        return const Color(0xFFE8EAED);
      case MessageType.system:
        return Colors.white;
      case MessageType.error:
        return Colors.white;
    }
  }

  bool get isUser => type == MessageType.user;

  static ChatMessage createUserMessage(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  static ChatMessage createAssistantMessage(
    String content, {
    bool isTyping = false,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isTyping: isTyping,
    );
  }

  static ChatMessage createSystemMessage(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  static ChatMessage createErrorMessage(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.error,
      timestamp: DateTime.now(),
      status: MessageStatus.error,
    );
  }

  static ChatMessage createTypingMessage() {
    return ChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isTyping: true,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, type: $type, timestamp: $timestamp, status: $status, isTyping: $isTyping)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // JSON serialization methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'isTyping': isTyping,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.assistant,
      ),
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isTyping: json['isTyping'] ?? false,
      metadata: json['metadata'],
    );
  }

  // Legacy compatibility methods
  String get text => content;
}

// Voice state for the chat
enum VoiceState { idle, listening, processing, speaking, error }

class VoiceStatus {
  final VoiceState state;
  final String message;
  final double? confidence;
  final Duration? duration;

  const VoiceStatus({
    required this.state,
    required this.message,
    this.confidence,
    this.duration,
  });

  VoiceStatus copyWith({
    VoiceState? state,
    String? message,
    double? confidence,
    Duration? duration,
  }) {
    return VoiceStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      confidence: confidence ?? this.confidence,
      duration: duration ?? this.duration,
    );
  }

  bool get isActive => state != VoiceState.idle;
  bool get isListening => state == VoiceState.listening;
  bool get isProcessing => state == VoiceState.processing;
  bool get isSpeaking => state == VoiceState.speaking;
  bool get hasError => state == VoiceState.error;

  Color get statusColor {
    switch (state) {
      case VoiceState.idle:
        return const Color(0xFF9AA0A6);
      case VoiceState.listening:
        return const Color(0xFF1A73E8);
      case VoiceState.processing:
        return const Color(0xFFFFBF00);
      case VoiceState.speaking:
        return const Color(0xFF34A853);
      case VoiceState.error:
        return const Color(0xFFEA4335);
    }
  }

  IconData get statusIcon {
    switch (state) {
      case VoiceState.idle:
        return Icons.mic_off;
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.hourglass_empty;
      case VoiceState.speaking:
        return Icons.volume_up;
      case VoiceState.error:
        return Icons.error;
    }
  }
}
