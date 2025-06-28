import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/chat_message_model.dart';

class ConversationAnalyticsService extends ChangeNotifier {
  final List<ConversationMetrics> _sessionMetrics = [];
  final Map<String, dynamic> _userBehaviorData = {};
  final Map<String, int> _topicFrequency = {};
  final Map<String, double> _responseQuality = {};
  
  ConversationMetrics? _currentSessionMetrics;
  DateTime? _sessionStartTime;
  DateTime? _lastInteractionTime;
  
  // Real-time metrics
  int _totalMessages = 0;
  int _userMessages = 0;
  int _aiMessages = 0;
  double _averageResponseTime = 0.0;
  double _userSatisfactionScore = 0.0;
  double _conversationCompletionRate = 0.0;
  
  // Voice metrics
  double _totalTalkTime = 0.0;
  double _userTalkTime = 0.0;
  double _aiTalkTime = 0.0;
  double _averageUserMessageLength = 0.0;
  double _averageAiMessageLength = 0.0;
  
  // Engagement metrics
  double _engagementScore = 0.0;
  int _interruptionCount = 0;
  int _clarificationRequests = 0;
  int _successfulTaskCompletions = 0;
  
  // Getters
  List<ConversationMetrics> get sessionMetrics => List.unmodifiable(_sessionMetrics);
  ConversationMetrics? get currentSessionMetrics => _currentSessionMetrics;
  int get totalMessages => _totalMessages;
  int get userMessages => _userMessages;
  int get aiMessages => _aiMessages;
  double get averageResponseTime => _averageResponseTime;
  double get userSatisfactionScore => _userSatisfactionScore;
  double get conversationCompletionRate => _conversationCompletionRate;
  double get totalTalkTime => _totalTalkTime;
  double get userTalkTime => _userTalkTime;
  double get aiTalkTime => _aiTalkTime;
  double get engagementScore => _engagementScore;
  Map<String, int> get topicFrequency => Map.unmodifiable(_topicFrequency);
  
  void initialize() {
    _loadAnalyticsData();
    _startNewSession();
  }
  
  void _loadAnalyticsData() {
    // In a real app, load from persistent storage
    _userBehaviorData.addAll({
      'preferredConversationLength': 5.2, // minutes
      'averageMessagesPerSession': 12.5,
      'mostActiveTimeOfDay': 14, // 2 PM
      'preferredResponseSpeed': 'medium',
      'conversationStyle': 'detailed',
    });
  }
  
  void _startNewSession() {
    _currentSessionMetrics = ConversationMetrics(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      userMessages: 0,
      aiMessages: 0,
      totalDuration: Duration.zero,
      userTalkTime: Duration.zero,
      aiTalkTime: Duration.zero,
      topics: [],
      averageResponseTime: 0.0,
      satisfactionScore: 0.0,
      engagementScore: 0.0,
      completionRate: 0.0,
      interruptionCount: 0,
      clarificationRequests: 0,
      taskCompletions: 0,
    );
    
    _sessionStartTime = DateTime.now();
    _lastInteractionTime = DateTime.now();
    
    // Reset session counters
    _totalMessages = 0;
    _userMessages = 0;
    _aiMessages = 0;
    _interruptionCount = 0;
    _clarificationRequests = 0;
    _successfulTaskCompletions = 0;
    
    notifyListeners();
  }
  
  void endCurrentSession() {
    if (_currentSessionMetrics != null && _sessionStartTime != null) {
      _currentSessionMetrics!.endTime = DateTime.now();
      _currentSessionMetrics!.totalDuration = DateTime.now().difference(_sessionStartTime!);
      _currentSessionMetrics!.userMessages = _userMessages;
      _currentSessionMetrics!.aiMessages = _aiMessages;
      _currentSessionMetrics!.averageResponseTime = _averageResponseTime;
      _currentSessionMetrics!.satisfactionScore = _userSatisfactionScore;
      _currentSessionMetrics!.engagementScore = _engagementScore;
      _currentSessionMetrics!.completionRate = _conversationCompletionRate;
      _currentSessionMetrics!.interruptionCount = _interruptionCount;
      _currentSessionMetrics!.clarificationRequests = _clarificationRequests;
      _currentSessionMetrics!.taskCompletions = _successfulTaskCompletions;
      
      _sessionMetrics.insert(0, _currentSessionMetrics!);
      
      // Keep only last 50 sessions
      if (_sessionMetrics.length > 50) {
        _sessionMetrics.removeRange(50, _sessionMetrics.length);
      }
      
      _currentSessionMetrics = null;
      _updateUserBehaviorData();
      notifyListeners();
    }
  }
  
