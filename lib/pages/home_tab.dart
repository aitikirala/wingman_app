import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  LatLng? currentLocation;
  String? errorMessage;
  List<dynamic> nearbyPlaces = [];

  final String apiKeyIOS = 'AIzaSyAnjiYYRSdcwj_l_hKb0yoHk0Yjj65V1ug';
  final String apiKeyAndroid = 'AIzaSyDmEgeulLM-j_ARIW4lZkF9yLNxkUs0HB8';
  final String apiKeyWeb = 'AIzaSyCzqFR9Ia-8H1M-fxaJ49EDld3aghn-6ps';


  String get apiKey {
    if (kIsWeb) {
      return apiKeyWeb;
    } else if (Platform.isIOS) {
      return apiKeyIOS;
    } else if (Platform.isAndroid) {
      return apiKeyAndroid;
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = "Location services are disabled.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = "Location permissions are denied.";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage =
          "Location permissions are permanently denied. We cannot access your location.";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        errorMessage = null;
      });

      await _fetchNearbyPlaces();
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching location: $e";
      });
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (currentLocation == null) return;

    final double latitude = currentLocation!.latitude;
    final double longitude = currentLocation!.longitude;
    final int radius = 32187; // 20 miles in meters

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$latitude,$longitude&radius=$radius&type=establishment&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          nearbyPlaces = data['results'];
        });
      } else {
        setState(() {
          errorMessage = 'No results found: ${data['status']}';
        });
      }
    } else {
      setState(() {
        errorMessage = 'Failed to load nearby places. Status code: ${response.statusCode}';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result'] ?? {};
    } else {
      print("Failed to load place details. Status code: ${response.statusCode}");
      return {};
    }
  }

  void _onPlaceTap(dynamic place) async {
    final placeDetails = await _fetchPlaceDetails(place['place_id']);
    final phoneNumber = placeDetails['formatted_phone_number'] ?? 'No Phone Number';
    final openingHours = placeDetails['opening_hours']?['weekday_text'] ?? ['No hours available'];
    final photoReference = placeDetails['photos'] != null ? placeDetails['photos'][0]['photo_reference'] : null;

    final photoUrl = photoReference != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey'
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              placeDetails['name'] ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(photoUrl, height: 150, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, 'Address', placeDetails['formatted_address'] ?? 'No Address'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.phone, 'Phone', phoneNumber),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.star, 'Rating', placeDetails['rating']?.toString() ?? 'No Rating'),
                const SizedBox(height: 12),
                const Text(
                  'Opening Hours:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...openingHours.map((hour) => Text(hour, style: const TextStyle(color: Colors.grey))),
              ],
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0), // Padding added
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ] else if (currentLocation == null) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Fetching your location...",
              style: TextStyle(fontSize: 16),
            ),
          ] else ...[
            Text(
              'Your Current Location:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Latitude: ${currentLocation!.latitude}, Longitude: ${currentLocation!.longitude}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: nearbyPlaces.isEmpty
                  ? const Text("No places found within 10 miles.")
                  : ListView.builder(
                itemCount: nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = nearbyPlaces[index];
                  final photoReference = place['photos'] != null
                      ? place['photos'][0]['photo_reference']
                      : null;

                  final photoUrl = photoReference != null
                      ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=100&photoreference=$photoReference&key=$apiKey'
                      : null;

                  return InkWell(
                    onTap: () => _onPlaceTap(place),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place['name'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    place['vicinity'] ?? 'No Address',
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rating: ${place['rating'] ?? 'No Rating'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            if (photoUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Image.network(
                                  photoUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 100);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }


}
