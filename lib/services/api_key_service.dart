import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService extends ChangeNotifier {
  static const String _apiKeyKey = 'gemini_api_key';
  static const String _hasSetupKey = 'has_completed_api_setup';
  
  static ApiKeyService? _instance;
  static ApiKeyService get instance {
    _instance ??= ApiKeyService._internal();
    return _instance!;
  }
  
  ApiKeyService._internal();
  
  String? _apiKey;
  bool _hasCompletedSetup = false;
  bool _isLoading = false;
  
  String? get apiKey => _apiKey;
  bool get hasCompletedSetup => _hasCompletedSetup;
  bool get isLoading => _isLoading;
  bool get hasValidApiKey => _apiKey != null && _apiKey!.isNotEmpty && _apiKey!.startsWith('AIza');
  
  /// Initialize the service and load saved API key
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_apiKeyKey);
      _hasCompletedSetup = prefs.getBool(_hasSetupKey) ?? false;
      
      // If we have an API key but haven't completed setup, mark as completed
      if (_apiKey != null && _apiKey!.isNotEmpty && !_hasCompletedSetup) {
        _hasCompletedSetup = true;
        await prefs.setBool(_hasSetupKey, true);
      }
    } catch (e) {
      debugPrint('Error loading API key: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Save API key to storage
  Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      await prefs.setBool(_hasSetupKey, true);
      
      _apiKey = apiKey;
      _hasCompletedSetup = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error saving API key: $e');
      return false;
    }
  }
  
  /// Update API key (for settings/changes)
  Future<bool> updateApiKey(String apiKey) async {
    return await saveApiKey(apiKey);
  }
  
  /// Clear API key and reset setup
  Future<void> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
      await prefs.setBool(_hasSetupKey, false);
      
      _apiKey = null;
      _hasCompletedSetup = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing API key: $e');
    }
  }
  
  /// Validate API key format
  static bool isValidApiKeyFormat(String apiKey) {
    return apiKey.trim().isNotEmpty && 
           apiKey.trim().startsWith('AIza') && 
           apiKey.trim().length > 20;
  }
  
  /// Get API key for services (throws if not available)
  String getApiKeyForService() {
    if (!hasValidApiKey) {
      throw Exception('API key not configured. Please set up your Gemini API key.');
    }
    return _apiKey!;
  }
  
  /// Check if API key is available for services
  bool isApiKeyAvailable() {
    return hasValidApiKey;
  }
  
  /// Mark setup as completed (for onboarding flow)
  Future<void> markSetupCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSetupKey, true);
      _hasCompletedSetup = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking setup completed: $e');
    }
  }
  
  /// Reset setup (for testing or re-onboarding)
  Future<void> resetSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSetupKey, false);
      _hasCompletedSetup = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting setup: $e');
    }
  }
}