  void recordMessage(ChatMessage message) {
    _totalMessages++;
    _lastInteractionTime = DateTime.now();
    
    if (message.isUser) {
      _userMessages++;
      _recordUserMessage(message);
    } else {
      _aiMessages++;
      _recordAiMessage(message);
    }
    
    _updateEngagementScore();
    notifyListeners();
  }
  
  void _recordUserMessage(ChatMessage message) {
    // Analyze user message
    final messageLength = message.text.length;
    _averageUserMessageLength = (_averageUserMessageLength * (_userMessages - 1) + messageLength) / _userMessages;
    
    // Extract topics
    final topics = _extractTopics(message.text);
    for (final topic in topics) {
      _topicFrequency[topic] = (_topicFrequency[topic] ?? 0) + 1;
      if (_currentSessionMetrics != null && !_currentSessionMetrics!.topics.contains(topic)) {
        _currentSessionMetrics!.topics.add(topic);
      }
    }
    
    // Detect clarification requests
    if (_isClarificationRequest(message.text)) {
      _clarificationRequests++;
    }
    
    // Detect task completion indicators
    if (_isTaskCompletion(message.text)) {
      _successfulTaskCompletions++;
    }
  }
  
  void _recordAiMessage(ChatMessage message) {
    final messageLength = message.text.length;
    _averageAiMessageLength = (_averageAiMessageLength * (_aiMessages - 1) + messageLength) / _aiMessages;
    
    // Calculate response time (simulated)
    final responseTime = _calculateResponseTime();
    _averageResponseTime = (_averageResponseTime * (_aiMessages - 1) + responseTime) / _aiMessages;
  }
  
  double _calculateResponseTime() {
    // Simulate response time calculation
    // In a real app, you'd measure actual time between user message and AI response
    return 1.5 + Random().nextDouble() * 2.0; // 1.5-3.5 seconds
  }
  
  List<String> _extractTopics(String text) {
    final topics = <String>[];
    final lowerText = text.toLowerCase();
    
    // Property types
    if (lowerText.contains('شقة') || lowerText.contains('شقق')) topics.add('شقق');
    if (lowerText.contains('فيلا') || lowerText.contains('فلل')) topics.add('فلل');
    if (lowerText.contains('أرض') || lowerText.contains('قطعة')) topics.add('أراضي');
    if (lowerText.contains('محل') || lowerText.contains('مكتب')) topics.add('تجاري');
    
    // Locations
    if (lowerText.contains('رياض')) topics.add('الرياض');
    if (lowerText.contains('جدة')) topics.add('جدة');
    if (lowerText.contains('دمام')) topics.add('الدمام');
    
    // Actions
    if (lowerText.contains('سعر') || lowerText.contains('تكلفة')) topics.add('الأسعار');
    if (lowerText.contains('موقع') || lowerText.contains('مكان')) topics.add('المواقع');
    if (lowerText.contains('معاينة') || lowerText.contains('زيارة')) topics.add('المعاينات');
    
    return topics;
  }
  
  bool _isClarificationRequest(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('ماذا تقصد') ||
           lowerText.contains('لم أفهم') ||
           lowerText.contains('وضح') ||
           lowerText.contains('اشرح') ||
           lowerText.contains('كيف');
  }
  
  bool _isTaskCompletion(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('شكراً') ||
           lowerText.contains('ممتاز') ||
           lowerText.contains('تمام') ||
           lowerText.contains('انتهيت') ||
           lowerText.contains('كفى');
  }
  
