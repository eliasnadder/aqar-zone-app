import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'agent.dart';

class Property {
  final int id;
  final String title;
  final String description;
  final String location;
  final String status;
  final double price;
  final String currency;
  final String type;
  final String adType;
  final String? address;
  final String? areaName;
  final String? cityName;
  final double area;
  final int? bedrooms;
  final int rooms;
  final int bathrooms;
  final String furnishing;
  final String adNumber;
  final int? views;
  final String? sellerType;
  final int? floorNumber;
  final String? direction;
  final bool isOffer;
  final bool isAvailable;

  final List<String> features;
  final List<String>? images;
  final double? latitude;
  final double? longitude;
  final Agent? agent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.price,
    required this.currency,
    required this.type,
    required this.adType,
    required this.rooms,
    required this.bathrooms,
    required this.furnishing,
    required this.features,
    required this.area,
    required this.adNumber,
    required this.isOffer,
    required this.isAvailable,
    this.address,
    this.areaName,
    this.cityName,
    this.bedrooms,
    this.images,
    this.latitude,
    this.longitude,
    this.agent,
    this.views,
    this.sellerType,
    this.floorNumber,
    this.direction,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Property.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null) {
        throw ArgumentError('Property ID is required');
      }

      if (json['title'] == null || json['title'].toString().isEmpty) {
        throw ArgumentError('Property title is required');
      }

      // Parse price from string to double
      double parsedPrice = 0.0;
      if (json['price'] != null) {
        try {
          if (json['price'] is String) {
            parsedPrice = double.tryParse(json['price']) ?? 0.0;
          } else {
            parsedPrice = (json['price'] as num).toDouble();
          }
        } catch (e) {
          debugPrint('Error parsing price: $e');
          parsedPrice = 0.0;
        }
      }

      // Parse area from string to double
      double? parsedArea;
      try {
        if (json['area'] != null) {
          if (json['area'] is String) {
            parsedArea = double.tryParse(json['area']);
          } else {
            parsedArea = (json['area'] as num?)?.toDouble();
          }

          // Validate area is positive
          if (parsedArea != null &&
              (parsedArea <= 0 || parsedArea.isNaN || parsedArea.isInfinite)) {
            debugPrint('Invalid area value: $parsedArea');
            parsedArea = null;
          }
        }
      } catch (e) {
        debugPrint('Error parsing area: $e');
        parsedArea = null;
      }

      // Parse latitude from string to double
      double? parsedLatitude;
      if (json['latitude'] != null) {
        if (json['latitude'] is String) {
          parsedLatitude = double.tryParse(json['latitude']);
        } else {
          parsedLatitude = (json['latitude'] as num?)?.toDouble();
        }
      }

      // Parse longitude from string to double
      double? parsedLongitude;
      if (json['longitude'] != null) {
        if (json['longitude'] is String) {
          parsedLongitude = double.tryParse(json['longitude']);
        } else {
          parsedLongitude = (json['longitude'] as num?)?.toDouble();
        }
      }

      // Extract image URLs from the images array
      List<String>? imageUrls;
      if (json['images'] != null && json['images'] is List) {
        final imagesList = json['images'] as List;
        imageUrls =
            imagesList.map((img) {
              if (img is Map<String, dynamic> && img['url'] != null) {
                String url = img['url'].toString();
                // Add https:// if not present
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  url = 'https://$url';
                }
                return url;
              }
              return img.toString(); // Fallback for direct string URLs
            }).toList();
      }

      // Parse features - handle null case
      List<String> parsedFeatures = [];
      if (json['features'] != null) {
        if (json['features'] is List) {
          parsedFeatures = List<String>.from(json['features']);
        } else if (json['features'] is String) {
          // If features is a string, split by comma or other delimiter
          parsedFeatures =
              json['features']
                  .toString()
                  .split(',')
                  .map((f) => f.trim())
                  .where((f) => f.isNotEmpty)
                  .toList();
        }
      }

      return Property(
        id:
            json['id'] is int
                ? json['id']
                : int.tryParse(json['id'].toString()) ?? 0,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        price: parsedPrice,
        currency: json['currency']?.toString() ?? 'USD',
        type: json['type']?.toString() ?? '',
        adType: json['ad_type']?.toString() ?? '',
        address: json['address']?.toString(),
        areaName: json['area_name']?.toString(),
        cityName: json['city_name']?.toString(),
        area: parsedArea!,
        bedrooms:
            json['bedrooms'] is int
                ? json['bedrooms']
                : int.tryParse(json['bedrooms']?.toString() ?? ''),
        rooms:
            json['rooms'] is int
                ? json['rooms']
                : int.tryParse(json['rooms']?.toString() ?? '') ?? 0,
        bathrooms:
            json['bathrooms'] is int
                ? json['bathrooms']
                : int.tryParse(json['bathrooms']?.toString() ?? '') ?? 0,
        features: parsedFeatures,
        images: imageUrls,
        latitude: parsedLatitude,
        longitude: parsedLongitude,
        agent:
            json['agent'] != null
                ? Agent.fromJson(json['agent'])
                : Agent.defaultAgent,
        furnishing: json['furnishing']?.toString() ?? '',
        adNumber: json['ad_number'].toString(),
        views:
            json['views'] is int
                ? json['views']
                : int.tryParse(json['views']?.toString() ?? ''),
        sellerType: json['seller_type']?.toString(),
        floorNumber:
            json['floor_number'] is int
                ? json['floor_number']
                : int.tryParse(json['floor_number']?.toString() ?? ''),
        direction: json['direction']?.toString(),
        isOffer:
            json['is_offer'] is bool
                ? json['is_offer']
                : (json['is_offer']?.toString().toLowerCase() == 'true'),
        isAvailable:
            json['is_available'] is bool
                ? json['is_available']
                : (json['is_available']?.toString().toLowerCase() == 'true'),
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        updatedAt:
            json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'].toString())
                : null,
      );
    } catch (e) {
      // Use a more robust logging approach
      debugPrint("Error parsing property: $e");
      debugPrint("JSON data: $json");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'price': price.toString(), // Convert back to string to match API format
      'currency': currency,
      'type': type,
      'ad_type': adType,
      'address': address,
      'area_name': areaName,
      'city_name': cityName,
      'area': area.toString(), // Convert back to string to match API format
      'bedrooms': bedrooms,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'images':
          images
              ?.map((url) => {'url': url})
              .toList(), // Convert back to API format
      'latitude':
          latitude?.toString(), // Convert back to string to match API format
      'longitude':
          longitude?.toString(), // Convert back to string to match API format
      'agent': agent?.toJson(),
      'furnishing': furnishing,
      'ad_number': adNumber,
      'views': views,
      'seller_type': sellerType,
      'floor_number': floorNumber,
      'direction': direction,
      'is_offer': isOffer,
      'is_available': isAvailable,
      'features': features,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // دالة لتحويل بيانات العقار إلى نص يمكن للـ AI فهمه
  String toContextString() {
    final areaText = "المساحة: $area متر مربع";

    return """
العقار رقم: $adNumber
- العنوان: $title
- الوصف: $description
- السعر: $formattedPrice
- العملة: $currency
- الموقع: $location
- نوع الإعلان: $adType
- نوع العقار: $type
- الحالة: $status
- عدد الغرف: $rooms
- عدد الحمامات: $bathrooms
- الفرش: $furnishing
${areaText.isNotEmpty ? '- $areaText' : ''}
${views != null ? '- عدد المشاهدات: $views' : ''}
---
""";
  }

  // String get locationString {
  //   final locationParts =
  //       [
  //         address,
  //         areaName,
  //         cityName,
  //       ].where((part) => part != null && part.isNotEmpty).toList();
  //   return locationParts.isNotEmpty ? locationParts.join(', ') : 'N/A';
  // }

  String get bedroomsDisplay {
    return (bedrooms ?? rooms).toString();
  }

  /// Format price with K/M suffixes for better readability
  String get formattedPrice {
    return formatPrice(price, currency);
  }

  /// Format price per square meter with K/M suffixes
  String get formattedPricePerSqm {
    final pricePerSqm = price / area;
    return '${formatPrice(pricePerSqm, currency)}/m²';
  }

  /// Static method to format any price value
  static String formatPrice(double price, String currency) {
    if (price >= 1000000) {
      // Format as millions
      final millions = price / 1000000;
      if (millions == millions.roundToDouble()) {
        return '${millions.toInt()}M $currency';
      } else {
        return '${millions.toStringAsFixed(1)}M $currency';
      }
    } else if (price >= 1000) {
      // Format as thousands
      final thousands = price / 1000;
      if (thousands == thousands.roundToDouble()) {
        return '${thousands.toInt()}K $currency';
      } else {
        return '${thousands.toStringAsFixed(1)}K $currency';
      }
    } else {
      // Format as regular number for values under 1000
      return '${price.toStringAsFixed(0)} $currency';
    }
  }
}

List<Property> propertiesFromJson(String str) {
  try {
    final jsonData = json.decode(str);

    if (!jsonData.containsKey('data')) {
      throw Exception("JSON response does not contain 'data' key");
    }

    final List<dynamic> data = jsonData['data'];
    final properties = <Property>[];

    for (int i = 0; i < data.length; i++) {
      try {
        final property = Property.fromJson(data[i]);
        properties.add(property);
      } catch (e) {
        // Continue with other properties instead of failing completely
        debugPrint("Error parsing property $i: $e");
      }
    }

    return properties;
  } catch (e) {
    debugPrint("Error in propertiesFromJson: $e");
    rethrow;
  }
}
