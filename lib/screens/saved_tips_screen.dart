import 'package:flutter/material.dart';

class SavedTipsScreen extends StatelessWidget {
  final List<String> savedTips;

  const SavedTipsScreen({required this.savedTips});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Tips'),
        backgroundColor: Colors.green,
      ),
      body: savedTips.isEmpty
          ? Center(child: Text('No saved tips found'))
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: savedTips.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(savedTips[index]),
                  ),
                );
              },
            ),
    );
  }
}