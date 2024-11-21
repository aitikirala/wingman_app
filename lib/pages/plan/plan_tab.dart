import 'package:flutter/material.dart';
import 'calendar.dart'; // Import the calendar screen

class PlanTab extends StatelessWidget {
  const PlanTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 50,
            right: 16,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              tooltip: 'Add Plan',
              onSelected: (value) {
                if (value == 'plan_ai') {
                  // Add functionality for Plan with AI
                  print('Plan with AI selected');
                } else if (value == 'create_own') {
                  // Navigate to the Calendar screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Calendar(),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'plan_ai',
                  child: ListTile(
                    leading: Icon(Icons.smart_toy),
                    title: Text('Plan with AI'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'create_own',
                  child: ListTile(
                    leading: Icon(Icons.edit_calendar),
                    title: Text('Create Your Own'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 66, // 10 points below the + button
            left: 16,
            child: const Text(
              'Your Itineraries',
              style: TextStyle(
                fontSize: 24, // Adjust font size as needed
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: const Text(
              'Your plans will be shown here.',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
