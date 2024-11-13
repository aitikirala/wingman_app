// home_tab.dart
import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Home Tab Here',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
