import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../login/first_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  late Future<DocumentSnapshot> _userDocFuture;

  // Controllers for the editable fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _controllersInitialized = false;
  bool _isEditing = false; // Toggle between view and edit mode

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;

    if (_user != null) {
      _userDocFuture = _firestore.collection('users').doc(_user!.uid).get();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> uploadPhoto(
      Uint8List fileBytes, String fileName, String userId) async {
    try {
      // Upload the file to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/$userId/$fileName');
      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask;

      // Get the download URL of the uploaded image
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save the photo URL in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'photoURL': downloadUrl},
        SetOptions(merge: true),
      );

      print('Photo uploaded successfully: $downloadUrl');
    } catch (e) {
      print('Error uploading photo: $e');
    }
  }

  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    return await FlutterImageCompress.compressWithList(
      imageBytes,
      minHeight: 800,
      minWidth: 800,
      quality: 70, // Adjust quality to reduce file size
    );
  }

  Future<Uint8List> compressImageForWeb(Uint8List imageBytes) async {
    final completer = Completer<Uint8List>();
    final blob = html.Blob([imageBytes]);

    // Create a file reader
    final reader = html.FileReader();
    reader.readAsDataUrl(blob);

    reader.onLoadEnd.listen((_) {
      final canvas = html.CanvasElement();
      final context = canvas.context2D;

      final img = html.ImageElement();
      img.src = reader.result as String;
      img.onLoad.listen((_) {
        // Set canvas size and draw image
        canvas.width = (img.width ?? 100) ~/ 2; // Resize to 50% width
        canvas.height = (img.height ?? 100) ~/ 2; // Resize to 50% height
        context.drawImageScaled(img, 0, 0, canvas.width!, canvas.height!);

        // Convert canvas to blob
        canvas.toBlob((blob) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(blob!);
          reader.onLoadEnd.listen((_) {
            completer.complete(Uint8List.fromList(reader.result as List<int>));
          });
        } as String?);
      });
    });

    return completer.future;
  }

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      final compressedBytes = kIsWeb
          ? await compressImageForWeb(fileBytes) // Compress for Web
          : await compressImage(fileBytes); // Compress for Mobile/Desktop

      final fileName = pickedFile.name;
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        await uploadPhoto(compressedBytes, fileName, userId);
      } else {
        print('User not authenticated');
      }
    } else {
      print('No file selected');
    }
  }

  void _saveProfile() async {
    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'dob': _dobController.text.trim(),
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        setState(() {
          _isEditing = false; // Exit edit mode after saving
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userDocFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No user data found'));
        }
        Map<String, dynamic> userData =
            snapshot.data!.data() as Map<String, dynamic>;

        if (!_controllersInitialized) {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _dobController.text = userData['dob'] ?? '';
          _controllersInitialized = true;
        }

        return SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData['photoURL'] != null
                        ? CachedNetworkImageProvider(userData['photoURL'])
                        : null,
                    child: userData['photoURL'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: pickAndUploadPhoto, // Link the function here
                    child: const Text('Upload Profile Picture'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${userData['firstName'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (!_isEditing)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true; // Enter edit mode
                            });
                          },
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _firstNameController,
                          decoration:
                              const InputDecoration(labelText: 'First Name'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _lastNameController,
                          decoration:
                              const InputDecoration(labelText: 'Last Name'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _dobController,
                          decoration:
                              const InputDecoration(labelText: 'Date of Birth'),
                          textAlign: TextAlign.center,
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.tryParse(_dobController.text) ??
                                      DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _dobController.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Save'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false; // Cancel edit mode
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await _auth.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => FirstScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
