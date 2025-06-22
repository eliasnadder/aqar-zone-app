import 'agent.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String type;
  final String adType;
  final String? address;
  final String? areaName;
  final String? cityName;
  final double? area;
  final int? bedrooms;
  final int? rooms;
  final int? bathrooms;
  final List<String>? images;
  final double? latitude;
  final double? longitude;
  final Agent? agent;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.adType,
    this.address,
    this.areaName,
    this.cityName,
    this.area,
    this.bedrooms,
    this.rooms,
    this.bathrooms,
    this.images,
    this.latitude,
    this.longitude,
    this.agent,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      type: json['type'] ?? '',
      adType: json['ad_type'] ?? '',
      address: json['address'],
      areaName: json['area_name'],
      cityName: json['city_name'],
      area: json['area']?.toDouble(),
      bedrooms: json['bedrooms']?.toInt(),
      rooms: json['rooms']?.toInt(),
      bathrooms: json['bathrooms']?.toInt(),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      agent:
          json['agent'] != null
              ? Agent.fromJson(json['agent'])
              : Agent.defaultAgent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'type': type,
      'ad_type': adType,
      'address': address,
      'area_name': areaName,
      'city_name': cityName,
      'area': area,
      'bedrooms': bedrooms,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'agent': agent?.toJson(),
    };
  }

  String get locationString {
    final locationParts =
        [
          address,
          areaName,
          cityName,
        ].where((part) => part != null && part.isNotEmpty).toList();
    return locationParts.isNotEmpty ? locationParts.join(', ') : 'N/A';
  }

  String get bedroomsDisplay {
    return (bedrooms ?? rooms ?? 0).toString();
  }
}
