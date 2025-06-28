import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/property_model.dart';
import 'gemini_service.dart';
import '../api_key_service.dart';

class GlobalAISuggestionsService {
  static const String _globalSuggestionsKey = 'global_ai_suggestions';
  static const String _globalLastUpdateKey = 'global_suggestions_last_update';
  static const Duration _refreshInterval = Duration(
    days: 2,
    hours: 12,
  ); // 2.5 days

  /// Generate AI-powered suggestions for multiple properties using global API key
  static Future<List<String>> generateGlobalSuggestionsWithGlobalKey({
    required List<Property> properties,
  }) async {
    if (!ApiKeyService.instance.isApiKeyAvailable()) {
      return getGlobalFallbackSuggestions(properties);
    }

    final apiKey = ApiKeyService.instance.getApiKeyForService();
    return await generateGlobalSuggestions(
      apiKey: apiKey,
      properties: properties,
    );
  }

  /// Get cached global suggestions using global API key
  static Future<List<String>> getCachedGlobalSuggestionsWithGlobalKey({
    required List<Property> properties,
  }) async {
    if (!ApiKeyService.instance.isApiKeyAvailable()) {
      return getGlobalFallbackSuggestions(properties);
    }

    final apiKey = ApiKeyService.instance.getApiKeyForService();
    return await getCachedGlobalSuggestions(
      apiKey: apiKey,
      properties: properties,
    );
  }

  /// Refresh global suggestions using global API key
  static Future<List<String>> refreshGlobalSuggestionsWithGlobalKey({
    required List<Property> properties,
  }) async {
    if (!ApiKeyService.instance.isApiKeyAvailable()) {
      return getGlobalFallbackSuggestions(properties);
    }

    final apiKey = ApiKeyService.instance.getApiKeyForService();
    return await refreshGlobalSuggestions(
      apiKey: apiKey,
      properties: properties,
    );
  }

  /// Generate AI-powered suggestions for multiple properties
  static Future<List<String>> generateGlobalSuggestions({
    required String apiKey,
    required List<Property> properties,
  }) async {
    if (apiKey.isEmpty || properties.isEmpty) {
      return getGlobalFallbackSuggestions(properties);
    }

    try {
      final prompt = _buildGlobalSuggestionsPrompt(properties);
      String response = '';

      await GeminiService.runMultiPropertyChat(
        apiKey: apiKey,
        properties: properties,
        question: prompt,
        onChunk: (chunk) {
          response += chunk;
        },
      );

      if (response.isNotEmpty) {
        return _parseGlobalSuggestions(response);
      }
    } catch (e) {
      debugPrint('Error generating global AI suggestions: $e');
    }

    return getGlobalFallbackSuggestions(properties);
  }

  /// Get cached global suggestions or generate new ones if needed
  static Future<List<String>> getCachedGlobalSuggestions({
    required String apiKey,
    required List<Property> properties,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have cached suggestions
    final cachedSuggestions = prefs.getStringList(_globalSuggestionsKey);
    final lastUpdate = prefs.getInt(_globalLastUpdateKey);

    if (cachedSuggestions != null && lastUpdate != null) {
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();

      // Check if suggestions are still fresh
      if (now.difference(lastUpdateTime) < _refreshInterval) {
        return cachedSuggestions;
      }
    }

    // Generate new suggestions
    final newSuggestions = await generateGlobalSuggestions(
      apiKey: apiKey,
      properties: properties,
    );

    // Cache the new suggestions
    await prefs.setStringList(_globalSuggestionsKey, newSuggestions);
    await prefs.setInt(
      _globalLastUpdateKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    return newSuggestions;
  }

  /// Force refresh global suggestions
  static Future<List<String>> refreshGlobalSuggestions({
    required String apiKey,
    required List<Property> properties,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear existing cache
    await prefs.remove(_globalSuggestionsKey);
    await prefs.remove(_globalLastUpdateKey);

    // Generate new suggestions
    return await getCachedGlobalSuggestions(
      apiKey: apiKey,
      properties: properties,
    );
  }

  /// Check if global suggestions need refresh
  static Future<bool> needsRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_globalLastUpdateKey);

    if (lastUpdate == null) return true;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();

    return now.difference(lastUpdateTime) >= _refreshInterval;
  }

  /// Get time until next refresh
  static Future<Duration?> getTimeUntilRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_globalLastUpdateKey);

    if (lastUpdate == null) return null;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final nextRefresh = lastUpdateTime.add(_refreshInterval);
    final now = DateTime.now();

