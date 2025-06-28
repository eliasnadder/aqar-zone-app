import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'voice_settings_service.dart';

class EmotionDetectionService extends ChangeNotifier {
  EmotionState _currentEmotion = EmotionState.neutral;
  double _confidence = 0.0;
  final List<EmotionReading> _emotionHistory = [];

  // Audio analysis simulation
  double _averageVolume = 0.0;
  double _speechRate = 0.0;
  double _pitchVariation = 0.0;

  // Text analysis
  final Map<String, EmotionType> _emotionKeywords = {};

  // Getters
  EmotionState get currentEmotion => _currentEmotion;
  double get confidence => _confidence;
  List<EmotionReading> get emotionHistory => List.unmodifiable(_emotionHistory);
  double get averageVolume => _averageVolume;
  double get speechRate => _speechRate;
  double get pitchVariation => _pitchVariation;

  void initialize() {
    _setupEmotionKeywords();
  }

  void _setupEmotionKeywords() {
    // Positive emotions
    _emotionKeywords.addAll({
      'ممتاز': EmotionType.excited,
      'رائع': EmotionType.excited,
      'جميل': EmotionType.excited,
      'أحب': EmotionType.excited,
      'سعيد': EmotionType.excited,
      'فرحان': EmotionType.excited,
      'مبسوط': EmotionType.excited,
      'حلو': EmotionType.excited,
      'جيد': EmotionType.calm,
      'مناسب': EmotionType.calm,
      'موافق': EmotionType.calm,
      'نعم': EmotionType.calm,
      'طيب': EmotionType.calm,
      'تمام': EmotionType.calm,
    });

    // Negative emotions
    _emotionKeywords.addAll({
      'سيء': EmotionType.sad,
      'مشكلة': EmotionType.urgent,
      'صعب': EmotionType.urgent,
      'غالي': EmotionType.sad,
      'مكلف': EmotionType.sad,
      'لا أريد': EmotionType.sad,
      'مرفوض': EmotionType.urgent,
      'غير مناسب': EmotionType.sad,
      'زعلان': EmotionType.sad,
      'متضايق': EmotionType.sad,
      'مستعجل': EmotionType.urgent,
      'بسرعة': EmotionType.urgent,
      'عاجل': EmotionType.urgent,
    });

    // Neutral emotions
    _emotionKeywords.addAll({
      'عادي': EmotionType.neutral,
      'ممكن': EmotionType.neutral,
      'أفكر': EmotionType.neutral,
      'ربما': EmotionType.neutral,
      'لا أدري': EmotionType.neutral,
    });
  }

  // Analyze emotion from text
  EmotionState analyzeTextEmotion(String text) {
    final words = text.toLowerCase().split(' ');
    final emotionScores = <EmotionType, double>{
      EmotionType.excited: 0.0,
      EmotionType.calm: 0.0,
      EmotionType.neutral: 0.0,
      EmotionType.sad: 0.0,
      EmotionType.urgent: 0.0,
    };

    // Analyze keywords
    for (final word in words) {
      if (_emotionKeywords.containsKey(word)) {
        final emotion = _emotionKeywords[word]!;
        emotionScores[emotion] = emotionScores[emotion]! + 1.0;
      }
    }

    // Analyze punctuation and structure
    if (text.contains('!')) {
      emotionScores[EmotionType.excited] =
          emotionScores[EmotionType.excited]! + 0.5;
    }

    if (text.contains('؟؟') || text.contains('!!')) {
      emotionScores[EmotionType.urgent] =
          emotionScores[EmotionType.urgent]! + 0.5;
    }

    if (text.length > 100) {
      emotionScores[EmotionType.excited] =
          emotionScores[EmotionType.excited]! + 0.3;
    }

    // Determine dominant emotion
    final dominantEmotion = emotionScores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final totalScore = emotionScores.values.reduce((a, b) => a + b);
    final confidence =
        totalScore > 0 ? dominantEmotion.value / totalScore : 0.0;

    return EmotionState(
      emotion: dominantEmotion.key,
      confidence: confidence.clamp(0.0, 1.0),
      timestamp: DateTime.now(),
      source: EmotionSource.text,
    );
  }

