// main_screen.dart
import 'package:flutter/material.dart';

import 'explore_tab.dart';
import 'profile_tab.dart';
import 'home_tab.dart';
import 'plan_tab.dart';

class NavbarSetup extends StatefulWidget {
  const NavbarSetup({Key? key}) : super(key: key);

  @override
  State<NavbarSetup> createState() => _NavbarSetupState();
}

class _NavbarSetupState extends State<NavbarSetup> {
  int _selectedIndex = 0;

  // List of widgets for each tab
  static List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    ExploreTab(),
    PlanTab(),
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
        backgroundColor: Color(0xFFFF88379), // Corrected color
        type: BottomNavigationBarType.fixed, // Prevents shifting colors
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white, // Ensure it contrasts with background
        unselectedItemColor: const Color.fromARGB(
            172, 68, 69, 71), // Lighter shade for unselected
        onTap: _onItemTapped,
      ),
    );
  }
}
