// filter_dialog.dart

import 'package:flutter/material.dart';

class FilterDialog extends StatefulWidget {
  final List<String> allTypes;
  final Set<String> selectedTypes;

  const FilterDialog({
    Key? key,
    required this.allTypes,
    required this.selectedTypes,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<String> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    // Since the types might be technical (e.g., 'restaurant', 'cafe'), consider mapping them to user-friendly labels
    Map<String, String> typeLabels = {
      'restaurant': 'Restaurant',
      'cafe': 'Cafe',
      'bar': 'Bar',
      'pub': 'Pub',
      'fast_food': 'Fast Food',
      'food_court': 'Food Court',
      'cinema': 'Cinema',
      'theatre': 'Theatre',
      'nightclub': 'Nightclub',
      'amusement_park': 'Amusement Park',
      'water_park': 'Water Park',
      'zoo': 'Zoo',
      'shop': 'Shop',
      'library': 'Library',
      'park': 'Park',
      'garden': 'Garden',
      'attraction': 'Attraction',
      'historic': 'Historic Site',
      'university': 'University',
      // Add more mappings as needed
    };

    return AlertDialog(
      title: const Text('Filter by Type'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.allTypes.map((type) {
            return CheckboxListTile(
              title: Text(typeLabels[type] ?? type),
              value: _selectedTypes.contains(type),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Reset'),
          onPressed: () {
            setState(() {
              _selectedTypes.clear();
            });
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ElevatedButton(
          child: const Text('Apply'),
          onPressed: () => Navigator.of(context).pop(_selectedTypes),
        ),
      ],
    );
  }
}
