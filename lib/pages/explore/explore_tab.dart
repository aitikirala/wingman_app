// explore_tab.dart

import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // May not be needed anymore
import 'package:wingman_app/pages/explore/service/location_service.dart';
import 'package:wingman_app/pages/explore/service/place_service.dart';
import 'package:wingman_app/pages/explore/widget/CustomAutocompleteWidget.dart';
import 'package:wingman_app/pages/explore/widget/filter_dialog.dart';
import 'package:wingman_app/pages/explore/widget/place_list_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  String? sessionId; // Session ID for caching
  final TextEditingController searchController =
      TextEditingController(); // Search bar controller

  Set<String> selectedTypes = Set();
  Set<String> allTypes = Set();

  List<dynamic> favorites = []; // Holds favorite places
  bool isLoadingFavorites = true; // Tracks loading state for favorites

  // Scroll controller for detecting when the user scrolls to the bottom
  ScrollController _scrollController = ScrollController();

  // Variables to manage pagination and loading state
  int currentGroupIndex = 0;
  int currentRadius = 1600; // Initial radius in meters
  bool hasMoreData = true;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initializeSessionAndLocation();
    searchController.addListener(() {
      setState(() {}); // Triggers rebuild to apply filtering
    });

    _scrollController.addListener(_onScroll);

    _listenToFavorites(); // Set up the listener
  }

  @override
  void dispose() {
    searchController.dispose(); // Dispose controller when widget is destroyed
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreData) {
      // User has scrolled near the bottom
      _fetchMorePlaces();
    }
  }

  Future<void> _initializeSessionAndLocation() async {
    try {
      await _startSession();
      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing session or location: $e';
      });
    }
  }

  Future<void> _startSession() async {
    try {
      final response = await http
          .get(Uri.parse('${PlaceService.serverUrl}/api/proxy/startSession'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        sessionId = data['sessionId'];
      } else {
        throw Exception(
            'Failed to start session. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting session: $e');
    }
  }

  void _listenToFavorites() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          favorites = snapshot.data()?['favorites'] ?? [];
          isLoadingFavorites = false;
        });
      } else {
        setState(() {
          favorites = [];
          isLoadingFavorites = false;
        });
      }
    }, onError: (e) {
      print('Error listening to favorites: $e');
      setState(() {
        favorites = [];
        isLoadingFavorites = false;
      });
    });
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
    );
    setState(() {});
  }

  Future<void> _fetchNearbyPlaces({int? groupIndex, int? radius}) async {
    if (currentLocation == null || sessionId == null) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final Map<String, dynamic> result = await PlaceService.fetchNearbyPlaces(
        currentLocation!.latitude,
        currentLocation!.longitude,
        radius: radius ?? currentRadius,
        groupIndex: groupIndex ?? currentGroupIndex,
        sessionId: sessionId,
      );

      if (result.containsKey('error')) {
        setState(() {
          errorMessage = 'Error: ${result['error']}';
        });
        return;
      }

      final List<dynamic> results = result['results'] ?? [];
      final int? newGroupIndex = result['groupIndex'] != null
          ? int.tryParse(result['groupIndex'].toString())
          : null;
      final int? newRadius = result['radius'] != null
          ? int.tryParse(result['radius'].toString())
          : null;

      setState(() {
        // Add new places to the list
        nearbyPlaces.addAll(results);

        // Update allTypes
        for (var place in results) {
          if (place['categories'] != null) {
            List<dynamic> categories = place['categories'];
            List<String> placeTypes =
                categories.map((cat) => cat['name'] as String).toList();
            allTypes.addAll(placeTypes);
          }
        }

        // Update currentGroupIndex and currentRadius for next fetch
        if (newGroupIndex != null) {
          currentGroupIndex = newGroupIndex;
        }

        if (newRadius != null) {
          currentRadius = newRadius;
        }

        // If both newGroupIndex and newRadius are null, no more data
        if (newGroupIndex == null && newRadius == null) {
          hasMoreData = false;
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchMorePlaces() async {
    if (!hasMoreData || isLoadingMore) return;

    await _fetchNearbyPlaces();
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
      List<String> types = [];
      if (place['categories'] != null) {
        List<dynamic> categories = place['categories'];
        types = categories.map((cat) => cat['name'] as String).toList();
      }
      final matchesFilter = selectedTypes.isEmpty ||
          types.any((type) => selectedTypes.contains(type));

      // Return true only if both match
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onPlaceTap(dynamic place) async {
    try {
      final placeId = place['fsq_id'];
      final placeDetails = await PlaceService.fetchPlaceDetails(placeId);

      final name = placeDetails['name'] ?? 'Unnamed Place';
      final address = placeDetails['location']['formatted_address'] ??
          placeDetails['location']['address'] ??
          'No Address';
      final rating = placeDetails['rating'];
      final photos = placeDetails['photos'];
      final hours = placeDetails['hours'];
      final tips = placeDetails['tips'];

      // Debugging statements
      print('hours: $hours');
      print('hours type: ${hours.runtimeType}');

      // Build photo URL if available
      String? photoUrl;
      if (photos != null && photos.isNotEmpty) {
        final photo = photos[0];
        final prefix = photo['prefix'];
        final suffix = photo['suffix'];
        final size = 'original'; // or specify size e.g., '200x200'
        photoUrl = '$prefix$size$suffix';
      }

      // Display the details in a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Center(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl != null)
                    Center(
                      child: Image.network(
                        photoUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 100);
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on, 'Address', address),
                  const SizedBox(height: 8),
                  if (rating != null)
                    _buildDetailRow(Icons.star, 'Rating', rating.toString()),
                  const SizedBox(height: 8),
                  if (hours != null)
                    _buildDetailRow(
                        Icons.access_time, 'Hours', _formatHours(hours)),
                  const SizedBox(height: 8),
                  if (tips != null && tips.isNotEmpty)
                    _buildDetailRow(
                        Icons.comment, 'Reviews', _formatTips(tips)),
                  // Add more details if available
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  _addToPlan(placeDetails);
                  Navigator.of(context).pop(); // Close dialog after adding
                },
              ),
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
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching place details: $e';
      });
    }
  }

  String _formatHours(dynamic hours) {
    if (hours != null) {
      if (hours is Map && hours['display'] != null) {
        final display = hours['display'];
        if (display is List) {
          return display.join('\n');
        } else if (display is String) {
          return display;
        } else {
          return display.toString();
        }
      } else if (hours is String) {
        return hours;
      } else {
        return hours.toString();
      }
    }
    return 'No hours available';
  }

  String _formatTips(List<dynamic> tips) {
    if (tips.isEmpty) return 'No reviews available';

    return tips.map((tip) => '- ${tip['text']}').join('\n\n');
  }

  void _addToPlan(dynamic placeDetails) {
    print('addToPlan function called with: ${placeDetails['name']}');
    // Implement your logic to add the place to the user's plan
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

  void _toggleFavorite(dynamic place) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    setState(() {
      favorites.removeWhere((fav) => fav['id'] == place['id']);
    });

    try {
      await userDoc.update({
        'favorites': FieldValue.arrayRemove([place]),
      });
    } catch (e) {
      print('Error removing favorite: $e');
    }
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
              onPlaceSelected: (suggestion) async {
                Navigator.of(context).pop(); // Close the dialog
                await _displayPrediction(suggestion);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _displayPrediction(Map<String, dynamic> suggestion) async {
    try {
      final double lat = suggestion['geometry']['lat'];
      final double lng = suggestion['geometry']['lng'];
      final name = suggestion['formatted'];

      setState(() {
        currentLocation = LatLng(lat, lng);
        displayedLocation = name;
        nearbyPlaces.clear();
        allTypes.clear();
        selectedTypes.clear();

        // Reset pagination variables
        currentGroupIndex = 0;
        currentRadius = 1600;
        hasMoreData = true;
      });

      await _fetchNearbyPlaces();
    } catch (e) {
      setState(() {
        errorMessage = 'Error setting location: $e';
      });
    }
  }

  Widget _buildFavoritesTab() {
    if (isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favorites.isEmpty) {
      return const Center(
        child: Text(
          'No favorites added yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleFavorite(favorite),
                  child:
                      const Icon(Icons.favorite, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite['name'] ?? 'Unnamed Place',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        favorite['address'] ?? 'No Address Available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Places Near You and Favorites
      child: Padding(
        padding: const EdgeInsets.only(
            top: 50.0), // Adjust padding for overall layout
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
                child: Text(
                  "Fetching your location...",
                  style: TextStyle(fontSize: 16),
                ),
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
              const SizedBox(height: 15),
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
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    if (displayedLocation != null) ...[
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
              const SizedBox(height: 15),
              TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Places Near You'),
                  Tab(text: 'Favorites'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    // Places Near You tab content
                    Builder(
                      builder: (context) {
                        if (filteredPlaces.isEmpty) {
                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: const Text(
                                "No places found matching your search and filter criteria.",
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        } else {
                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredPlaces.length + 1,
                            itemBuilder: (context, index) {
                              if (index < filteredPlaces.length) {
                                final place = filteredPlaces[index];
                                return PlaceListItem(
                                  place: place,
                                  onTap: () => _onPlaceTap(place),
                                );
                              } else {
                                // Show loading indicator or "No more data" message
                                if (isLoadingMore) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (!hasMoreData) {
                                  return Center(
                                      child: Text("No more places to show."));
                                } else {
                                  return SizedBox(); // Empty space
                                }
                              }
                            },
                          );
                        }
                      },
                    ),
                    // Favorites tab content
                    _buildFavoritesTab(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