  // Simulate audio emotion analysis
  EmotionState analyzeAudioEmotion({
    required double volume,
    required double speechRate,
    required double pitchVariation,
  }) {
    _averageVolume = volume;
    _speechRate = speechRate;
    _pitchVariation = pitchVariation;

    // Simple heuristic-based emotion detection
    EmotionType detectedEmotion = EmotionType.neutral;
    double confidence = 0.0;

    // High volume + fast speech + high pitch variation = excited
    if (volume > 0.7 && speechRate > 0.8 && pitchVariation > 0.6) {
      detectedEmotion = EmotionType.excited;
      confidence = 0.8;
    }
    // Low volume + slow speech + low pitch variation = sad
    else if (volume < 0.3 && speechRate < 0.4 && pitchVariation < 0.3) {
      detectedEmotion = EmotionType.sad;
      confidence = 0.7;
    }
    // High speech rate + high pitch = urgent
    else if (speechRate > 0.9 || pitchVariation > 0.8) {
      detectedEmotion = EmotionType.urgent;
      confidence = 0.6;
    }
    // Moderate values = calm
    else if (volume > 0.4 &&
        volume < 0.7 &&
        speechRate > 0.4 &&
        speechRate < 0.7) {
      detectedEmotion = EmotionType.calm;
      confidence = 0.5;
    }

    return EmotionState(
      emotion: detectedEmotion,
      confidence: confidence,
      timestamp: DateTime.now(),
      source: EmotionSource.audio,
    );
  }

  // Combined emotion analysis
  void analyzeEmotion({
    String? text,
    double? volume,
    double? speechRate,
    double? pitchVariation,
  }) {
    EmotionState? textEmotion;
    EmotionState? audioEmotion;

    // Analyze text if provided
    if (text != null && text.isNotEmpty) {
      textEmotion = analyzeTextEmotion(text);
    }

    // Analyze audio if provided
    if (volume != null && speechRate != null && pitchVariation != null) {
      audioEmotion = analyzeAudioEmotion(
        volume: volume,
        speechRate: speechRate,
        pitchVariation: pitchVariation,
      );
    }

    // Combine results
    EmotionState finalEmotion;

    if (textEmotion != null && audioEmotion != null) {
      // Weighted combination (text 60%, audio 40%)
      if (textEmotion.confidence > audioEmotion.confidence) {
        finalEmotion = textEmotion;
      } else {
        finalEmotion = audioEmotion;
      }

      // Adjust confidence based on agreement
      if (textEmotion.emotion == audioEmotion.emotion) {
        finalEmotion = EmotionState(
          emotion: textEmotion.emotion,
          confidence: min(
            1.0,
            (textEmotion.confidence + audioEmotion.confidence) / 2 + 0.2,
          ),
          timestamp: DateTime.now(),
          source: EmotionSource.combined,
        );
      }
    } else if (textEmotion != null) {
      finalEmotion = textEmotion;
    } else if (audioEmotion != null) {
      finalEmotion = audioEmotion;
    } else {
      finalEmotion = EmotionState(
        emotion: EmotionType.neutral,
        confidence: 0.0,
        timestamp: DateTime.now(),
        source: EmotionSource.unknown,
      );
    }

    _updateEmotion(finalEmotion);
  }

  void _updateEmotion(EmotionState emotion) {
    _currentEmotion = emotion;
    _confidence = emotion.confidence;

    // Add to history
    _emotionHistory.add(
      EmotionReading(
        emotion: emotion.emotion,
        confidence: emotion.confidence,
        timestamp: emotion.timestamp,
        source: emotion.source,
      ),
    );

    // Keep only last 50 readings
    if (_emotionHistory.length > 50) {
      _emotionHistory.removeAt(0);
    }

    notifyListeners();
  }

