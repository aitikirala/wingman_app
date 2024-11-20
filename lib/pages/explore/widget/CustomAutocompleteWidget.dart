import 'package:flutter/material.dart';
import 'package:wingman_app/pages/explore/service/place_service.dart';

class CustomAutocompleteWidget extends StatefulWidget {
  final Function(String placeId) onPlaceSelected;
  final String platform; // Add platform as a parameter

  const CustomAutocompleteWidget({
    Key? key,
    required this.onPlaceSelected,
    required this.platform, // Make platform required
  }) : super(key: key);

  @override
  _CustomAutocompleteWidgetState createState() =>
      _CustomAutocompleteWidgetState();
}

class _CustomAutocompleteWidgetState extends State<CustomAutocompleteWidget> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _suggestions = [];

  void _onTextChanged(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      // Pass widget.platform as the second argument
      final results = await PlaceService.fetchAutocompleteSuggestions(
          input, widget.platform);
      setState(() {
        _suggestions = results;
      });
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() {
        _suggestions = [
          {
            'description': 'Error fetching suggestions. Please try again.',
            'place_id': ''
          }
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Enter location',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _onTextChanged,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                title: Text(suggestion['description']),
                onTap: () {
                  widget.onPlaceSelected(suggestion['place_id']);
                  _controller.clear();
                  setState(() {
                    _suggestions = [];
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
