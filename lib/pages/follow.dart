import 'package:flutter/material.dart';

class Follow extends StatelessWidget {
  const Follow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow')),
      body: const Center(
        child: Text(
          'This is the Follow Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
