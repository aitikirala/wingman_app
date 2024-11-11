import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;

  // Controllers and variables for phone authentication
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _smsCodeController = TextEditingController();

  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((event) {
      setState(() {
        _user = event;
      });
    });
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _user != null
        ? MainScreen()
        : Scaffold(
            appBar: AppBar(
              title: const Text("Sign-In"),
            ),
            body: _signInOptions(),
          );
  }

  Widget _signInOptions() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Sign-In button
            SizedBox(
              height: 50,
              child: SignInButton(
                Buttons.google,
                text: "Sign in with Google",
                onPressed: _handleGoogleSignIn,
              ),
            ),
            SizedBox(height: 20),
            // Phone Sign-In fields and buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendCodeToPhoneNumber,
              child: Text('Send Code'),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _smsCodeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _signInWithPhoneNumber,
              child: Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      String? clientId;

      if (kIsWeb) {
        // Web Client ID
        clientId =
            "669294062001-13fjec4k4jl5ucdb62eva2qo9va6ku0l.apps.googleusercontent.com";
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS Client ID
        clientId =
            "669294062001-i8jnjtmn6b8ki4qqddkgb003uuuq295r.apps.googleusercontent.com";
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // For Android, you typically don't need to specify the clientId
        clientId =
            "669294062001-13fjec4k4jl5ucdb62eva2qo9va6ku0l.apps.googleusercontent.com";
      } else {
        // Other platforms (e.g., macOS, Windows)
        clientId = null;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: clientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Get the current user
      User? user = _auth.currentUser;

      if (user != null) {
        // Store user data in Firestore without overwriting existing fields
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastSignInTime': FieldValue.serverTimestamp(),
          'provider': 'google',
        }, SetOptions(merge: true));
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
    }
  }

  void _sendCodeToPhoneNumber() async {
    String phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter phone number')));
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in on Android
        await _auth.signInWithCredential(credential);

        // Get the current user
        User? user = _auth.currentUser;

        if (user != null) {
          // Store user data in Firestore without overwriting existing fields
          await _firestore.collection('users').doc(user.uid).set({
            'phoneNumber': user.phoneNumber,
            'lastSignInTime': FieldValue.serverTimestamp(),
            'provider': 'phone',
          }, SetOptions(merge: true));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Verification code sent')));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _signInWithPhoneNumber() async {
    String smsCode = _smsCodeController.text.trim();
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please request verification code first')));
      return;
    }
    if (smsCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter verification code')));
      return;
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: smsCode);
      await _auth.signInWithCredential(credential);

      // Get the current user
      User? user = _auth.currentUser;

      if (user != null) {
        // Store user data in Firestore without overwriting existing fields
        await _firestore.collection('users').doc(user.uid).set({
          'phoneNumber': user.phoneNumber,
          'lastSignInTime': FieldValue.serverTimestamp(),
          'provider': 'phone',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: ${e.toString()}')));
    }
  }
}

// New MainScreen Widget with BottomNavigationBar
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of widgets for each tab
  static List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // Placeholder tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}

// HomeTab Widget
class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder content for the Home tab
    return Center(
      child: Text(
        'Welcome to the Home Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

// ProfileTab Widget
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

  void _saveProfile() async {
    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'dob': _dobController.text.trim(),
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated')),
        );
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
          // Show a loading indicator while fetching data
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If user data doesn't exist, show a message
          return Center(child: Text('No user data found'));
        }
        Map<String, dynamic> userData =
            snapshot.data!.data() as Map<String, dynamic>;

        // Initialize controllers if not already initialized
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
                // Center all elements
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  if (userData['photoURL'] != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(userData['photoURL']),
                    ),
                  SizedBox(height: 20),
                  Text(
                    userData['displayName'] ?? '',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    userData['email'] ?? userData['phoneNumber'] ?? '',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  // Editable TextFields for First Name, Last Name, and DOB
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(labelText: 'First Name'),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(labelText: 'Last Name'),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _dobController,
                    decoration: InputDecoration(labelText: 'Date of Birth'),
                    textAlign: TextAlign.center,
                    readOnly: true, // To use a DatePicker
                    onTap: () async {
                      // Show DatePicker when tapped
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_dobController.text) ??
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _auth.signOut();
                      // Navigate back to the sign-in screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text('Sign Out'),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
