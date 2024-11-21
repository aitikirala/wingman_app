import 'package:flutter/material.dart';

class Calendar extends StatelessWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of time slots from 12 AM to 11 PM
    final timeSlots = List.generate(24, (index) {
      final hour = index % 12 == 0 ? 12 : index % 12; // 12-hour format
      final period = index < 12 ? 'AM' : 'PM';
      return '$hour $period';
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Schedule'),
      ),
      body: ListView.builder(
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Text(
              timeSlots[index],
              style: const TextStyle(fontSize: 18),
            ),
            title: const TextField(
              decoration: InputDecoration(
                hintText: 'Add task or event',
                border: OutlineInputBorder(),
              ),
            ),
          );
        },
      ),
    );
  }
}
