import 'package:flutter/foundation.dart';
import '../../models/property_model.dart';

class PropertyRecommendationService extends ChangeNotifier {
  final Map<String, double> _userPreferences = {};
  final Map<String, int> _interactionHistory = {};
  final Map<String, double> _locationPreferences = {};
  final Map<String, double> _featurePreferences = {};

  List<Property> _availableProperties = [];
  List<PropertyRecommendation> _currentRecommendations = [];

  // Machine learning weights (simplified)
  final Map<String, double> _mlWeights = {
    'location': 0.3,
    'price': 0.25,
    'propertyType': 0.2,
    'features': 0.15,
    'size': 0.1,
  };

  // Getters
  List<PropertyRecommendation> get currentRecommendations =>
      List.unmodifiable(_currentRecommendations);
  Map<String, double> get userPreferences => Map.unmodifiable(_userPreferences);

  void initialize(List<Property> properties) {
    _availableProperties = properties;
    _loadUserPreferences();
    _generateRecommendations();
  }

  void _loadUserPreferences() {
    // Initialize with default preferences
    _userPreferences.addAll({
      'budget_min': 200000.0,
      'budget_max': 800000.0,
      'preferred_bedrooms': 3.0,
      'preferred_bathrooms': 2.0,
      'min_area': 100.0,
      'max_area': 300.0,
    });

    _locationPreferences.addAll({
      'الرياض': 0.8,
      'جدة': 0.6,
      'الدمام': 0.4,
      'مكة': 0.3,
    });

    _featurePreferences.addAll({
      'مسبح': 0.7,
      'حديقة': 0.8,
      'مصعد': 0.5,
      'موقف سيارات': 0.9,
      'أمن': 0.6,
    });
  }

  // Learn from user voice interactions
  void learnFromVoiceInteraction(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Extract preferences from voice
    _extractLocationPreferences(lowerMessage);
    _extractPricePreferences(lowerMessage);
    _extractPropertyTypePreferences(lowerMessage);
    _extractFeaturePreferences(lowerMessage);
    _extractSizePreferences(lowerMessage);

    // Update interaction history
    _updateInteractionHistory(lowerMessage);

    // Regenerate recommendations
    _generateRecommendations();
    notifyListeners();
  }

  void _extractLocationPreferences(String message) {
    final locations = ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة'];

    for (final location in locations) {
      if (message.contains(location.toLowerCase())) {
        _locationPreferences[location] =
            (_locationPreferences[location] ?? 0.0) + 0.1;
        _locationPreferences[location] = _locationPreferences[location]!.clamp(
          0.0,
          1.0,
        );
      }
    }
  }

  void _extractPricePreferences(String message) {
    // Extract price mentions
    final priceRegex = RegExp(r'(\d+)\s*(ألف|مليون|ريال)');
    final matches = priceRegex.allMatches(message);

    for (final match in matches) {
      final number = double.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = match.group(2);

      double price = number;
      if (unit == 'ألف') {
        price *= 1000;
      } else if (unit == 'مليون') {
        price *= 1000000;
      }

      // Update budget preferences
      if (message.contains('أقل من') || message.contains('تحت')) {
        _userPreferences['budget_max'] = price;
      } else if (message.contains('أكثر من') || message.contains('فوق')) {
        _userPreferences['budget_min'] = price;
      } else {
        // Assume it's a target price, adjust range around it
        _userPreferences['budget_min'] = price * 0.8;
        _userPreferences['budget_max'] = price * 1.2;
      }
    }
  }

  void _extractPropertyTypePreferences(String message) {
    final propertyTypes = {
      'شقة': 'apartment',
      'فيلا': 'villa',
      'أرض': 'land',
      'محل': 'commercial',
      'مكتب': 'office',
    };

    for (final entry in propertyTypes.entries) {
      if (message.contains(entry.key)) {
        _userPreferences['preferred_type_${entry.value}'] =
            (_userPreferences['preferred_type_${entry.value}'] ?? 0.0) + 0.2;
      }
    }
  }

  void _extractFeaturePreferences(String message) {
    final features = {
      'مسبح': 'pool',
      'حديقة': 'garden',
      'مصعد': 'elevator',
      'موقف': 'parking',
      'أمن': 'security',
      'مطبخ': 'kitchen',
      'صالة': 'living_room',
    };

    for (final entry in features.entries) {
      if (message.contains(entry.key)) {
        _featurePreferences[entry.key] =
            (_featurePreferences[entry.key] ?? 0.0) + 0.1;
        _featurePreferences[entry.key] = _featurePreferences[entry.key]!.clamp(
          0.0,
          1.0,
        );
      }
    }
  }

