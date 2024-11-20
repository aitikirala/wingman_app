// explore_tab.dart
// When running android: 10.0.2.2:8080 replaces localhost:8080

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:wingman_app/pages/explore/service/location_service.dart';
import 'package:wingman_app/pages/explore/service/place_service.dart';
import 'package:wingman_app/pages/explore/widget/CustomAutocompleteWidget.dart';
import 'package:wingman_app/pages/explore/widget/filter_dialog.dart';
import 'package:wingman_app/pages/explore/widget/place_list_item.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({Key? key}) : super(key: key);

  @override
  _ExploreTabState createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  LatLng? currentLocation;
  String? errorMessage;
  String? displayedLocation;
  List<dynamic> nearbyPlaces = [];
  final TextEditingController searchController =
      TextEditingController(); // Search bar controller

  Set<String> selectedTypes = Set();
  Set<String> allTypes = Set();

  // Determine the platform
  String get platform {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    } else {
      return 'unknown';
    }
  }

  // Initialize Google Maps Places with an empty API key
  // The actual API calls will be routed through the backend proxy
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: '');

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Update the UI when the search text changes
    searchController.addListener(() {
      setState(() {}); // Triggers rebuild to apply filtering
    });
  }

  @override
  void dispose() {
    searchController.dispose(); // Dispose controller when widget is destroyed
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      currentLocation = await LocationService.getCurrentLocation();
      if (currentLocation != null) {
        setState(() {
          errorMessage = null;
        });
        await _getLocationName();
        await _fetchNearbyPlaces();
      } else {
        setState(() {
          errorMessage = "Could not determine current location.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching location: $e";
      });
    }
  }

  Future<void> _getLocationName() async {
    if (currentLocation == null) return;

    displayedLocation = await LocationService.getLocationNameFromCoordinates(
      currentLocation!.latitude,
      currentLocation!.longitude,
      platform, // Pass the platform here
    );
    setState(() {});
  }

  Future<void> _fetchNearbyPlaces(
      {String? pageToken, int groupIndex = 0}) async {
    if (currentLocation == null) return;

    try {
      final Map<String, dynamic> result = await PlaceService.fetchNearbyPlaces(
        currentLocation!.latitude,
        currentLocation!.longitude,
        platform, // Pass the platform here
        pageToken: pageToken,
        groupIndex: groupIndex,
      );

      if (result.containsKey('error')) {
        setState(() {
          errorMessage = 'Error: ${result['error']}';
        });
        return;
      }

      final List<dynamic> results = result['results'] ?? [];
      final String? newNextPageToken =
          result['next_page_token'] ?? result['nextPageToken'];
      final int? newGroupIndex = result['groupIndex'] != null
          ? int.tryParse(result['groupIndex'].toString())
          : null;

      setState(() {
        nearbyPlaces.addAll(results);

        // Update allTypes
        for (var place in results) {
          if (place['types'] != null) {
            allTypes.addAll(List<String>.from(place['types']));
          }
        }
      });

      if (newNextPageToken != null) {
        await Future.delayed(const Duration(seconds: 2));
        await _fetchNearbyPlaces(
          pageToken: newNextPageToken,
          groupIndex: groupIndex,
        );
      } else if (newGroupIndex != null) {
        await _fetchNearbyPlaces(
          groupIndex: newGroupIndex,
        );
      } else {
        setState(() {}); // Ensure UI updates after fetching all data
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  void _openFilterDialog() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          allTypes: allTypes.toList(),
          selectedTypes: selectedTypes,
        );
      },
    );

    if (selected != null) {
      setState(() {
        selectedTypes = selected;
      });
    }
  }

  // Combined filtering logic for both search text and selected types
  List<dynamic> get filteredPlaces {
    String query = searchController.text.toLowerCase();
    return nearbyPlaces.where((place) {
      // Apply search filter
      final name = place['name']?.toLowerCase() ?? '';
      final matchesSearch = name.contains(query) || query.isEmpty;

      // Apply type filter
      final types =
          place['types'] != null ? List<String>.from(place['types']) : [];
      final matchesFilter = selectedTypes.isEmpty ||
          types.any((type) => selectedTypes.contains(type));

      // Return true only if both match
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onPlaceTap(dynamic place) async {
    final placeDetails = await PlaceService.fetchPlaceDetails(
      place['place_id'],
      platform, // Pass the platform here
    );
    final phoneNumber =
        placeDetails['formatted_phone_number'] ?? 'No Phone Number';
    final openingHours = placeDetails['opening_hours']?['weekday_text'] ??
        ['No hours available'];
    final photoReference = placeDetails['photos'] != null
        ? placeDetails['photos'][0]['photo_reference']
        : null;

    final photoUrl = photoReference != null
        ? PlaceService.getPhotoUrl(photoReference, platform)
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

  void _changeLocation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Location'),
          content: SizedBox(
            width: double.maxFinite,
            child: CustomAutocompleteWidget(
              platform: platform, // Pass the platform variable here
              onPlaceSelected: (placeId) async {
                Navigator.of(context).pop(); // Close the dialog
                await _displayPrediction(placeId);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _displayPrediction(String placeId) async {
    try {
      final placeDetails = await PlaceService.fetchPlaceDetails(
        placeId,
        platform,
      );

      final double lat = placeDetails['geometry']['location']['lat'];
      final double lng = placeDetails['geometry']['location']['lng'];

      setState(() {
        currentLocation = LatLng(lat, lng);
        displayedLocation = placeDetails['name'];
        nearbyPlaces.clear();
        allTypes.clear();
        selectedTypes.clear();
      });

      await _fetchNearbyPlaces();
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching place details: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 50.0), // Adjust padding for overall layout
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (currentLocation == null) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              const Center(
                child: Text("Fetching your location...",
                    style: TextStyle(fontSize: 16)),
              ),
            ] else ...[
              const SizedBox(height: 10), // Add spacing before search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search places',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 8), // Space between search bar and filter button
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _openFilterDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                  height: 15), // Adjust spacing between search bar and content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Places near: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            displayedLocation ?? '',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2, // Allow text to wrap
                          ),
                        ),
                      ],
                    ),
                    if (displayedLocation != null) ...[
                      const SizedBox(
                          height: 5), // Space between text and button
                      Center(
                        child: TextButton(
                          onPressed: _changeLocation,
                          child: const Text(
                            'Change',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  if (filteredPlaces.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "No places found matching your search and filter criteria.",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      return PlaceListItem(
                        place: place,
                        onTap: () => _onPlaceTap(place),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
