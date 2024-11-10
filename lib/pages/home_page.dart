import 'dart:io';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google SignIn"),
      ),
      body: _user != null ? _userInfo() : _googleSignInButton(),
    );
  }

  Widget _googleSignInButton() {
    return Center(
      child: SizedBox(
        height: 50,
        child: SignInButton(
          Buttons.google,
          text: "Sign up with Google",
          onPressed: _handleGoogleSignIn,
        ),
      ),
    );
  }

  Widget _userInfo() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (_user!.photoURL != null)
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_user!.photoURL!),
                ),
              ),
            ),
          Text(_user!.email ?? ""),
          Text(_user!.displayName ?? ""),
          MaterialButton(
            color: Colors.red,
            child: const Text("Sign Out"),
            onPressed: () async {
              await _auth.signOut();
              setState(() {
                _user = null;
              });
            },
          )
        ],
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
    } catch (error) {
      print('Error during Google Sign-In: $error');
    }
  }
}
