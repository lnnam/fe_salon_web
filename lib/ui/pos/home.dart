import 'package:flutter/material.dart';
import 'package:salonappweb/constants.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale'),
        backgroundColor: const Color(COLOR_PRIMARY), // Set app bar color
      ),
      body: const Center(
        child: Text('Sale Screen'),
      ),
    );
  }
}
