// widgets/place_list_item.dart

import 'package:flutter/material.dart';
import 'package:wingman_app/pages/explore/service/place_service.dart';

class PlaceListItem extends StatelessWidget {
  final dynamic place;
  final VoidCallback onTap;

  const PlaceListItem({
    Key? key,
    required this.place,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final photoReference =
        place['photos'] != null ? place['photos'][0]['photo_reference'] : null;

    // Platform is not needed here as getPhotoUrl now uses the server URL
    final photoUrl = photoReference != null
        ? PlaceService.getPhotoUrl(photoReference, 'web')
        : null;

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
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
