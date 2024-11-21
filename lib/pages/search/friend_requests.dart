import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatefulWidget {
  final List<String> requestsReceived;

  const FriendRequestsPage({Key? key, required this.requestsReceived})
      : super(key: key);

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late List<String> _requestsReceived;

  @override
  void initState() {
    super.initState();
    _requestsReceived = List.from(widget.requestsReceived); // Initialize list
  }

  Future<void> _acceptFriendRequest(
      String senderId, String? currentUserId) async {
    if (currentUserId == null) return;

    try {
      // Update Firestore for the current user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'followers': FieldValue.arrayUnion([senderId]),
        'requestsReceived': FieldValue.arrayRemove([senderId]),
      });

      // Update Firestore for the sender
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .update({
        'following': FieldValue.arrayUnion([currentUserId]),
        'requestsSent': FieldValue.arrayRemove([currentUserId]),
      });

      // Remove the accepted request from the UI
      setState(() {
        _requestsReceived.remove(senderId);
      });

      print('Friend request accepted!');
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> _denyFriendRequest(
      String senderId, String? currentUserId) async {
    if (currentUserId == null) return;

    try {
      // Update Firestore to remove the request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'requestsReceived': FieldValue.arrayRemove([senderId]),
      });

      // Remove the denied request from the UI
      setState(() {
        _requestsReceived.remove(senderId);
      });

      print('Friend request denied.');
    } catch (e) {
      print('Error denying friend request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: const Text('Friend Requests'),
      ),
      body: _requestsReceived.isNotEmpty
          ? ListView.builder(
              itemCount: _requestsReceived.length,
              itemBuilder: (context, index) {
                final requesterId = _requestsReceived[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(requesterId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requesterData =
                        snapshot.data!.data() as Map<String, dynamic>;

                    return Dismissible(
                      key: Key(requesterId),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          // Swipe right to accept
                          _acceptFriendRequest(requesterId,
                              FirebaseAuth.instance.currentUser?.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Friend request accepted!')),
                          );
                        } else if (direction == DismissDirection.endToStart) {
                          // Swipe left to deny
                          _denyFriendRequest(requesterId,
                              FirebaseAuth.instance.currentUser?.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Friend request denied.')),
                          );
                        }
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.green,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: requesterData['photoURL'] != null
                                ? NetworkImage(requesterData['photoURL'])
                                : null,
                            child: requesterData['photoURL'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                              requesterData['firstName'] ?? 'Unknown Name'),
                          subtitle: Text(
                              requesterData['email'] ?? 'No Email Provided'),
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(
              child: Text(
                'No friend requests.',
                style: TextStyle(fontSize: 16),
              ),
            ),
    );
  }
}
