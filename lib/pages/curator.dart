import 'package:flutter/material.dart';

class Curator extends StatelessWidget {
  const Curator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curation')),
      body: const Center(
        child: Text(
          'This is the Curation Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
