import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/property_model.dart';
import '../models/paginated_response.dart';

class PropertiesService {
  static const String baseUrl =
      'https://state-ecommerce-production.up.railway.app/api';

  // Instance methods for BLoC compatibility

  /// Get properties with pagination and filtering support
  Future<PaginatedResponse<Property>> getProperties({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': limit.toString(),
      };

      // Add search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      // Add filters if provided
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      final uri = Uri.parse(
        '$baseUrl/user/properties',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PaginatedResponse.fromJson(data, Property.fromJson);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      throw Exception('Error fetching properties: $e');
    }
  }

  // Legacy static method for backward compatibility
  static Future<List<Property>> getPropertiesStatic() async {
    final service = PropertiesService();
    final paginatedResponse = await service.getProperties();
    return paginatedResponse.data;
  }

  /// Get property by ID
  Future<Property?> getPropertyById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          debugPrint('Empty response body for property: $id');
          return null;
        }

        try {
          final Map<String, dynamic> data = jsonDecode(responseBody);

          // Handle both direct property response and wrapped response
          if (data.containsKey('data') && data['data'] != null) {
            return Property.fromJson(data['data']);
          } else if (data.isNotEmpty) {
            return Property.fromJson(data);
          } else {
            debugPrint('No property data in response for: $id');
            return null;
          }
        } catch (jsonError) {
          debugPrint('JSON parsing error for property $id: $jsonError');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Property not found: $id');
        return null;
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching property: $e');
      return null;
    }
  }

  /// Get property by ad number
  Future<Property?> getPropertyByAdNumber(String adNumber) async {
    try {
      final response = await getProperties(searchQuery: adNumber);
      final properties =
          response.data.where((p) => p.adNumber == adNumber).toList();
      return properties.isNotEmpty ? properties.first : null;
    } catch (e) {
      debugPrint('Error fetching property by ad number: $e');
      return null;
    }
  }

  /// Get similar properties based on property characteristics
  Future<List<Property>> getSimilarProperties(
    String propertyId, {
    int limit = 5,
  }) async {
    try {
      // For now, just return recent properties
      // In a real implementation, this would use ML or similarity algorithms
      final response = await getProperties(limit: limit);
      final targetId = int.tryParse(propertyId);
      return response.data.where((p) => p.id != targetId).take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching similar properties: $e');
      return [];
    }
  }

  /// Increment property views (mock implementation)
  Future<int> incrementPropertyViews(String propertyId) async {
    try {
      // In a real implementation, this would make an API call to increment views
      // For now, return a mock incremented view count
      await Future.delayed(const Duration(milliseconds: 100));
      return DateTime.now().millisecondsSinceEpoch % 1000; // Mock view count
    } catch (e) {
      debugPrint('Error incrementing property views: $e');
      return 0;
    }
  }

  // Static methods for backward compatibility

  /// Get properties with pagination support (static version)
  static Future<PaginatedResponse<Property>> getPropertiesPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    final service = PropertiesService();
    return await service.getProperties(page: page, limit: perPage);
  }

  /// Get property by ID (static version)
  static Future<Property> getPropertyByIdStatic(String id) async {
    final service = PropertiesService();
    final property = await service.getPropertyById(id);
    if (property == null) {
      throw Exception('Property not found');
    }
    return property;
  }
}
