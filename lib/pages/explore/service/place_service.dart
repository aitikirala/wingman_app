import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceService {
  // Update this to your server's address
  static final String serverUrl = 'http://localhost:8080';

  String? sessionId;

  Future<void> startSession() async {
    final response =
        await http.get(Uri.parse('$serverUrl/api/proxy/startSession'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      sessionId = data['sessionId'];
    } else {
      throw Exception('Failed to start session');
    }
  }

  static Future<Map<String, dynamic>> fetchNearbyPlaces(
      double latitude, double longitude,
      {int radius = 1600, int groupIndex = 0, String? sessionId}) async {
    final url = Uri.parse('$serverUrl/api/proxy/nearbysearch').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'groupIndex': groupIndex.toString(),
        if (sessionId != null) 'sessionId': sessionId,
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

  static Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url = Uri.parse('$serverUrl/api/proxy/detail').replace(
      queryParameters: {
        'placeId': placeId,
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

  static Future<List<dynamic>> fetchAutocompleteSuggestions(
      String input) async {
    final url = Uri.parse('$serverUrl/api/proxy/autocomplete').replace(
      queryParameters: {
        'input': input,
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            'Failed to fetch suggestions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching suggestions: $e');
    }
  }
}
