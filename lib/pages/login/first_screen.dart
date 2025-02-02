// home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../navbar_setup.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;

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
  Widget build(BuildContext context) {
    return _user != null
        ? NavbarSetup()
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, // Starting point of the gradient
                end: Alignment.bottomCenter, // Ending point of the gradient
                colors: [
                  Color(0xFFFF8379), // Coral
                  Color(0xFFFFE5B4), // Light Peach
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Wingman",
                  style: TextStyle(
                    fontSize: 36, // Adjust font size as needed
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    decoration: TextDecoration.none, // Remove any underline
                  ),
                ),
                SizedBox(height: 40), // Space between title and sign-in options
                Center(child: _signInOptions()),
              ],
            ),
          );
  }

  Widget _signInOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Custom Google Sign-In button with the Google logo
        Container(
          width: 300, // Set a fixed width for consistency
          height: 50, // Fixed height for both buttons
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30), // Match button radius
            border: Border.all(color: Colors.white, width: 2), // White border
          ),
          child: ElevatedButton(
            onPressed: _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Transparent background
              elevation: 0, // Remove button shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  './lib/assests/images/google_logo.png',
                  height: 24, // Adjust size as needed
                ),
                SizedBox(width: 10),
                Text(
                  "Sign in with Google",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10), // Space between buttons
        // Sign in with Phone Number button
        Container(
          width: 300,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2), // White border
          ),
          child: ElevatedButton.icon(
            onPressed: _showPhoneSignInDialog,
            icon: Icon(Icons.phone, color: Colors.white), // Phone Icon
            label: Text('Sign in with Phone Number',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Transparent background
              elevation: 0, // Remove button shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhoneSignInDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController phoneNumberController =
            TextEditingController();
        final TextEditingController smsCodeController = TextEditingController();
        String? verificationId;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void sendCodeToPhoneNumber() async {
              String phoneNumber = phoneNumberController.text.trim();
              if (phoneNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter phone number')));
                return;
              }
              await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: phoneNumber,
                verificationCompleted: (PhoneAuthCredential credential) async {
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  Navigator.pop(context); // Close dialog on success
                },
                verificationFailed: (FirebaseAuthException e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Verification failed: ${e.message}')));
                },
                codeSent: (String vId, int? resendToken) {
                  setState(() {
                    verificationId = vId;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Verification code sent')));
                },
                codeAutoRetrievalTimeout: (String vId) {
                  verificationId = vId;
                },
              );
            }

            void signInWithPhoneNumber() async {
              String smsCode = smsCodeController.text.trim();
              if (verificationId == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please request verification code first')));
                return;
              }
              if (smsCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter verification code')));
                return;
              }
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: verificationId!, smsCode: smsCode);
                await FirebaseAuth.instance.signInWithCredential(credential);
                Navigator.pop(context); // Close dialog on success
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to sign in: ${e.toString()}')));
              }
            }

            return AlertDialog(
              title: Text('Phone Sign-In'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1 123-456-7890',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: sendCodeToPhoneNumber,
                      child: Text('Send Code'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: smsCodeController,
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: signInWithPhoneNumber,
                      child: Text('Verify Code'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog without action
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      String? clientId;

      if (kIsWeb) {
        clientId =
            "669294062001-13fjec4k4jl5ucdb62eva2qo9va6ku0l.apps.googleusercontent.com";
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        clientId =
            "669294062001-i8jnjtmn6b8ki4qqddkgb003uuuq295r.apps.googleusercontent.com";
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        clientId =
            "669294062001-13fjec4k4jl5ucdb62eva2qo9va6ku0l.apps.googleusercontent.com";
      } else {
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
        // Extract first and last names
        String? displayName = user.displayName;
        String? firstName;
        String? lastName;

        if (displayName != null) {
          List<String> nameParts = displayName.split(' ');
          if (nameParts.length > 1) {
            firstName = nameParts.first;
            lastName = nameParts.sublist(1).join(' ');
          } else {
            firstName = displayName;
            lastName = '';
          }
        }

        // Store user data in Firestore without overwriting existing fields
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastSignInTime': FieldValue.serverTimestamp(),
          'provider': 'google',
          'favorites': FieldValue.arrayUnion([]),
          'followers': FieldValue.arrayUnion([]),
          'requestsSent': FieldValue.arrayUnion([]),
          'requestsReceived': FieldValue.arrayUnion([]),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
    }
  }
}
