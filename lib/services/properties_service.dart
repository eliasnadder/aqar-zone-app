import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property.dart';
import '../models/agent.dart';

class PropertiesService {
  static const String baseUrl =
      'http://192.168.99.209:8000/api'; // Replace with your actual API URL

  static Future<List<Property>> getProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/properties'),
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> propertiesJson = data['data'] ?? [];

        return propertiesJson.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching properties: $e');
    }
  }

  static Future<Property> getPropertyById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/properties/$id'),
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Property.fromJson(data['data']);
      } else {
        throw Exception('Failed to load property: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching property: $e');
    }
  }

  // Mock data for testing purposes
  static List<Property> getMockProperties() {
    return [
      Property(
        id: '1',
        title: 'Modern Apartment in Downtown',
        description:
            'Beautiful 2-bedroom apartment with city views. This stunning property features floor-to-ceiling windows, modern appliances, and premium finishes throughout. Located in the heart of the city with easy access to public transportation, shopping, and dining.',
        price: 250000,
        currency: 'USD',
        type: 'Apartment',
        adType: 'Sale',
        address: '123 Main St',
        areaName: 'Downtown',
        cityName: 'New York',
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
        images: ['image1.jpg', 'image2.jpg'],
        latitude: 40.7128,
        longitude: -74.0060,
        agent: const Agent(
          id: '1',
          name: 'Sarah Johnson',
          email: 'sarah.johnson@aqarzone.com',
          phone: '+1 (555) 123-4567',
          company: 'Aqar Zone Real Estate',
          rating: 4.8,
          reviewsCount: 127,
          bio:
              'Experienced real estate agent specializing in downtown properties.',
          specialties: [
            'Downtown Properties',
            'First-time Buyers',
            'Investment Properties',
          ],
        ),
      ),
      Property(
        id: '2',
        title: 'Luxury Villa with Pool',
        description:
            'Spacious villa with private pool and garden. This magnificent property offers luxury living with a private swimming pool, landscaped gardens, and spacious interiors. Perfect for families looking for comfort and elegance in a prestigious neighborhood.',
        price: 1500,
        currency: 'USD',
        type: 'Villa',
        adType: 'Rent',
        address: '456 Oak Ave',
        areaName: 'Suburbs',
        cityName: 'Los Angeles',
        area: 300.0,
        bedrooms: 4,
        bathrooms: 3,
        images: ['villa1.jpg', 'villa2.jpg'],
        latitude: 34.0522,
        longitude: -118.2437,
        agent: const Agent(
          id: '2',
          name: 'Michael Chen',
          email: 'michael.chen@aqarzone.com',
          phone: '+1 (555) 987-6543',
          company: 'Aqar Zone Real Estate',
          rating: 4.9,
          reviewsCount: 89,
          bio:
              'Luxury property specialist with expertise in high-end residential sales.',
          specialties: ['Luxury Properties', 'Villa Sales', 'High-end Rentals'],
        ),
      ),
      Property(
        id: '3',
        title: 'Cozy Studio Near University',
        description:
            'Perfect for students, fully furnished. This charming studio apartment is ideally located near the university campus. Fully furnished with modern amenities, high-speed internet, and all utilities included. Great for students or young professionals.',
        price: 800,
        currency: 'USD',
        type: 'Studio',
        adType: 'Rent',
        address: '789 College Rd',
        areaName: 'University District',
        cityName: 'Boston',
        area: 35.0,
        bedrooms: 1,
        bathrooms: 1,
        images: ['studio1.jpg'],
        latitude: 42.3601,
        longitude: -71.0589,
        agent: const Agent(
          id: '3',
          name: 'Emily Rodriguez',
          email: 'emily.rodriguez@aqarzone.com',
          phone: '+1 (555) 456-7890',
          company: 'Aqar Zone Real Estate',
          rating: 4.7,
          reviewsCount: 156,
          bio:
              'Student housing specialist helping students find perfect accommodations.',
          specialties: [
            'Student Housing',
            'Rental Properties',
            'University Area',
          ],
        ),
      ),
    ];
  }
}
