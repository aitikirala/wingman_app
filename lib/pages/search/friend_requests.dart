import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatelessWidget {
  final List<String> requestsReceived;

  const FriendRequestsPage({Key? key, required this.requestsReceived})
      : super(key: key);

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
      body: requestsReceived.isNotEmpty
          ? ListView.builder(
              itemCount: requestsReceived.length,
              itemBuilder: (context, index) {
                final requesterId = requestsReceived[index];
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

                    return Card(
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
                        title:
                            Text(requesterData['firstName'] ?? 'Unknown Name'),
                        subtitle:
                            Text(requesterData['email'] ?? 'No Email Provided'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _acceptFriendRequest(requesterId);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                _denyFriendRequest(requesterId);
                              },
                            ),
                          ],
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

  Future<void> _acceptFriendRequest(String senderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    try {
      // Add sender to current user's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'friends': FieldValue.arrayUnion([senderId]),
        'requestsReceived': FieldValue.arrayRemove([senderId])
      });

      // Add current user to sender's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .update({
        'friends': FieldValue.arrayUnion([currentUserId]),
        'requestsSent': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> _denyFriendRequest(String senderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    try {
      // Remove sender from current user's requestsReceived list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'requestsReceived': FieldValue.arrayRemove([senderId]),
      });
    } catch (e) {
      print('Error denying friend request: $e');
    }
  }
}
