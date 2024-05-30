import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  // Requiring the list of todos.
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      //passing in the ListView.builder
      body: ListView.builder(
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('test'),
          );
        },
      ),
    );
  }
}