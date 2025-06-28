import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/property_model.dart';
import '../../core/theme/app_theme.dart';

class AIService extends ChangeNotifier {
  GenerativeModel? _model;
  ChatSession? _chat;
  List<Property> _properties = [];
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  List<Property> get properties => List.unmodifiable(_properties);
  bool get hasProperties => _properties.isNotEmpty;

  Future<bool> initialize(String apiKey) async {
    if (apiKey.isEmpty || apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      if (kDebugMode) {
        print('Invalid API key provided');
      }
      return false;
    }

    try {
      final systemInstruction = Content.system("""
أنت مساعد عقاري متخصص وودود. مهمتك هي مساعدة المستخدمين في العثور على العقارات المناسبة لهم.

قواعد مهمة:
1. استند فقط على بيانات العقارات المقدمة لك مع كل سؤال
2. لا تخترع أي معلومات أو أرقام
3. إذا لم تجد المعلومة في البيانات، قل "ليس لدي معلومات حول هذا في البيانات المتاحة"
4. كن ودودًا ومفيدًا في إجاباتك
5. اجعل إجاباتك مختصرة وواضحة
6. استخدم الأرقام والتفاصيل الدقيقة من البيانات
7. اقترح عقارات بديلة إذا لم تجد ما يطلبه المستخدم بالضبط

أمثلة على الأسئلة التي يمكنك الإجابة عليها:
- "أريد شقة للإيجار في الرياض"
- "ما هي أرخص الفلل المتاحة؟"
- "أبحث عن عقار مفروش"
- "كم عدد الغرف في العقار رقم 5؟"
""");

      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
        systemInstruction: systemInstruction,
      );

      _chat = _model!.startChat();
      _isInitialized = true;

      if (kDebugMode) {
        print('AI Service initialized successfully');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize AI service: $e');
      }
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  void updateProperties(List<Property> properties) {
    _properties = List.from(properties);
    notifyListeners();

    if (kDebugMode) {
      print('Properties updated: ${_properties.length} properties loaded');
    }
  }

  Future<String> processUserMessage(String userMessage) async {
    if (!_isInitialized || _chat == null) {
      return "الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.";
    }

    if (_properties.isEmpty) {
      return AppConstants.noDataMessage;
    }

    if (userMessage.trim().isEmpty) {
      return "يرجى كتابة سؤالك أو طلبك.";
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final propertyContext = _buildPropertyContext();
      final fullPrompt = _buildFullPrompt(userMessage, propertyContext);

      final response = await _chat!.sendMessage(Content.text(fullPrompt));
      final responseText = response.text;

      _isProcessing = false;
      notifyListeners();

      if (responseText == null || responseText.trim().isEmpty) {
        return "لم أتمكن من إنشاء رد مناسب. يرجى إعادة صياغة السؤال.";
      }

      return responseText.trim();
    } catch (e) {
      _isProcessing = false;
      notifyListeners();

      if (kDebugMode) {
        print('Error processing message: $e');
      }

      if (e.toString().contains('quota') || e.toString().contains('limit')) {
        return "تم تجاوز حد الاستخدام المسموح. يرجى المحاولة لاحقاً.";
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return "مشكلة في الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.";
      } else {
        return "حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.";
      }
    }
  }

  String _buildPropertyContext() {
    if (_properties.isEmpty) return "";

    final buffer = StringBuffer();
    buffer.writeln("قائمة العقارات المتاحة:");
    buffer.writeln();

    for (final property in _properties) {
      buffer.writeln("العقار رقم ${property.adNumber}:");
      buffer.writeln("- العنوان: ${property.title}");
      buffer.writeln("- الوصف: ${property.description}");
      buffer.writeln("- السعر: ${property.price}");
      buffer.writeln("- الموقع: ${property.location}");
      buffer.writeln("- نوع الإعلان: ${property.adType}");
      buffer.writeln("- نوع العقار: ${property.type}");
      buffer.writeln("- الحالة: ${property.status}");
      buffer.writeln("- عدد الغرف: ${property.rooms}");
      buffer.writeln("- عدد الحمامات: ${property.bathrooms}");
      buffer.writeln("- الفرش: ${property.furnishing}");
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _buildFullPrompt(String userMessage, String propertyContext) {
    return """
$propertyContext

سؤال المستخدم: "$userMessage"

يرجى الإجابة على سؤال المستخدم بناءً على بيانات العقارات المذكورة أعلاه فقط.
إذا كان السؤال يتطلب معلومات غير متوفرة في البيانات، أخبر المستخدم بذلك بوضوح.
اجعل إجابتك مفيدة ومختصرة وودودة.
""";
  }

  Future<void> resetChat() async {
    if (_model != null) {
      _chat = _model!.startChat();
      notifyListeners();
    }
  }

  String getWelcomeMessage() {
    if (!_isInitialized) {
      return "مرحباً! أحتاج إلى إعداد الخدمة أولاً.";
    }

    if (_properties.isEmpty) {
      return "مرحباً! يرجى تحميل بيانات العقارات أولاً لأتمكن من مساعدتك.";
    }

    return "مرحباً! أنا مساعدك العقاري الذكي. لدي معلومات عن ${_properties.length} عقار. كيف يمكنني مساعدتك؟";
  }

  List<String> getSuggestedQuestions() {
    if (_properties.isEmpty) {
      return ["كيف يمكنني تحميل بيانات العقارات؟", "ما هي الخدمات المتاحة؟"];
    }

    return [
      "أريد شقة للإيجار",
      "ما هي أرخص العقارات المتاحة؟",
      "أبحث عن فيلا مفروشة",
      "أريد عقار في موقع معين",
      "كم عدد العقارات المتاحة؟",
    ];
  }

  @override
  void dispose() {
    _chat = null;
    _model = null;
    _properties.clear();
    super.dispose();
  }
}
