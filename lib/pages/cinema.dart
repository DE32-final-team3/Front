import 'package:flutter/material.dart';

class Cinema extends StatelessWidget {
  const Cinema({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinema')),
      body: const Center(
        child: Text(
          'This is the Cinema Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
