import 'package:flutter/material.dart';
import 'calendar.dart'; // Import the calendar screen

class PlanTab extends StatelessWidget {
  const PlanTab({Key? key}) : super(key: key);

  void _planWithAI(BuildContext context) {
    // Show a dialog to select default or custom preferences
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Plan with AI'),
          content: const Text(
              'Would you like to use default preferences or customize your plan?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Use default preferences to generate itinerary
                _generateItinerary(context, useCustomPreferences: false);
              },
              child: const Text('Default Preferences'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to the custom preferences survey
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomPreferencesSurvey(),
                  ),
                );
              },
              child: const Text('Custom Preferences'),
            ),
          ],
        );
      },
    );
  }

  void _generateItinerary(BuildContext context,
      {required bool useCustomPreferences}) {
    // Simulate itinerary generation
    final itinerary = useCustomPreferences
        ? 'Custom Itinerary: Morning Date -> Afternoon Date -> Evening Date'
        : 'Default Itinerary: Cafe -> Park -> Dinner at a Bar';

    // Show the generated itinerary
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generated Itinerary'),
          content: Text(itinerary),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

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
                  _planWithAI(context);
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
          const Center(
            child: Text(
              'Your plans will be shown here.',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomPreferencesSurvey extends StatefulWidget {
  const CustomPreferencesSurvey({Key? key}) : super(key: key);

  @override
  _CustomPreferencesSurveyState createState() =>
      _CustomPreferencesSurveyState();
}

class _CustomPreferencesSurveyState extends State<CustomPreferencesSurvey> {
  String _timeOfDay = 'Morning'; // Default value
  String _duration = 'Short (2-3 hours)';
  String _dayType = 'Weekday';

  final List<String> _timeOptions = ['Morning', 'Afternoon', 'Evening'];
  final List<String> _durationOptions = [
    'Short (2-3 hours)',
    'Half Day',
    'Full Day'
  ];
  final List<String> _dayTypeOptions = ['Weekday', 'Weekend'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Preferences Survey'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'When would you like your date?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _timeOfDay,
              items: _timeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _timeOfDay = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Duration of the date:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _duration,
              items: _durationOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _duration = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Day of the date:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _dayType,
              items: _dayTypeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _dayType = value!;
                });
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Use the preferences to generate the itinerary
                  final preferences = {
                    'timeOfDay': _timeOfDay,
                    'duration': _duration,
                    'dayType': _dayType,
                  };
                  Navigator.pop(context); // Return to the previous screen
                  _showGeneratedItinerary(context, preferences);
                },
                child: const Text('Submit Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneratedItinerary(
      BuildContext context, Map<String, String> preferences) {
    // Example itinerary generation logic
    final itinerary = '''
    Itinerary based on preferences:
    - ${preferences['timeOfDay']} activity
    - Duration: ${preferences['duration']}
    - Day Type: ${preferences['dayType']}
    ''';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generated Itinerary'),
          content: Text(itinerary),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
