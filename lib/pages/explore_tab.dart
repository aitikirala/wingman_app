import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  _ExploreTabState createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  LatLng? currentLocation;
  String? errorMessage;
  String? zipCode;
  List<dynamic> nearbyPlaces = [];

  final String apiKeyIOS = 'AIzaSyAnjiYYRSdcwj_l_hKb0yoHk0Yjj65V1ug';
  final String apiKeyAndroid = 'AIzaSyDmEgeulLM-j_ARIW4lZkF9yLNxkUs0HB8';
  final String apiKeyWeb = 'AIzaSyCzqFR9Ia-8H1M-fxaJ49EDld3aghn-6ps';
  final String geocodingApiKey =
      'AIzaSyC7H09WpqfBy2EEamBKXzvLAMcmApR-HyM'; // Geocoding API key

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
          errorMessage = "Location permissions are permanently denied.";
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

      await _getZipCode();
      await _fetchNearbyPlaces();
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching location: $e";
      });
    }
  }

  Future<void> _getZipCode() async {
    if (currentLocation == null) return;

    final latitude = currentLocation!.latitude;
    final longitude = currentLocation!.longitude;
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$geocodingApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final addressComponents = data['results'][0]['address_components'];
          for (var component in addressComponents) {
            if (component['types'].contains('postal_code')) {
              setState(() {
                zipCode = component['long_name'];
              });
              break;
            }
          }
        } else {
          setState(() {
            errorMessage = 'Failed to retrieve zip code: ${data['status']}';
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch zip code. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching zip code: $e';
      });
    }
  }

  Future<void> _fetchNearbyPlaces({String? pageToken}) async {
    if (currentLocation == null) return;

    final double latitude = currentLocation!.latitude;
    final double longitude = currentLocation!.longitude;
    final int radius = 32187;

    final url = Uri.parse('http://localhost:8080/api/proxy/nearbysearch')
        .replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
      'apiKey': apiKey,
      if (pageToken != null) 'pageToken': pageToken,
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          setState(() {
            nearbyPlaces.addAll(data['results']);
          });

          if (data['next_page_token'] != null) {
            await Future.delayed(Duration(seconds: 2));
            _fetchNearbyPlaces(pageToken: data['next_page_token']);
          }
        } else {
          setState(() {
            errorMessage = 'No results found: ${data['status']}';
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load nearby places. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  void _onPlaceTap(dynamic place) async {
    final placeDetails = await _fetchPlaceDetails(place['place_id']);
    final phoneNumber =
        placeDetails['formatted_phone_number'] ?? 'No Phone Number';
    final openingHours = placeDetails['opening_hours']?['weekday_text'] ??
        ['No hours available'];
    final photoReference = placeDetails['photos'] != null
        ? placeDetails['photos'][0]['photo_reference']
        : null;

    final photoUrl = photoReference != null
        ? Uri.parse('http://localhost:8080/api/proxy/photo')
            .replace(queryParameters: {
            'photoReference': photoReference,
            'apiKey': apiKey,
          }).toString()
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    child: Image.network(
                      photoUrl,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, 'Address',
                    placeDetails['formatted_address'] ?? 'No Address'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.phone, 'Phone', phoneNumber),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.star, 'Rating',
                    placeDetails['rating']?.toString() ?? 'No Rating'),
                const SizedBox(height: 12),
                const Text(
                  'Opening Hours:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...openingHours.map((hour) =>
                    Text(hour, style: const TextStyle(color: Colors.grey))),
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

  Future<Map<String, dynamic>> _fetchPlaceDetails(String placeId) async {
    final url = Uri.parse('http://localhost:8080/api/proxy/detail')
        .replace(queryParameters: {
      'placeId': placeId,
      'apiKey': apiKey,
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] ?? {};
      } else {
        print(
            "Failed to load place details. Status code: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("Error fetching place details: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
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
            const Text("Fetching your location...",
                style: TextStyle(fontSize: 16)),
          ] else ...[
            Text('Places near: ',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(zipCode ?? 'Fetching zip code...',
                style: const TextStyle(fontSize: 16)),
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
                            ? Uri.parse('http://localhost:8080/api/proxy/photo')
                                .replace(queryParameters: {
                                'photoReference': photoReference,
                                'apiKey': apiKey,
                              }).toString()
                            : null;

                        return InkWell(
                          onTap: () => _onPlaceTap(place),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place['name'] ?? 'No Name',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          place['vicinity'] ?? 'No Address',
                                          style: const TextStyle(
                                              fontSize: 16, color: Colors.grey),
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(Icons.broken_image,
                                              size: 100);
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