    if (now.isAfter(nextRefresh)) return Duration.zero;

    return nextRefresh.difference(now);
  }

  static String _buildGlobalSuggestionsPrompt(List<Property> properties) {
    final propertyTypes = properties.map((p) => p.type).toSet().toList();
    final priceRange = _getFormattedPriceRange(properties);
    final locations =
        properties.map((p) => p.location).toSet().take(5).toList();

    return '''Generate exactly 4 short, engaging questions that a potential buyer might ask about our property portfolio. Make them general but relevant to the types of properties we have available.

Our Property Portfolio:
- Total Properties: ${properties.length}
- Property Types: ${propertyTypes.join(', ')}
- Price Range: ${priceRange['min']} - ${priceRange['max']}
- Key Locations: ${locations.join(', ')}

Requirements:
1. Each question should be 3-8 words maximum
2. Focus on general property search, investment, or market questions
3. Make them sound natural and conversational
4. Avoid being too specific to one property
5. Format as a simple list, one question per line
6. No numbering, bullets, or extra formatting

Example format:
What's the best investment property?
Show me properties under \$500K
Which areas have the best value?
Are there any luxury options?''';
  }

  static Map<String, String> _getFormattedPriceRange(
    List<Property> properties,
  ) {
    if (properties.isEmpty) {
      return {'min': '0 USD', 'max': '0 USD'};
    }

    final prices = properties.map((p) => p.price).toList();
    prices.sort();

    // Use a consistent currency for the range (USD as default)
    const currency = 'USD';
    final minFormatted = Property.formatPrice(prices.first, currency);
    final maxFormatted = Property.formatPrice(prices.last, currency);

    return {'min': minFormatted, 'max': maxFormatted};
  }

  static List<String> _parseGlobalSuggestions(String response) {
    // Clean and split the response
    final lines =
        response
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty && !line.startsWith('#'))
            .where(
              (line) => line.length > 5 && line.length < 60,
            ) // Reasonable length
            .where(
              (line) =>
                  line.contains('?') ||
                  line.toLowerCase().contains('what') ||
                  line.toLowerCase().contains('how') ||
                  line.toLowerCase().contains('show') ||
                  line.toLowerCase().contains('find') ||
                  line.toLowerCase().contains('tell'),
            )
            .take(4)
            .toList();

    // Clean up each suggestion
    final suggestions =
        lines
            .map((line) {
              // Remove common prefixes and clean up
              line = line.replaceAll(
                RegExp(r'^\d+\.?\s*'),
                '',
              ); // Remove numbering
              line = line.replaceAll(
                RegExp(r'^[-•*]\s*'),
                '',
              ); // Remove bullets
              line = line.trim();

              // Ensure it ends with a question mark if it's a question
              if ((line.toLowerCase().startsWith('what') ||
                      line.toLowerCase().startsWith('how') ||
                      line.toLowerCase().startsWith('show') ||
                      line.toLowerCase().startsWith('find') ||
                      line.toLowerCase().startsWith('tell')) &&
                  !line.endsWith('?')) {
                line += '?';
              }

              return line;
            })
            .where((line) => line.length > 5)
            .toList();

    // Return suggestions or fallback if not enough
    return suggestions.length >= 2 ? suggestions : [];
  }

  static List<String> getGlobalFallbackSuggestions(List<Property> properties) {
    final suggestions = <String>[];

    if (properties.isEmpty) {
      return [
        'What properties do you have?',
        'Tell me about your services',
        'How can I search for properties?',
        'What areas do you cover?',
      ];
    }

    // Analyze property types
    final hasVillas = properties.any(
      (p) => p.type.toLowerCase().contains('villa'),
    );
    final hasApartments = properties.any(
      (p) => p.type.toLowerCase().contains('apartment'),
    );
    final hasCommercial = properties.any(
      (p) => p.type.toLowerCase().contains('commercial'),
    );

    // Add type-specific suggestions
    if (hasVillas) {
      suggestions.add('Show me luxury villas');
    }
    if (hasApartments) {
      suggestions.add('Find me a modern apartment');
    }
    if (hasCommercial) {
      suggestions.add('What commercial properties available?');
    }

    // Add general suggestions
    suggestions.addAll([
      'What\'s the best investment option?',
      'Show me properties under \$500K',
      'Which areas have good value?',
      'Tell me about financing options',
    ]);

    return suggestions.take(4).toList();
  }
}
