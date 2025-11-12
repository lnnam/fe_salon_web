import 'package:flutter/material.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale'),
        backgroundColor: Colors.blue, // Set app bar color
      ),
      body: const Center(
        child: Text('Sale Screen'),
      ),
    );
  }
}