import 'package:flutter/material.dart';

class TraceabilityScreen extends StatelessWidget {
  final String lotId;

  const TraceabilityScreen({super.key, required this.lotId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traceability')),
      body: Center(
        child: Text('Traceability: $lotId - Implementation Pending'),
      ),
    );
  }
}
