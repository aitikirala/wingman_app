// plan_tab.dart
import 'package:flutter/material.dart';

class PlanTab extends StatelessWidget {
  const PlanTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              // Implement the "Plan with AI" functionality here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white, // White text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    30), // Increased for full-rounded effect
                side: BorderSide(color: Colors.white), // White border
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16), // Increase padding for a pill shape
            ),
            child: const Text('Plan with AI'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Implement the "Create Your Own" functionality here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white, // White text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    30), // Increased for full-rounded effect
                side: BorderSide(color: Colors.white), // White border
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16), // Increase padding for a pill shape
            ),
            child: const Text('Create Your Own'),
          ),
        ],
      ),
    );
  }
}