  void recordVoiceActivity({
    required bool isUserSpeaking,
    required double duration,
  }) {
    if (isUserSpeaking) {
      _userTalkTime += duration;
      if (_currentSessionMetrics != null) {
        _currentSessionMetrics!.userTalkTime = Duration(milliseconds: _userTalkTime.round());
      }
    } else {
      _aiTalkTime += duration;
      if (_currentSessionMetrics != null) {
        _currentSessionMetrics!.aiTalkTime = Duration(milliseconds: _aiTalkTime.round());
      }
    }
    
    _totalTalkTime = _userTalkTime + _aiTalkTime;
    notifyListeners();
  }
  
  void recordInterruption() {
    _interruptionCount++;
    notifyListeners();
  }
  
  void recordUserSatisfaction(double score) {
    _userSatisfactionScore = score.clamp(0.0, 5.0);
    notifyListeners();
  }
  
  void _updateEngagementScore() {
    // Calculate engagement based on multiple factors
    double score = 0.0;
    
    // Message frequency (higher is better, up to a point)
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inMinutes;
      final messagesPerMinute = sessionDuration > 0 ? _totalMessages / sessionDuration : 0;
      score += min(messagesPerMinute * 10, 30); // Max 30 points
    }
    
    // Topic variety (more topics = higher engagement)
    final uniqueTopics = _currentSessionMetrics?.topics.length ?? 0;
    score += uniqueTopics * 5; // 5 points per topic
    
    // Low interruption rate (fewer interruptions = better engagement)
    final interruptionRate = _totalMessages > 0 ? _interruptionCount / _totalMessages : 0;
    score += (1 - interruptionRate) * 20; // Max 20 points
    
    // Task completion rate
    final completionRate = _totalMessages > 0 ? _successfulTaskCompletions / _totalMessages : 0;
    score += completionRate * 25; // Max 25 points
    
    // Response quality (based on clarification requests)
    final clarificationRate = _totalMessages > 0 ? _clarificationRequests / _totalMessages : 0;
    score += (1 - clarificationRate) * 25; // Max 25 points
    
