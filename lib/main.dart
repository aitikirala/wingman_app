// main.dart
// Define platform-specific API keys
// final String apiKeyIOS = 'AIzaSyAnjiYYRSdcwj_l_hKb0yoHk0Yjj65V1ug';
// final String apiKeyAndroid = 'AIzaSyDmEgeulLM-j_ARIW4lZkF9yLNxkUs0HB8';
// final String apiKeyWeb = 'AIzaSyCzqFR9Ia-8H1M-fxaJ49EDld3aghn-6ps';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/first_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the background color using the hex code FFC300
    final Color backgroundColor = Color(0xFFFF88379);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // Set the primary color to the background color
        primaryColor: backgroundColor,
        // Set the scaffold background color
        scaffoldBackgroundColor: backgroundColor,
        // Update the color scheme to use the background color
        colorScheme: ColorScheme.fromSeed(
          seedColor: backgroundColor,
          brightness: Brightness.light, // You can adjust brightness if needed
        ),
        useMaterial3: true,
      ),
      home: FirstScreen(),
    );
  }
}
