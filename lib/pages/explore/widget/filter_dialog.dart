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
    return AlertDialog(
      title: const Text('Filter by Type'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.allTypes.map((type) {
            return CheckboxListTile(
              title: Text(type),
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
