import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:wingman_app/pages/explore/service/place_service.dart';

class LocationService {
  static Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception("Error fetching location: $e");
    }
  }

  static Future<String?> getLocationNameFromCoordinates(
      double latitude, double longitude) async {
    final url =
        Uri.parse('${PlaceService.serverUrl}/api/proxy/geocode').replace(
      queryParameters: {
        'latitude': '$latitude',
        'longitude': '$longitude',
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.containsKey('formatted')) {
          final formattedAddress = data['formatted'];
          return formattedAddress;
        } else {
          throw Exception(
              'Failed to retrieve location name: Response does not contain formatted address');
        }
      } else {
        throw Exception(
            'Failed to fetch location name. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching location name: $e');
    }
  }
}
