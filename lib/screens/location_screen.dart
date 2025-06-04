import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  final String location;

  const LocationScreen({required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          location.isEmpty ? 'Location not set' : location,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}