import 'package:flutter/material.dart';

class Cinemates extends StatelessWidget {
  const Cinemates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinemaes')),
      body: const Center(
        child: Text(
          'This is the Cinemates Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
