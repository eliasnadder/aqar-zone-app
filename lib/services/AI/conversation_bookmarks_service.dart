import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message_model.dart';
import '../../models/property_model.dart';

class ConversationBookmarksService extends ChangeNotifier {
  final List<ConversationBookmark> _bookmarks = [];
  final List<ConversationSession> _sessions = [];
  
  ConversationSession? _currentSession;
  int _nextBookmarkId = 1;
  int _nextSessionId = 1;
  
  // Getters
  List<ConversationBookmark> get bookmarks => List.unmodifiable(_bookmarks);
  List<ConversationSession> get sessions => List.unmodifiable(_sessions);
  ConversationSession? get currentSession => _currentSession;
  
  Future<void> initialize() async {
    await _loadBookmarks();
    await _loadSessions();
    _startNewSession();
  }
  
  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString('conversation_bookmarks');
      
      if (bookmarksJson != null) {
        final List<dynamic> bookmarksList = jsonDecode(bookmarksJson);
        _bookmarks.clear();
        
        for (final bookmarkData in bookmarksList) {
          _bookmarks.add(ConversationBookmark.fromJson(bookmarkData));
        }
        
        // Update next ID
        if (_bookmarks.isNotEmpty) {
          _nextBookmarkId = _bookmarks.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bookmarks: $e');
      }
    }
  }
  
  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('conversation_sessions');
      
      if (sessionsJson != null) {
        final List<dynamic> sessionsList = jsonDecode(sessionsJson);
        _sessions.clear();
        
        for (final sessionData in sessionsList) {
          _sessions.add(ConversationSession.fromJson(sessionData));
        }
        
        // Update next ID
        if (_sessions.isNotEmpty) {
          _nextSessionId = _sessions.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sessions: $e');
      }
    }
  }
  
  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString('conversation_bookmarks', bookmarksJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving bookmarks: $e');
      }
    }
  }
  
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString('conversation_sessions', sessionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving sessions: $e');
      }
    }
  }
  
  // Session management
  void _startNewSession() {
    _currentSession = ConversationSession(
      id: _nextSessionId++,
      startTime: DateTime.now(),
      title: 'محادثة ${DateTime.now().day}/${DateTime.now().month}',
      messages: [],
      bookmarks: [],
      properties: [],
    );
    
    _sessions.insert(0, _currentSession!);
    _saveSessions();
    notifyListeners();
  }
  
  void endCurrentSession() {
    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now();
      _saveSessions();
      _currentSession = null;
      notifyListeners();
    }
  }
  
  void addMessageToCurrentSession(ChatMessage message) {
    if (_currentSession != null) {
      _currentSession!.messages.add(message);
      _saveSessions();
      notifyListeners();
    }
  }
  
  void addPropertyToCurrentSession(Property property) {
    if (_currentSession != null && 
        !_currentSession!.properties.any((p) => p.id == property.id)) {
      _currentSession!.properties.add(property);
      _saveSessions();
      notifyListeners();
    }
  }
  
  // Bookmark management
  ConversationBookmark addBookmark({
    required String text,
    required String context,
    String? propertyId,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    final bookmark = ConversationBookmark(
      id: _nextBookmarkId++,
      text: text,
      context: context,
      timestamp: DateTime.now(),
      sessionId: _currentSession?.id,
      propertyId: propertyId,
      category: category ?? 'general',
      metadata: metadata ?? {},
    );
    
    _bookmarks.insert(0, bookmark);
    
    // Add to current session
    if (_currentSession != null) {
      _currentSession!.bookmarks.add(bookmark);
    }
    
    _saveBookmarks();
    _saveSessions();
    notifyListeners();
    
    return bookmark;
  }
  
  void removeBookmark(int bookmarkId) {
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
    
    // Remove from all sessions
    for (final session in _sessions) {
      session.bookmarks.removeWhere((b) => b.id == bookmarkId);
    }
    
    _saveBookmarks();
    _saveSessions();
    notifyListeners();
  }
  
  void updateBookmark(int bookmarkId, {
    String? text,
    String? context,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    final bookmarkIndex = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (bookmarkIndex != -1) {
      final bookmark = _bookmarks[bookmarkIndex];
      
      _bookmarks[bookmarkIndex] = ConversationBookmark(
        id: bookmark.id,
        text: text ?? bookmark.text,
        context: context ?? bookmark.context,
        timestamp: bookmark.timestamp,
        sessionId: bookmark.sessionId,
        propertyId: bookmark.propertyId,
        category: category ?? bookmark.category,
        metadata: metadata ?? bookmark.metadata,
      );
      
      _saveBookmarks();
      notifyListeners();
    }
  }
  
  // Search and filter
  List<ConversationBookmark> searchBookmarks(String query) {
    final lowerQuery = query.toLowerCase();
    return _bookmarks.where((bookmark) {
      return bookmark.text.toLowerCase().contains(lowerQuery) ||
             bookmark.context.toLowerCase().contains(lowerQuery) ||
             bookmark.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  List<ConversationBookmark> getBookmarksByCategory(String category) {
    return _bookmarks.where((b) => b.category == category).toList();
  }
  
  List<ConversationBookmark> getBookmarksByProperty(String propertyId) {
    return _bookmarks.where((b) => b.propertyId == propertyId).toList();
  }
  
  List<ConversationBookmark> getBookmarksBySession(int sessionId) {
    return _bookmarks.where((b) => b.sessionId == sessionId).toList();
  }
  
  // Categories
  List<String> getBookmarkCategories() {
    final categories = _bookmarks.map((b) => b.category).toSet().toList();
    categories.sort();
    return categories;
  }
  
  // Session management
  void deleteSession(int sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    _bookmarks.removeWhere((b) => b.sessionId == sessionId);
    
    _saveSessions();
    _saveBookmarks();
    notifyListeners();
  }
  
  void renameSession(int sessionId, String newTitle) {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex].title = newTitle;
      _saveSessions();
      notifyListeners();
    }
  }
  
  ConversationSession? getSession(int sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }
  
  // Export functionality
  String exportBookmarksAsText() {
    final buffer = StringBuffer();
    buffer.writeln('العلامات المرجعية للمحادثة');
    buffer.writeln('تاريخ التصدير: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final category in getBookmarkCategories()) {
      final categoryBookmarks = getBookmarksByCategory(category);
      if (categoryBookmarks.isNotEmpty) {
        buffer.writeln('## $category');
        buffer.writeln();
        
        for (final bookmark in categoryBookmarks) {
          buffer.writeln('### ${bookmark.text}');
          buffer.writeln('التاريخ: ${bookmark.timestamp}');
          buffer.writeln('السياق: ${bookmark.context}');
          if (bookmark.propertyId != null) {
            buffer.writeln('العقار: ${bookmark.propertyId}');
          }
          buffer.writeln();
        }
      }
    }
    
    return buffer.toString();
  }
  
  Map<String, dynamic> exportBookmarksAsJson() {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'bookmarks': _bookmarks.map((b) => b.toJson()).toList(),
      'sessions': _sessions.map((s) => s.toJson()).toList(),
    };
  }
  
  // Statistics
  Map<String, dynamic> getBookmarkStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);
    
    return {
      'totalBookmarks': _bookmarks.length,
      'totalSessions': _sessions.length,
      'bookmarksToday': _bookmarks.where((b) => b.timestamp.isAfter(today)).length,
      'bookmarksThisWeek': _bookmarks.where((b) => b.timestamp.isAfter(thisWeek)).length,
      'bookmarksThisMonth': _bookmarks.where((b) => b.timestamp.isAfter(thisMonth)).length,
      'categoriesCount': getBookmarkCategories().length,
      'averageBookmarksPerSession': _sessions.isNotEmpty 
          ? (_bookmarks.length / _sessions.length).toStringAsFixed(1)
          : '0',
    };
  }
  
  // Clear all data
  void clearAllBookmarks() {
    _bookmarks.clear();
    _saveBookmarks();
    notifyListeners();
  }
  
  void clearAllSessions() {
    _sessions.clear();
    _currentSession = null;
    _saveSessions();
    notifyListeners();
  }
}

