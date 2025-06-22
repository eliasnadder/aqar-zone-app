import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property.dart';
import 'gemini_service.dart';
import 'api_key_service.dart';

class AISuggestionsService {
  static const String _suggestionsKey = 'ai_suggestions_';
  static const String _lastUpdateKey = 'suggestions_last_update_';
  static const Duration _refreshInterval = Duration(
    days: 2,
    hours: 12,
  ); // 2.5 days

  /// Generate AI-powered suggestions using global API key
  static Future<List<String>> generateSuggestionsWithGlobalKey({
    required Property property,
  }) async {
    if (!ApiKeyService.instance.isApiKeyAvailable()) {
      return getFallbackSuggestions(property);
    }

    final apiKey = ApiKeyService.instance.getApiKeyForService();
    return await generateSuggestions(apiKey: apiKey, property: property);
  }

  /// Get cached suggestions using global API key
  static Future<List<String>> getCachedSuggestionsWithGlobalKey({
    required Property property,
  }) async {
    if (!ApiKeyService.instance.isApiKeyAvailable()) {
      return getFallbackSuggestions(property);
    }

    final apiKey = ApiKeyService.instance.getApiKeyForService();
    return await getCachedSuggestions(apiKey: apiKey, property: property);
  }

  /// Refresh suggestions using global API key
  static Future<List<String>> refreshSuggestionsWithGlobalKey({
    required Property property,
  }) async {
    if (!ApiKeyService.instance.isApiKeyAvailable()) {
      return getFallbackSuggestions(property);
    }

    final apiKey = ApiKeyService.instance.getApiKeyForService();
    return await refreshSuggestions(apiKey: apiKey, property: property);
  }

  /// Generate AI-powered suggestions for a property
  static Future<List<String>> generateSuggestions({
    required String apiKey,
    required Property property,
  }) async {
    if (apiKey.isEmpty) {
      return getFallbackSuggestions(property);
    }

    try {
      final prompt = _buildSuggestionsPrompt(property);
      String response = '';

      await GeminiService.runChat(
        apiKey: apiKey,
        property: property,
        question: prompt,
        onChunk: (chunk) {
          response += chunk;
        },
      );

      if (response.isNotEmpty) {
        return _parseSuggestions(response);
      }
    } catch (e) {
      // Log error in production, use proper logging framework
      debugPrint('Error generating AI suggestions: $e');
    }

    return getFallbackSuggestions(property);
  }

  /// Get cached suggestions or generate new ones if needed
  static Future<List<String>> getCachedSuggestions({
    required String apiKey,
    required Property property,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _suggestionsKey + property.id.toString();
    final updateKey = _lastUpdateKey + property.id.toString();

    // Check if we have cached suggestions
    final cachedSuggestions = prefs.getStringList(cacheKey);
    final lastUpdate = prefs.getInt(updateKey);

    if (cachedSuggestions != null && lastUpdate != null) {
      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();

      // Check if suggestions are still fresh
      if (now.difference(lastUpdateTime) < _refreshInterval) {
        return cachedSuggestions;
      }
    }

    // Generate new suggestions
    final newSuggestions = await generateSuggestions(
      apiKey: apiKey,
      property: property,
    );

    // Cache the new suggestions
    await prefs.setStringList(cacheKey, newSuggestions);
    await prefs.setInt(updateKey, DateTime.now().millisecondsSinceEpoch);

    return newSuggestions;
  }

  /// Force refresh suggestions for a property
  static Future<List<String>> refreshSuggestions({
    required String apiKey,
    required Property property,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _suggestionsKey + property.id.toString();
    final updateKey = _lastUpdateKey + property.id.toString();

    // Clear existing cache
    await prefs.remove(cacheKey);
    await prefs.remove(updateKey);

    // Generate new suggestions
    return await getCachedSuggestions(apiKey: apiKey, property: property);
  }

  /// Check if suggestions need refresh
  static Future<bool> needsRefresh(Property property) async {
    final prefs = await SharedPreferences.getInstance();
    final updateKey = _lastUpdateKey + property.id.toString();
    final lastUpdate = prefs.getInt(updateKey);

    if (lastUpdate == null) return true;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();

    return now.difference(lastUpdateTime) >= _refreshInterval;
  }

  /// Get time until next refresh
  static Future<Duration?> getTimeUntilRefresh(Property property) async {
    final prefs = await SharedPreferences.getInstance();
    final updateKey = _lastUpdateKey + property.id.toString();
    final lastUpdate = prefs.getInt(updateKey);

    if (lastUpdate == null) return null;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final nextRefresh = lastUpdateTime.add(_refreshInterval);
    final now = DateTime.now();

    if (now.isAfter(nextRefresh)) return Duration.zero;

    return nextRefresh.difference(now);
  }

  static String _buildSuggestionsPrompt(Property property) {
    return '''Generate exactly 4 short, engaging questions that a potential buyer might ask about this property. Make them specific to the property details provided and focus on practical concerns buyers typically have.

Property Details:
- Title: ${property.title}
- Type: ${property.type} for ${property.adType}
- Price: ${property.price} ${property.currency}
- Location: ${property.locationString}
- Size: ${property.area ?? 'N/A'} m²
- Bedrooms: ${property.bedroomsDisplay}
- Bathrooms: ${property.bathrooms ?? 'N/A'}

Requirements:
1. Each question should be 3-8 words maximum
2. Focus on location, amenities, investment potential, or practical concerns
3. Make them sound natural and conversational
4. Avoid repeating information already visible
5. Format as a simple list, one question per line
6. No numbering, bullets, or extra formatting

Example format:
What's the neighborhood like?
Are there good schools nearby?
Is parking included?
What's the investment potential?''';
  }

  static List<String> _parseSuggestions(String response) {
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
                  line.toLowerCase().contains('is') ||
                  line.toLowerCase().contains('are') ||
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
                      line.toLowerCase().startsWith('is') ||
                      line.toLowerCase().startsWith('are') ||
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

  static List<String> getFallbackSuggestions(Property property) {
    final suggestions = <String>[];

    // Add property-specific suggestions based on type and details
    if (property.type.toLowerCase().contains('villa') ||
        property.type.toLowerCase().contains('house')) {
      suggestions.addAll([
        'What\'s the neighborhood like?',
        'Is there a garden or outdoor space?',
        'Are there good schools nearby?',
        'What\'s the parking situation?',
      ]);
    } else if (property.type.toLowerCase().contains('apartment') ||
        property.type.toLowerCase().contains('flat')) {
      suggestions.addAll([
        'What floor is it on?',
        'Are there building amenities?',
        'Is parking included?',
        'What\'s the view like?',
      ]);
    } else {
      suggestions.addAll([
        'Tell me about the location',
        'What are the nearby amenities?',
        'Is this a good investment?',
        'What\'s the neighborhood like?',
      ]);
    }

    return suggestions.take(4).toList();
  }
}
