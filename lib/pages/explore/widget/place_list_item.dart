// place_item.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PlaceListItem extends StatefulWidget {
  final dynamic place;
  final VoidCallback onTap;

  const PlaceListItem({
    Key? key,
    required this.place,
    required this.onTap,
  }) : super(key: key);

  @override
  _PlaceListItemState createState() => _PlaceListItemState();
}

class _PlaceListItemState extends State<PlaceListItem> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    checkIfFavorite();
  }

  void checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in!');
      return;
    }

    final userId = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      // Fetch the user's favorites
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        print("User document does not exist!");
        return;
      }

      final favorites =
          List<Map<String, dynamic>>.from(snapshot.data()?['favorites'] ?? []);

      // Adjust the favoriteData to match the OpenStreetMap data structure
      final favoriteData = {
        'name': widget.place['tags']['name'] ?? 'Unknown Name',
        'address': widget.place['tags']['addr:full'] ??
            widget.place['tags']['addr:street'] ??
            'Unknown Address',
      };

      // Check if the current place exists in favorites
      final exists = favorites.any((favorite) =>
          favorite['name'] == favoriteData['name'] &&
          favorite['address'] == favoriteData['address']);

      setState(() {
        isFavorite = exists;
      });
    } catch (e) {
      print("Error checking favorites: $e");
    }
  }

  void toggleFavorite() async {
    // Optimistically update UI
    setState(() {
      isFavorite = !isFavorite;
    });

    // Get the currently logged-in user's ID
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in!');
      setState(() {
        isFavorite = !isFavorite; // Revert the state
      });
      return;
    }

    final userId = user.uid; // Use the user's ID as the document ID
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    // Create the data to be added/removed to/from the favorites array
    final favoriteData = {
      'name': widget.place['tags']['name'] ?? 'Unknown Name',
      'address': widget.place['tags']['addr:full'] ??
          widget.place['tags']['addr:street'] ??
          'Unknown Address',
    };

    try {
      // Get the current favorites array
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        print("User document does not exist!");
        return;
      }

      final favorites =
          List<Map<String, dynamic>>.from(snapshot.data()?['favorites'] ?? []);

      // Check if the item already exists in the array
      final exists = favorites.any((favorite) =>
          favorite['name'] == favoriteData['name'] &&
          favorite['address'] == favoriteData['address']);

      if (exists) {
        // If it exists, remove it
        await userDoc.update({
          'favorites': FieldValue.arrayRemove([favoriteData]),
        });
        setState(() {
          isFavorite = false; // Update UI state
        });
        print('Removed from favorites.');
      } else {
        // If it doesn’t exist, add it
        await userDoc.update({
          'favorites': FieldValue.arrayUnion([favoriteData]),
        });
        setState(() {
          isFavorite = true; // Update UI state
        });
        print('Added to favorites.');
      }
    } catch (e) {
      print("Error updating favorites: $e");
      setState(() {
        isFavorite =
            !isFavorite; // Revert the state change if there is an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Since OpenStreetMap does not provide photos, we'll skip photo handling
    // You can use a placeholder image or an icon instead

    final name = widget.place['tags']['name'] ?? 'No Name';
    final address = widget.place['tags']['addr:full'] ??
        widget.place['tags']['addr:street'] ??
        'No Address';

    // Since OpenStreetMap does not provide ratings, we can omit that part or set a default
    final rating = widget.place['tags']['rating'] ?? 'No Rating';

    return InkWell(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              6.0, 16.0, 16.0, 16.0), // Less left padding
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: toggleFavorite,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    // If you want to include rating, you can add it here
                    /*
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    */
                  ],
                ),
              ),
              // Since we don't have photos, you might display an icon or skip this
              /*
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.place, size: 50, color: Colors.blue),
              ),
              */
            ],
          ),
        ),
      ),
    );
  }
}