  // Get emotion trend over time
  EmotionTrend getEmotionTrend({Duration? period}) {
    final cutoffTime =
        period != null
            ? DateTime.now().subtract(period)
            : DateTime.now().subtract(const Duration(minutes: 10));

    final recentEmotions =
        _emotionHistory
            .where((reading) => reading.timestamp.isAfter(cutoffTime))
            .toList();

    if (recentEmotions.isEmpty) {
      return EmotionTrend(
        dominantEmotion: EmotionType.neutral,
        averageConfidence: 0.0,
        emotionCounts: {},
        trend: TrendDirection.stable,
      );
    }

    // Count emotions
    final emotionCounts = <EmotionType, int>{};
    double totalConfidence = 0.0;

    for (final reading in recentEmotions) {
      emotionCounts[reading.emotion] =
          (emotionCounts[reading.emotion] ?? 0) + 1;
      totalConfidence += reading.confidence;
    }

    // Find dominant emotion
    final dominantEmotion =
        emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Calculate trend
    final trend = _calculateTrend(recentEmotions);

    return EmotionTrend(
      dominantEmotion: dominantEmotion,
      averageConfidence: totalConfidence / recentEmotions.length,
      emotionCounts: emotionCounts,
      trend: trend,
    );
  }

  TrendDirection _calculateTrend(List<EmotionReading> emotions) {
    if (emotions.length < 3) return TrendDirection.stable;

    final firstHalf = emotions.take(emotions.length ~/ 2);
    final secondHalf = emotions.skip(emotions.length ~/ 2);

    final firstAvgConfidence =
        firstHalf.map((e) => e.confidence).reduce((a, b) => a + b) /
        firstHalf.length;
    final secondAvgConfidence =
        secondHalf.map((e) => e.confidence).reduce((a, b) => a + b) /
        secondHalf.length;

    final difference = secondAvgConfidence - firstAvgConfidence;

    if (difference > 0.1) return TrendDirection.improving;
    if (difference < -0.1) return TrendDirection.declining;
    return TrendDirection.stable;
  }

  // Get appropriate response emotion
  EmotionType getResponseEmotion() {
    switch (_currentEmotion.emotion) {
      case EmotionType.excited:
        return EmotionType.excited;
      case EmotionType.sad:
        return EmotionType.calm;
      case EmotionType.urgent:
        return EmotionType.calm;
      case EmotionType.calm:
        return EmotionType.calm;
      case EmotionType.neutral:
        return EmotionType.neutral;
    }
  }

  // Get emotion description in Arabic
  String getEmotionDescription(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.excited:
        return 'متحمس ومتفائل';
      case EmotionType.calm:
        return 'هادئ ومرتاح';
      case EmotionType.neutral:
        return 'محايد';
      case EmotionType.sad:
        return 'حزين أو محبط';
      case EmotionType.urgent:
        return 'مستعجل أو قلق';
    }
  }

  // Clear emotion history
  void clearHistory() {
    _emotionHistory.clear();
    _currentEmotion = EmotionState.neutral;
    _confidence = 0.0;
    notifyListeners();
  }
}

class EmotionState {
  final EmotionType emotion;
  final double confidence;
  final DateTime timestamp;
  final EmotionSource source;

  EmotionState({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
    required this.source,
  });

  static EmotionState get neutral => EmotionState(
    emotion: EmotionType.neutral,
    confidence: 0.0,
    timestamp: DateTime.now(),
    source: EmotionSource.unknown,
  );
}

class EmotionReading {
  final EmotionType emotion;
  final double confidence;
  final DateTime timestamp;
  final EmotionSource source;

  EmotionReading({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
    required this.source,
  });
}

class EmotionTrend {
  final EmotionType dominantEmotion;
  final double averageConfidence;
  final Map<EmotionType, int> emotionCounts;
  final TrendDirection trend;

  EmotionTrend({
    required this.dominantEmotion,
    required this.averageConfidence,
    required this.emotionCounts,
    required this.trend,
  });
}

enum EmotionSource { text, audio, combined, unknown }

enum TrendDirection { improving, declining, stable }
