import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/property_model.dart';

class ContextAwarenessService extends ChangeNotifier {
  final List<ConversationContext> _contextHistory = [];
  final Map<String, dynamic> _userPreferences = {};
  final List<String> _currentTopics = [];
  final Map<String, int> _topicFrequency = {};

  ConversationContext? _currentContext;
  String _userIntent = '';
  double _conversationSentiment = 0.0;
  List<String> _suggestedQuestions = [];

  // Getters
  ConversationContext? get currentContext => _currentContext;
  String get userIntent => _userIntent;
  double get conversationSentiment => _conversationSentiment;
  List<String> get suggestedQuestions => _suggestedQuestions;
  List<String> get currentTopics => _currentTopics;
  Map<String, int> get topicFrequency => Map.unmodifiable(_topicFrequency);

  void initialize() {
    _loadUserPreferences();
    _generateInitialSuggestions();
  }

  void _loadUserPreferences() {
    // In a real app, load from persistent storage
    _userPreferences.addAll({
      'preferredPropertyType': 'apartment',
      'budgetRange': {'min': 200000, 'max': 500000},
      'preferredAreas': ['الرياض', 'جدة', 'الدمام'],
      'conversationStyle': 'friendly',
      'responseLength': 'medium',
    });
  }

  void _generateInitialSuggestions() {
    _suggestedQuestions = [
      "ما هي أنواع العقارات المتاحة؟",
      "أريد شقة في الرياض",
      "ما هو متوسط أسعار الشقق؟",
      "أبحث عن فيلا للبيع",
      "أريد عقار للاستثمار",
    ];
  }

  // Analyze user message and update context
  void analyzeUserMessage(
    String message, {
    List<Property>? relatedProperties,
  }) {
    final context = ConversationContext(
      timestamp: DateTime.now(),
      userMessage: message,
      intent: _detectIntent(message),
      topics: _extractTopics(message),
      sentiment: _analyzeSentiment(message),
      relatedProperties: relatedProperties ?? [],
    );

    _currentContext = context;
    _contextHistory.add(context);

    _updateUserIntent(context.intent);
    _updateTopics(context.topics);
    _updateSentiment(context.sentiment);
    _generateContextualSuggestions();

    notifyListeners();
  }

  String _detectIntent(String message) {
    final lowerMessage = message.toLowerCase();

    // Property search intents
    if (lowerMessage.contains('أبحث') ||
        lowerMessage.contains('أريد') ||
        lowerMessage.contains('أبي')) {
      if (lowerMessage.contains('شقة') || lowerMessage.contains('شقق')) {
        return 'search_apartment';
      } else if (lowerMessage.contains('فيلا') ||
          lowerMessage.contains('فلل')) {
        return 'search_villa';
      } else if (lowerMessage.contains('أرض') ||
          lowerMessage.contains('قطعة')) {
        return 'search_land';
      } else if (lowerMessage.contains('محل') ||
          lowerMessage.contains('مكتب')) {
        return 'search_commercial';
      }
      return 'search_general';
    }

    // Information intents
    if (lowerMessage.contains('سعر') ||
        lowerMessage.contains('كم') ||
        lowerMessage.contains('تكلفة')) {
      return 'price_inquiry';
    }

    if (lowerMessage.contains('موقع') ||
        lowerMessage.contains('مكان') ||
        lowerMessage.contains('منطقة')) {
      return 'location_inquiry';
    }

    if (lowerMessage.contains('مواصفات') ||
        lowerMessage.contains('تفاصيل') ||
        lowerMessage.contains('معلومات')) {
      return 'details_inquiry';
    }

    // Action intents
    if (lowerMessage.contains('اتصل') ||
        lowerMessage.contains('تواصل') ||
        lowerMessage.contains('رقم')) {
      return 'contact_request';
    }

    if (lowerMessage.contains('زيارة') ||
        lowerMessage.contains('معاينة') ||
        lowerMessage.contains('شوف')) {
      return 'visit_request';
    }

    if (lowerMessage.contains('احفظ') ||
        lowerMessage.contains('مفضلة') ||
        lowerMessage.contains('احتفظ')) {
      return 'save_property';
    }

    return 'general_inquiry';
  }

