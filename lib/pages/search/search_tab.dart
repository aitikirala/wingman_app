import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wingman_app/pages/search/friend_requests.dart';
import 'package:wingman_app/pages/search/view_profile.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  _SearchTabState createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;

  bool hasNotifications = false; // Tracks if there are any friend requests

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
    _listenForFriendRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listenForFriendRequests() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final requestsReceived =
            List<String>.from(snapshot.data()?['requestsReceived'] ?? []);
        setState(() {
          hasNotifications = requestsReceived.isNotEmpty;
        });
      }
    });
  }

  Future<void> fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in!');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userId = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        final fetchedFavorites = List<Map<String, dynamic>>.from(
          snapshot.data()?['favorites'] ?? [],
        );
        setState(() {
          favorites = fetchedFavorites;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void showDetailsDialog(BuildContext context, Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                place['name'] ?? 'Unknown Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (place['photoUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    place['photoUrl'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              if (place['vicinity'] != null)
                Row(
                  children: [
                    const Icon(Icons.location_pin, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place['vicinity'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              if (place['phone'] != null)
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      place['phone'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              if (place['rating'] != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow),
                    const SizedBox(width: 8),
                    Text(
                      place['rating'].toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              if (place['hours'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opening Hours:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.from(
                        (place['hours'] as List<dynamic>).map(
                          (hour) => Text(
                            hour,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _searchUser() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResult = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: query)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Try searching by phone number if no email match
        final phoneSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: query)
            .get();

        if (phoneSnapshot.docs.isNotEmpty) {
          setState(() {
            _searchResult = phoneSnapshot.docs.first.data();
            _searchResult!['uid'] = phoneSnapshot.docs.first.id;
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResult = null;
            _isSearching = false;
          });
        }
      } else {
        setState(() {
          _searchResult = querySnapshot.docs.first.data();
          _searchResult!['uid'] = querySnapshot.docs.first.id;
          _isSearching = false;
        });
      }
    } catch (e) {
      print("Error searching user: $e");
      setState(() {
        _searchResult = null;
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(String friendId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add friends')),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    try {
      // Add the friend to the current user's requestsSent list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'requestsSent': FieldValue.arrayUnion([friendId])
      });

      // Add the current user to the friend's requestsReceived list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .update({
        'requestsReceived': FieldValue.arrayUnion([currentUserId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e) {
      print("Error sending friend request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to send friend request. Please try again.')),
      );
    }
  }

  Widget _buildSearchResult() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResult != null) {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return const Text('Please log in to search users.');
      }

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserData = snapshot.data!.data() as Map<String, dynamic>;
          final currentUserFollowing =
              List<String>.from(currentUserData['following'] ?? []);
          final requestsSent =
              List<String>.from(currentUserData['requestsSent'] ?? []);
          final recipientId = _searchResult!['uid'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(recipientId)
                .get(),
            builder: (context, recipientSnapshot) {
              if (!recipientSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final recipientData =
                  recipientSnapshot.data!.data() as Map<String, dynamic>;
              final isFollowing = currentUserFollowing.contains(recipientId);
              final isRequestSent = requestsSent.contains(recipientId);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: isFollowing
                      ? () {
                          // Navigate to the recipient's profile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewProfile(
                                userId: recipientId,
                              ),
                            ),
                          );
                        }
                      : null, // Disable tap if not following
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_searchResult!['photoURL'] != null)
                            CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  NetworkImage(_searchResult!['photoURL']),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _searchResult!['firstName'] ?? 'Unknown Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchResult!['email'] ??
                                _searchResult!['phoneNumber'] ??
                                '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          if (isFollowing)
                            const Text(
                              'Following',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )
                          else if (isRequestSent)
                            ElevatedButton(
                              onPressed: () => _showWaitingDialog(),
                              child: const Text('Waiting'),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _sendFriendRequest(recipientId),
                              child: const Text('Add Friend'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'No user found',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by email or phone number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUser,
                ),
              ),
              onSubmitted: (_) => _searchUser(),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mail),
                onPressed: _showFriendRequests,
              ),
              if (hasNotifications)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFriendRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userId = currentUser.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final requestsReceived =
          List<String>.from(userDoc.data()?['requestsReceived'] ?? []);

      // Navigate to the Friend Requests Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FriendRequestsPage(
            requestsReceived: requestsReceived,
          ),
        ),
      );
    }
  }

  Future<void> _sendFriendRequest(String recipientId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to send friend requests')),
      );
      return;
    }

    final currentUserId = currentUser.uid;

    try {
      // Add the current user's ID to the recipient's requestsReceived array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientId)
          .update({
        'requestsReceived': FieldValue.arrayUnion([currentUserId])
      });

      // Add the recipient's ID to the current user's requestsSent array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'requestsSent': FieldValue.arrayUnion([recipientId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e) {
      print("Error sending friend request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to send friend request. Please try again.')),
      );
    }
  }

  void _showWaitingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Friend Request Sent'),
          content: const Text(
              'You have already sent a friend request. We are waiting on their response.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 50), // Adds spacing at the top
      _buildSearchBar(),
      _buildSearchResult(),
      const SizedBox(height: 20),
    ]);
  }
}
