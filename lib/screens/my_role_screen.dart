import 'package:flutter/material.dart';

class MyRoleScreen extends StatelessWidget {
  final String role;

  const MyRoleScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Role'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          role.isEmpty ? 'Role not set' : role,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}