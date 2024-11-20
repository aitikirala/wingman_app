import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wingman_app/pages/explore/service/place_service.dart';

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

      // Check if the current place exists in favorites
      final favoriteData = {
        'name': widget.place['name'] ?? 'Unknown Name',
        'address': widget.place['vicinity'] ?? 'Unknown Address',
      };

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
      'name': widget.place['name'] ?? 'Unknown Name',
      'address': widget.place['vicinity'] ?? 'Unknown Address',
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
    final photoReference = widget.place['photos'] != null
        ? widget.place['photos'][0]['photo_reference']
        : null;

    final photoUrl = photoReference != null
        ? PlaceService.getPhotoUrl(photoReference, 'web')
        : null;

    final rating = widget.place['rating'];

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
                      widget.place['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.place['vicinity'] ?? 'No Address',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating != null ? rating.toString() : 'No Rating',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (photoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
