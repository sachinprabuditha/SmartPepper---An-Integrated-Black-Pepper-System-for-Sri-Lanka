import 'package:flutter/material.dart';

class LotDetailsScreen extends StatelessWidget {
  final String lotId;

  const LotDetailsScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lot Details')),
      body: Center(child: Text('Lot Details: $lotId - Implementation Pending')),
    );
  }
}
