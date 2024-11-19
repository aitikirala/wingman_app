// services/place_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceService {
  // Update this to your server's address
  static final String serverUrl =
      'http://localhost:8080'; // Replace with your server's IP and port

  static Future<Map<String, dynamic>> fetchNearbyPlaces(
      double latitude, double longitude, String platform,
      {String? pageToken, int groupIndex = 0}) async {
    final int radius = 1600; // 20 miles in meters

    final url = Uri.parse('$serverUrl/api/proxy/nearbysearch').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'platform': platform,
        'groupIndex': groupIndex.toString(),
        if (pageToken != null) 'nextPageToken': pageToken,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to load nearby places. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching nearby places: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchPlaceDetails(
      String placeId, String platform) async {
    final url = Uri.parse('$serverUrl/api/proxy/detail').replace(
      queryParameters: {
        'placeId': placeId,
        'platform': platform,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? {};
      } else {
        throw Exception(
            "Failed to load place details. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching place details: $e");
    }
  }

  static String getPhotoUrl(String photoReference, String platform) {
    final url = Uri.parse('$serverUrl/api/proxy/photo').replace(
      queryParameters: {
        'photoReference': photoReference,
        'platform': platform,
      },
    );
    return url.toString();
  }

  static Future<List<dynamic>> fetchAutocompleteSuggestions(
      String input, String platform) async {
    final url = Uri.parse('$serverUrl/api/proxy/autocomplete').replace(
      queryParameters: {
        'input': input,
        'platform': platform,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['predictions'] ?? [];
      } else {
        throw Exception(
            'Failed to fetch suggestions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching suggestions: $e');
    }
  }
}
