import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/property_model.dart';
import '../api_key_service.dart';

class GeminiService {
  // Convenience method using global API key
  static Future<void> runChatWithGlobalKey({
    required Property property,
    required String question,
    required Function(String) onChunk,
  }) async {
    final apiKey = ApiKeyService.instance.getApiKeyForService();
    await runChat(
      apiKey: apiKey,
      property: property,
      question: question,
      onChunk: onChunk,
    );
  }

  static Future<void> runChat({
    required String apiKey,
    required Property property,
    required String question,
    required Function(String) onChunk,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is required.');
    }

    if (!apiKey.startsWith('AIza')) {
      throw Exception(
        'Invalid API Key format. Gemini API keys should start with "AIza".',
      );
    }

    final prompt = _buildSinglePropertyPrompt(property, question);
    await _generateResponse(apiKey, prompt, onChunk);
  }

  // Convenience method using global API key
  static Future<void> runMultiPropertyChatWithGlobalKey({
    required List<Property> properties,
    required String question,
    required Function(String) onChunk,
  }) async {
    final apiKey = ApiKeyService.instance.getApiKeyForService();
    await runMultiPropertyChat(
      apiKey: apiKey,
      properties: properties,
      question: question,
      onChunk: onChunk,
    );
  }

  static Future<void> runMultiPropertyChat({
    required String apiKey,
    required List<Property> properties,
    required String question,
    required Function(String) onChunk,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is required.');
    }

    if (!apiKey.startsWith('AIza')) {
      throw Exception(
        'Invalid API Key format. Gemini API keys should start with "AIza".',
      );
    }

    final prompt = _buildMultiPropertyPrompt(properties, question);
    await _generateResponse(apiKey, prompt, onChunk);
  }

  // Convenience method using global API key
  static Future<void> testGlobalApiKey({
    required Function(String) onChunk,
  }) async {
    final apiKey = ApiKeyService.instance.getApiKeyForService();
    await testApiKey(apiKey: apiKey, onChunk: onChunk);
  }

  static Future<void> testApiKey({
    required String apiKey,
    required Function(String) onChunk,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is required.');
    }

    if (!apiKey.startsWith('AIza')) {
      throw Exception(
        'Invalid API Key format. Gemini API keys should start with "AIza".',
      );
    }

    const testPrompt =
        'Hello! Please respond with "API key is working correctly" to confirm the connection.';
    await _generateResponse(apiKey, testPrompt, onChunk);
  }

  static Future<void> _generateResponse(
    String apiKey,
    String prompt,
    Function(String) onChunk,
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 1,
          topP: 1,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      final content = [Content.text(prompt)];
      final response = model.generateContentStream(content);

      bool hasReceivedData = false;
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          hasReceivedData = true;
          onChunk(text);
        }
      }

      if (!hasReceivedData) {
        onChunk(
          'I apologize, but I didn\'t receive a response. Please check your API key and try again.',
        );
      }
    } on GenerativeAIException catch (e) {
      String errorMessage = 'Sorry, I encountered an error: ';

      final errorString = e.toString();
      if (errorString.contains('API_KEY_INVALID') ||
          errorString.contains('invalid API key')) {
        errorMessage += 'Invalid API key. Please check your API key.';
      } else if (errorString.contains('quota') ||
          errorString.contains('QUOTA_EXCEEDED')) {
        errorMessage += 'API quota exceeded. Please try again later.';
      } else if (errorString.contains('blocked') ||
          errorString.contains('SAFETY')) {
        errorMessage +=
            'Content was blocked by safety filters. Please try rephrasing your question.';
      } else if (errorString.contains('403')) {
        errorMessage +=
            'Access denied. Your API key may not have the required permissions.';
      } else if (errorString.contains('429')) {
        errorMessage +=
            'Too many requests. Please wait a moment and try again.';
      } else if (errorString.contains('location') ||
          errorString.contains('region')) {
        errorMessage += 'Gemini API is not available in your location.';
      } else {
        errorMessage += e.message;
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to generate content: $e');
    }
  }

  static String _buildSinglePropertyPrompt(Property property, String question) {
    return '''You are a helpful and friendly real estate assistant called 'Casa AI' for a platform called 'Aqar Zone'. You are talking to a potential buyer about a property. Your goal is to answer their questions accurately based on the information provided and encourage them to consider the property. Be conversational and professional.

IMPORTANT: Always respond in the same language as the user's question. If the user asks in Arabic, respond in Arabic. If the user asks in English, respond in English. Match the user's language exactly.

Property Details:
- Title: ${property.title}
- Description: ${property.description}
- Price: ${property.formattedPrice}
- Type: ${property.type} for ${property.adType}
- Location: ${property.location}
- Size: ${property.area} m²
- Rooms: ${property.bedroomsDisplay}
- Bathrooms: ${property.bathrooms}

The user's question is: "$question"

Please answer the user's question in the same language they used. If the information is not available in the details provided, politely state that you don't have that specific information but you can answer other questions.''';
  }

  static String _buildMultiPropertyPrompt(
    List<Property> properties,
    String question,
  ) {
    final propertiesData = properties
        .take(5)
        .map(
          (property) => '''
Property ID: ${property.adNumber}
Title: ${property.title}
Price: ${property.formattedPrice}
Type: ${property.type} for ${property.adType}
Location: ${property.location}
Size: ${property.area} m²
Rooms: ${property.bedroomsDisplay}
Bathrooms: ${property.bathrooms}
''',
        )
        .join('\n---\n');

    return '''You are a helpful and friendly real estate assistant called 'Casa AI' for a platform called 'Aqar Zone'. You are talking to a potential buyer about properties on our platform. Your goal is to answer their questions based on the available property listings and help them find suitable options.

IMPORTANT: Always respond in the same language as the user's question. If the user asks in Arabic, respond in Arabic. If the user asks in English, respond in English. Match the user's language exactly.

Here are some of our current property listings:

$propertiesData

The user's question is: "$question"

Please answer the user's question in the same language they used. If they're asking about specific properties, reference the relevant listings by ID or title. If they're asking general questions about real estate, provide helpful information based on your knowledge. If they're looking for properties with specific features, recommend suitable options from the listings provided.''';
  }

  // BLoC compatibility methods

  /// Validate API key by making a simple test request
  Future<bool> validateApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty || !apiKey.startsWith('AIza')) {
        return false;
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      // Make a simple test request
      final response = await model.generateContent([
        Content.text(
          'Hello, this is a test. Please respond with "API key is valid".',
        ),
      ]);

      return response.text?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }

  /// Test connection with detailed results
  Future<Map<String, dynamic>> testConnection(String apiKey) async {
    try {
      if (apiKey.isEmpty || !apiKey.startsWith('AIza')) {
        return {
          'success': false,
          'error': 'Invalid API key format',
          'details': 'API key must start with "AIza"',
        };
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      final startTime = DateTime.now();

      // Make a test request
      final response = await model.generateContent([
        Content.text('Test connection. Respond with "Connection successful".'),
      ]);

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;

      if (response.text?.isNotEmpty == true) {
        return {
          'success': true,
          'responseTime': responseTime,
          'model': 'gemini-pro',
          'response': response.text,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'error': 'Empty response from API',
          'responseTime': responseTime,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