  void _extractSizePreferences(String message) {
    // Extract room counts
    final bedroomRegex = RegExp(r'(\d+)\s*(غرف|غرفة)');
    final bathroomRegex = RegExp(r'(\d+)\s*(حمام|دورة)');
    final areaRegex = RegExp(r'(\d+)\s*(متر|م)');

    final bedroomMatch = bedroomRegex.firstMatch(message);
    if (bedroomMatch != null) {
      final bedrooms = double.tryParse(bedroomMatch.group(1) ?? '0') ?? 0;
      _userPreferences['preferred_bedrooms'] = bedrooms;
    }

    final bathroomMatch = bathroomRegex.firstMatch(message);
    if (bathroomMatch != null) {
      final bathrooms = double.tryParse(bathroomMatch.group(1) ?? '0') ?? 0;
      _userPreferences['preferred_bathrooms'] = bathrooms;
    }

    final areaMatch = areaRegex.firstMatch(message);
    if (areaMatch != null) {
      final area = double.tryParse(areaMatch.group(1) ?? '0') ?? 0;
      _userPreferences['preferred_area'] = area;
    }
  }

  void _updateInteractionHistory(String message) {
    // Track interaction patterns
    final words = message.split(' ');
    for (final word in words) {
      if (word.length > 3) {
        _interactionHistory[word] = (_interactionHistory[word] ?? 0) + 1;
      }
    }
  }

  void _generateRecommendations() {
    final recommendations = <PropertyRecommendation>[];

    for (final property in _availableProperties) {
      final score = _calculatePropertyScore(property);
      final reasons = _generateRecommendationReasons(property);

      recommendations.add(
        PropertyRecommendation(
          property: property,
          score: score,
          reasons: reasons,
          confidence: _calculateConfidence(property, score),
        ),
      );
    }

    // Sort by score and take top recommendations
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    _currentRecommendations = recommendations.take(10).toList();
  }

  double _calculatePropertyScore(Property property) {
    double score = 0.0;

    // Location score
    final locationScore = _locationPreferences[property.location] ?? 0.0;
    score += locationScore * _mlWeights['location']!;

    // Price score
    final priceScore = _calculatePriceScore(property.price);
    score += priceScore * _mlWeights['price']!;

    // Property type score
    final typeScore = _calculatePropertyTypeScore(property.type);
    score += typeScore * _mlWeights['propertyType']!;

    // Features score
    final featuresScore = _calculateFeaturesScore(property.features);
    score += featuresScore * _mlWeights['features']!;

    // Size score
    final sizeScore = _calculateSizeScore(property);
    score += sizeScore * _mlWeights['size']!;

    return score.clamp(0.0, 1.0);
  }

  double _calculatePriceScore(double price) {
    final minBudget = _userPreferences['budget_min'] ?? 0.0;
    final maxBudget = _userPreferences['budget_max'] ?? double.infinity;

    if (price < minBudget || price > maxBudget) {
      return 0.0;
    }

    // Score is higher for prices closer to the middle of the range
    final midPoint = (minBudget + maxBudget) / 2;
    final distance = (price - midPoint).abs();
    final maxDistance = (maxBudget - minBudget) / 2;

    return 1.0 - (distance / maxDistance);
  }

  double _calculatePropertyTypeScore(String type) {
    final typeKey = 'preferred_type_$type';
    return _userPreferences[typeKey] ?? 0.5;
  }

  double _calculateFeaturesScore(List<String> features) {
    if (features.isEmpty) return 0.5;

    double totalScore = 0.0;
    int matchedFeatures = 0;

    for (final feature in features) {
      final preference = _featurePreferences[feature];
      if (preference != null) {
        totalScore += preference;
        matchedFeatures++;
      }
    }

    return matchedFeatures > 0 ? totalScore / matchedFeatures : 0.5;
  }

  double _calculateSizeScore(Property property) {
    double score = 0.5;

    // Bedrooms
    final preferredBedrooms = _userPreferences['preferred_bedrooms'] ?? 3.0;
    final bedroomDiff = (property.rooms - preferredBedrooms).abs();
    score += (1.0 - bedroomDiff / 5.0).clamp(0.0, 0.3);

    // Bathrooms
    final preferredBathrooms = _userPreferences['preferred_bathrooms'] ?? 2.0;
    final bathroomDiff = (property.bathrooms - preferredBathrooms).abs();
    score += (1.0 - bathroomDiff / 3.0).clamp(0.0, 0.2);

    return score.clamp(0.0, 1.0);
  }