  List<String> _extractTopics(String message) {
    final topics = <String>[];
    final lowerMessage = message.toLowerCase();

    // Property types
    if (lowerMessage.contains('شقة') || lowerMessage.contains('شقق')) {
      topics.add('شقق');
    }
    if (lowerMessage.contains('فيلا') || lowerMessage.contains('فلل')) {
      topics.add('فلل');
    }
    if (lowerMessage.contains('أرض') || lowerMessage.contains('قطعة')) {
      topics.add('أراضي');
    }
    if (lowerMessage.contains('محل') || lowerMessage.contains('مكتب')) {
      topics.add('تجاري');
    }

    // Locations
    if (lowerMessage.contains('رياض')) topics.add('الرياض');
    if (lowerMessage.contains('جدة')) topics.add('جدة');
    if (lowerMessage.contains('دمام')) topics.add('الدمام');
    if (lowerMessage.contains('مكة')) topics.add('مكة');
    if (lowerMessage.contains('المدينة')) topics.add('المدينة المنورة');

    // Features
    if (lowerMessage.contains('غرف') || lowerMessage.contains('غرفة')) {
      topics.add('غرف النوم');
    }
    if (lowerMessage.contains('حمام') || lowerMessage.contains('دورة مياه')) {
      topics.add('دورات المياه');
    }
    if (lowerMessage.contains('مطبخ')) topics.add('مطبخ');
    if (lowerMessage.contains('صالة') || lowerMessage.contains('مجلس')) {
      topics.add('صالة');
    }
    if (lowerMessage.contains('حديقة') || lowerMessage.contains('فناء')) {
      topics.add('حديقة');
    }
    if (lowerMessage.contains('مسبح')) topics.add('مسبح');
    if (lowerMessage.contains('مصعد')) topics.add('مصعد');
    if (lowerMessage.contains('موقف') || lowerMessage.contains('جراج')) {
      topics.add('موقف سيارات');
    }

    // Price-related
    if (lowerMessage.contains('سعر') || lowerMessage.contains('ريال')) {
      topics.add('السعر');
    }
    if (lowerMessage.contains('رخيص') || lowerMessage.contains('اقتصادي')) {
      topics.add('اقتصادي');
    }
    if (lowerMessage.contains('فاخر') || lowerMessage.contains('راقي')) {
      topics.add('فاخر');
    }

    return topics;
  }

  double _analyzeSentiment(String message) {
    final lowerMessage = message.toLowerCase();
    double sentiment = 0.0;

    // Positive indicators
    final positiveWords = [
      'ممتاز',
      'رائع',
      'جميل',
      'أحب',
      'مناسب',
      'جيد',
      'ممكن',
      'نعم',
      'موافق',
    ];
    final negativeWords = [
      'سيء',
      'غالي',
      'صعب',
      'مشكلة',
      'لا أريد',
      'لا',
      'مرفوض',
      'غير مناسب',
    ];

    for (final word in positiveWords) {
      if (lowerMessage.contains(word)) sentiment += 0.2;
    }

    for (final word in negativeWords) {
      if (lowerMessage.contains(word)) sentiment -= 0.2;
    }

    return sentiment.clamp(-1.0, 1.0);
  }

  void _updateUserIntent(String intent) {
    _userIntent = intent;
  }

  void _updateTopics(List<String> topics) {
    _currentTopics.clear();
    _currentTopics.addAll(topics);

    // Update topic frequency
    for (final topic in topics) {
      _topicFrequency[topic] = (_topicFrequency[topic] ?? 0) + 1;
    }
  }

  void _updateSentiment(double sentiment) {
    // Use exponential moving average for conversation sentiment
    _conversationSentiment = _conversationSentiment * 0.7 + sentiment * 0.3;
  }

  void _generateContextualSuggestions() {
    _suggestedQuestions.clear();

    switch (_userIntent) {
      case 'search_apartment':
        _suggestedQuestions.addAll([
          "كم عدد الغرف التي تريدها؟",
          "ما هي المنطقة المفضلة لديك؟",
          "ما هو نطاق الميزانية؟",
          "هل تريد شقة مفروشة؟",
        ]);
        break;

      case 'search_villa':
        _suggestedQuestions.addAll([
          "هل تريد فيلا بحديقة؟",
          "كم عدد الأدوار المطلوب؟",
          "هل تحتاج مسبح؟",
          "ما حجم الفيلا المناسب؟",
        ]);
        break;

      case 'price_inquiry':
        _suggestedQuestions.addAll([
          "هل تريد مقارنة الأسعار؟",
          "ما هو نطاق ميزانيتك؟",
          "هل تبحث عن عروض خاصة؟",
          "هل تريد خيارات تمويل؟",
        ]);
        break;

      case 'location_inquiry':
        _suggestedQuestions.addAll([
          "هل تريد معلومات عن المنطقة؟",
          "ما هي الخدمات المطلوبة قريباً؟",
          "هل تريد عقارات في مناطق أخرى؟",
          "هل المواصلات مهمة لك؟",
        ]);
        break;

      default:
        _generateGeneralSuggestions();
    }

    // Add personalized suggestions based on history
    _addPersonalizedSuggestions();
  }