class ConversationBookmark {
  final int id;
  final String text;
  final String context;
  final DateTime timestamp;
  final int? sessionId;
  final String? propertyId;
  final String category;
  final Map<String, dynamic> metadata;
  
  ConversationBookmark({
    required this.id,
    required this.text,
    required this.context,
    required this.timestamp,
    this.sessionId,
    this.propertyId,
    required this.category,
    required this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'propertyId': propertyId,
      'category': category,
      'metadata': metadata,
    };
  }
  
  factory ConversationBookmark.fromJson(Map<String, dynamic> json) {
    return ConversationBookmark(
      id: json['id'],
      text: json['text'],
      context: json['context'],
      timestamp: DateTime.parse(json['timestamp']),
      sessionId: json['sessionId'],
      propertyId: json['propertyId'],
      category: json['category'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class ConversationSession {
  final int id;
  final DateTime startTime;
  DateTime? endTime;
  String title;
  final List<ChatMessage> messages;
  final List<ConversationBookmark> bookmarks;
  final List<Property> properties;
  
  ConversationSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.title,
    required this.messages,
    required this.bookmarks,
    required this.properties,
  });
  
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'properties': properties.map((p) => p.toJson()).toList(),
    };
  }
  
  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      title: json['title'],
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      bookmarks: (json['bookmarks'] as List? ?? [])
          .map((b) => ConversationBookmark.fromJson(b))
          .toList(),
      properties: (json['properties'] as List? ?? [])
          .map((p) => Property.fromJson(p))
          .toList(),
    );
  }
}