  List<String> _generateRecommendationReasons(Property property) {
    final reasons = <String>[];

    // Location match
    final locationPref = _locationPreferences[property.location] ?? 0.0;
    if (locationPref > 0.6) {
      reasons.add('موقع مفضل لديك (${property.location})');
    }

    // Price match
    final minBudget = _userPreferences['budget_min'] ?? 0.0;
    final maxBudget = _userPreferences['budget_max'] ?? double.infinity;
    if (property.price >= minBudget && property.price <= maxBudget) {
      reasons.add('ضمن نطاق ميزانيتك');
    }

    // Feature matches
    for (final feature in property.features) {
      final preference = _featurePreferences[feature];
      if (preference != null && preference > 0.6) {
        reasons.add('يحتوي على $feature المفضل لديك');
      }
    }

    // Size match
    final preferredBedrooms = _userPreferences['preferred_bedrooms'] ?? 3.0;
    if ((property.rooms - preferredBedrooms).abs() <= 1) {
      reasons.add('عدد الغرف مناسب لاحتياجاتك');
    }

    return reasons;
  }

  double _calculateConfidence(Property property, double score) {
    // Confidence based on how much data we have about user preferences
    double confidence = 0.5;

    // More interactions = higher confidence
    final totalInteractions = _interactionHistory.values.fold(
      0,
      (a, b) => a + b,
    );
    confidence += (totalInteractions / 100.0).clamp(0.0, 0.3);

    // More specific preferences = higher confidence
    final specificPreferences =
        _userPreferences.length +
        _locationPreferences.length +
        _featurePreferences.length;
    confidence += (specificPreferences / 20.0).clamp(0.0, 0.2);

    return confidence.clamp(0.0, 1.0);
  }

  // Public methods
  void recordPropertyInteraction(String propertyId, String interactionType) {
    // Record user interactions with properties
    final key = '${propertyId}_$interactionType';
    _interactionHistory[key] = (_interactionHistory[key] ?? 0) + 1;

    // Update recommendations based on interaction
    _generateRecommendations();
    notifyListeners();
  }

  void updateUserFeedback(String propertyId, double rating) {
    // Learn from user feedback
    final property = _availableProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => throw Exception('Property not found'),
    );

    // Adjust preferences based on rating
    if (rating >= 4.0) {
      // Positive feedback - increase preferences for this property's characteristics
      _locationPreferences[property.location] =
          (_locationPreferences[property.location] ?? 0.0) + 0.1;

      for (final feature in property.features) {
        _featurePreferences[feature] =
            (_featurePreferences[feature] ?? 0.0) + 0.1;
      }
    } else if (rating <= 2.0) {
      // Negative feedback - decrease preferences
      _locationPreferences[property.location] =
          (_locationPreferences[property.location] ?? 0.0) - 0.1;

      for (final feature in property.features) {
        _featurePreferences[feature] =
            (_featurePreferences[feature] ?? 0.0) - 0.1;
      }
    }

    // Clamp values
    _locationPreferences.updateAll((key, value) => value.clamp(0.0, 1.0));
    _featurePreferences.updateAll((key, value) => value.clamp(0.0, 1.0));

    _generateRecommendations();
    notifyListeners();
  }

  List<PropertyRecommendation> getRecommendationsByCategory(String category) {
    return _currentRecommendations
        .where((r) => r.property.type == category)
        .toList();
  }

  List<PropertyRecommendation> getRecommendationsByLocation(String location) {
    return _currentRecommendations
        .where((r) => r.property.location == location)
        .toList();
  }

  Map<String, dynamic> getRecommendationInsights() {
    return {
      'totalRecommendations': _currentRecommendations.length,
      'averageScore':
          _currentRecommendations.isNotEmpty
              ? _currentRecommendations
                      .map((r) => r.score)
                      .reduce((a, b) => a + b) /
                  _currentRecommendations.length
              : 0.0,
      'topLocation': _getTopLocation(),
      'preferredPriceRange':
          '${_userPreferences['budget_min']?.round()} - ${_userPreferences['budget_max']?.round()}',
      'mostImportantFeatures': _getMostImportantFeatures(),
      'recommendationConfidence': _getAverageConfidence(),
    };
  }

  String _getTopLocation() {
    if (_locationPreferences.isEmpty) return 'غير محدد';
    return _locationPreferences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<String> _getMostImportantFeatures() {
    final sortedFeatures =
        _featurePreferences.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sortedFeatures.take(3).map((e) => e.key).toList();
  }

  double _getAverageConfidence() {
    if (_currentRecommendations.isEmpty) return 0.0;
    return _currentRecommendations
            .map((r) => r.confidence)
            .reduce((a, b) => a + b) /
        _currentRecommendations.length;
  }
}

class PropertyRecommendation {
  final Property property;
  final double score;
  final List<String> reasons;
  final double confidence;

  PropertyRecommendation({
    required this.property,
    required this.score,
    required this.reasons,
    required this.confidence,
  });

  String get scorePercentage => '${(score * 100).round()}%';
  String get confidencePercentage => '${(confidence * 100).round()}%';
}