  void _generateGeneralSuggestions() {
    final generalSuggestions = [
      "أريد شقة في الرياض",
      "ما هي أسعار الفلل؟",
      "أبحث عن عقار للاستثمار",
      "أريد معاينة العقار",
      "كيف يمكنني التواصل مع المالك؟",
    ];

    _suggestedQuestions.addAll(generalSuggestions.take(3));
  }

  void _addPersonalizedSuggestions() {
    // Add suggestions based on most frequent topics
    final sortedTopics =
        _topicFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedTopics.take(2)) {
      final topic = entry.key;
      switch (topic) {
        case 'شقق':
          if (!_suggestedQuestions.any((q) => q.contains('شقة'))) {
            _suggestedQuestions.add("هل تريد المزيد من الشقق؟");
          }
          break;
        case 'فلل':
          if (!_suggestedQuestions.any((q) => q.contains('فيلا'))) {
            _suggestedQuestions.add("هل تريد المزيد من الفلل؟");
          }
          break;
        case 'الرياض':
          if (!_suggestedQuestions.any((q) => q.contains('الرياض'))) {
            _suggestedQuestions.add("هل تريد عقارات أخرى في الرياض؟");
          }
          break;
      }
    }
  }

  // Get context summary for AI
  String getContextSummary() {
    if (_contextHistory.isEmpty) return "لا يوجد سياق سابق";

    final recentContexts = _contextHistory.take(5).toList();
    final topics = recentContexts.expand((c) => c.topics).toSet().join(', ');
    final avgSentiment =
        recentContexts.map((c) => c.sentiment).reduce((a, b) => a + b) /
        recentContexts.length;

    return "المواضيع الحالية: $topics. المزاج العام: ${_getSentimentDescription(avgSentiment)}. النية: $_userIntent";
  }

  String _getSentimentDescription(double sentiment) {
    if (sentiment > 0.3) return "إيجابي";
    if (sentiment < -0.3) return "سلبي";
    return "محايد";
  }

  // Check if user is interested in a property type
  bool isInterestedIn(String propertyType) {
    return _topicFrequency.containsKey(propertyType) &&
        _topicFrequency[propertyType]! > 0;
  }

  // Get conversation insights
  Map<String, dynamic> getConversationInsights() {
    return {
      'totalMessages': _contextHistory.length,
      'averageSentiment': _conversationSentiment,
      'topTopics': _getTopTopics(5),
      'primaryIntent': _userIntent,
      'conversationDuration': _getConversationDuration(),
      'engagementLevel': _calculateEngagementLevel(),
    };
  }

  List<String> _getTopTopics(int count) {
    final sortedTopics =
        _topicFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sortedTopics.take(count).map((e) => e.key).toList();
  }

  Duration _getConversationDuration() {
    if (_contextHistory.isEmpty) return Duration.zero;
    return DateTime.now().difference(_contextHistory.first.timestamp);
  }

  double _calculateEngagementLevel() {
    if (_contextHistory.isEmpty) return 0.0;

    final messageCount = _contextHistory.length;
    final duration = _getConversationDuration().inMinutes;
    final topicVariety = _topicFrequency.length;

    // Simple engagement calculation
    double engagement =
        (messageCount * 0.4) +
        (topicVariety * 0.3) +
        (duration > 0 ? min(duration / 10, 1.0) * 0.3 : 0);
    return engagement.clamp(0.0, 1.0);
  }

  void clearContext() {
    _contextHistory.clear();
    _currentContext = null;
    _userIntent = '';
    _conversationSentiment = 0.0;
    _currentTopics.clear();
    _topicFrequency.clear();
    _generateInitialSuggestions();
    notifyListeners();
  }
}

class ConversationContext {
  final DateTime timestamp;
  final String userMessage;
  final String intent;
  final List<String> topics;
  final double sentiment;
  final List<Property> relatedProperties;

  ConversationContext({
    required this.timestamp,
    required this.userMessage,
    required this.intent,
    required this.topics,
    required this.sentiment,
    required this.relatedProperties,
  });
}
