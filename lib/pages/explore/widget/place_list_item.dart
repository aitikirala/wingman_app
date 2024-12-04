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
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        print("User document does not exist!");
        return;
      }

      final favorites =
          List<Map<String, dynamic>>.from(snapshot.data()?['favorites'] ?? []);

      final favoriteData = {
        'name': widget.place['name'] ?? 'Unknown Name',
        'address': widget.place['location']['formatted_address'] ??
            widget.place['location']['address'] ??
            'Unknown Address',
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
    setState(() {
      isFavorite = !isFavorite;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in!');
      setState(() {
        isFavorite = !isFavorite;
      });
      return;
    }

    final userId = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    final favoriteData = {
      'name': widget.place['name'] ?? 'Unknown Name',
      'address': widget.place['location']['formatted_address'] ??
          widget.place['location']['address'] ??
          'Unknown Address',
    };

    try {
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        print("User document does not exist!");
        return;
      }

      final favorites =
          List<Map<String, dynamic>>.from(snapshot.data()?['favorites'] ?? []);

      final exists = favorites.any((favorite) =>
          favorite['name'] == favoriteData['name'] &&
          favorite['address'] == favoriteData['address']);

      if (exists) {
        await userDoc.update({
          'favorites': FieldValue.arrayRemove([favoriteData]),
        });
        setState(() {
          isFavorite = false;
        });
        print('Removed from favorites.');
      } else {
        await userDoc.update({
          'favorites': FieldValue.arrayUnion([favoriteData]),
        });
        setState(() {
          isFavorite = true;
        });
        print('Added to favorites.');
      }
    } catch (e) {
      print("Error updating favorites: $e");
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract photo URL
    final photo =
        widget.place['photos'] != null && widget.place['photos'].isNotEmpty
            ? widget.place['photos'][0]
            : null;

    String? photoUrl;

    if (photo != null) {
      final prefix = photo['prefix'];
      final suffix = photo['suffix'];
      // You can specify a size or use 'original'
      final size = '200x200'; // Or 'original'
      photoUrl = '$prefix$size$suffix';
    }

    final rating = widget.place['rating'];
    final name = widget.place['name'] ?? 'No Name';
    final address = widget.place['location']['formatted_address'] ??
        widget.place['location']['address'] ??
        'No Address';

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
                    const SizedBox(height: 8),
                    if (rating != null)
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
