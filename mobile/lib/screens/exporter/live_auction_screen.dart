import 'package:flutter/material.dart';

class LiveAuctionScreen extends StatelessWidget {
  final String auctionId;

  const LiveAuctionScreen({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Auction')),
      body: Center(
        child: Text('Live Auction: $auctionId - Implementation Pending'),
      ),
    );
  }
}