    _engagementScore = score.clamp(0.0, 100.0);
  }
  
  void _updateUserBehaviorData() {
    if (_sessionMetrics.isNotEmpty) {
      final recentSessions = _sessionMetrics.take(10).toList();
      
      // Update average session length
      final avgDuration = recentSessions
          .map((s) => s.totalDuration.inMinutes)
          .reduce((a, b) => a + b) / recentSessions.length;
      _userBehaviorData['preferredConversationLength'] = avgDuration;
      
      // Update average messages per session
      final avgMessages = recentSessions
          .map((s) => s.userMessages + s.aiMessages)
          .reduce((a, b) => a + b) / recentSessions.length;
      _userBehaviorData['averageMessagesPerSession'] = avgMessages;
      
      // Update most active time
      final hours = recentSessions.map((s) => s.startTime.hour).toList();
      final hourFrequency = <int, int>{};
      for (final hour in hours) {
        hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
      }
      final mostActiveHour = hourFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      _userBehaviorData['mostActiveTimeOfDay'] = mostActiveHour;
    }
  }
  
  // Analytics queries
  Map<String, dynamic> getSessionSummary() {
    return {
      'totalSessions': _sessionMetrics.length,
      'averageSessionDuration': _getAverageSessionDuration(),
      'totalConversationTime': _getTotalConversationTime(),
      'averageMessagesPerSession': _getAverageMessagesPerSession(),
      'userSatisfactionAverage': _getAverageSatisfaction(),
      'engagementScoreAverage': _getAverageEngagement(),
      'mostDiscussedTopics': _getMostDiscussedTopics(5),
      'conversationCompletionRate': _getAverageCompletionRate(),
    };
  }
  
  double _getAverageSessionDuration() {
    if (_sessionMetrics.isEmpty) return 0.0;
    final totalMinutes = _sessionMetrics
        .map((s) => s.totalDuration.inMinutes)
        .reduce((a, b) => a + b);
    return totalMinutes / _sessionMetrics.length;
  }
  
  Duration _getTotalConversationTime() {
    final totalMinutes = _sessionMetrics
        .map((s) => s.totalDuration.inMinutes)
        .fold(0, (a, b) => a + b);
    return Duration(minutes: totalMinutes);
  }
  
  double _getAverageMessagesPerSession() {
    if (_sessionMetrics.isEmpty) return 0.0;
    final totalMessages = _sessionMetrics
        .map((s) => s.userMessages + s.aiMessages)
        .reduce((a, b) => a + b);
    return totalMessages / _sessionMetrics.length;
  }
  
  double _getAverageSatisfaction() {
    if (_sessionMetrics.isEmpty) return 0.0;
    final totalSatisfaction = _sessionMetrics
        .map((s) => s.satisfactionScore)
        .reduce((a, b) => a + b);
    return totalSatisfaction / _sessionMetrics.length;
  }
  
  double _getAverageEngagement() {
    if (_sessionMetrics.isEmpty) return 0.0;
    final totalEngagement = _sessionMetrics
        .map((s) => s.engagementScore)
        .reduce((a, b) => a + b);
    return totalEngagement / _sessionMetrics.length;
  }
  
  List<MapEntry<String, int>> _getMostDiscussedTopics(int count) {
    final sortedTopics = _topicFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedTopics.take(count).toList();
  }
  
  double _getAverageCompletionRate() {
    if (_sessionMetrics.isEmpty) return 0.0;
    final totalCompletionRate = _sessionMetrics
        .map((s) => s.completionRate)
        .reduce((a, b) => a + b);
    return totalCompletionRate / _sessionMetrics.length;
  }
  
  // Recommendations
  List<String> getPersonalizedRecommendations() {
    final recommendations = <String>[];
    
    // Based on conversation patterns
    if (_getAverageSessionDuration() < 3) {
      recommendations.add('جرب محادثات أطول للحصول على نتائج أفضل');
    }
    
    if (_getAverageSatisfaction() < 3.5) {
      recommendations.add('استخدم أوامر صوتية أكثر وضوحاً لتحسين الفهم');
    }
    
    if (_interruptionCount > _totalMessages * 0.3) {
      recommendations.add('انتظر انتهاء المساعد من الكلام للحصول على إجابات كاملة');
    }
    
    // Based on usage patterns
    final mostActiveHour = _userBehaviorData['mostActiveTimeOfDay'] as int? ?? 14;
    if (mostActiveHour < 9 || mostActiveHour > 22) {
      recommendations.add('جرب استخدام التطبيق في أوقات النهار للحصول على أداء أفضل');
    }
    
    // Based on topics
    final topTopics = _getMostDiscussedTopics(3);
    if (topTopics.isNotEmpty) {
      final topTopic = topTopics.first.key;
      recommendations.add('بناءً على اهتمامك بـ$topTopic، جرب البحث في مناطق جديدة');
    }
    
    return recommendations;
  }
  
  Map<String, dynamic> getVoiceTrainingTips() {
    return {
      'speakingPace': _userTalkTime > _aiTalkTime * 2 
          ? 'جرب التحدث بوتيرة أبطأ للحصول على فهم أفضل'
          : 'وتيرة كلامك جيدة، استمر',
      'messageLength': _averageUserMessageLength < 20
          ? 'جرب إعطاء تفاصيل أكثر في رسائلك'
          : 'طول رسائلك مناسب',
      'clarityTips': _clarificationRequests > _totalMessages * 0.2
          ? 'استخدم كلمات واضحة وتجنب الكلام السريع'
          : 'وضوح كلامك ممتاز',
      'interactionStyle': _engagementScore > 70
          ? 'أسلوب تفاعلك ممتاز، استمر'
          : 'جرب طرح أسئلة أكثر تفصيلاً',
    };
  }
}

class ConversationMetrics {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  Duration totalDuration;
  int userMessages;
  int aiMessages;
  Duration userTalkTime;
  Duration aiTalkTime;
  List<String> topics;
  double averageResponseTime;
  double satisfactionScore;
  double engagementScore;
  double completionRate;
  int interruptionCount;
  int clarificationRequests;
  int taskCompletions;
  
  ConversationMetrics({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.totalDuration,
    required this.userMessages,
    required this.aiMessages,
    required this.userTalkTime,
    required this.aiTalkTime,
    required this.topics,
    required this.averageResponseTime,
    required this.satisfactionScore,
    required this.engagementScore,
    required this.completionRate,
    required this.interruptionCount,
    required this.clarificationRequests,
    required this.taskCompletions,
  });
}
