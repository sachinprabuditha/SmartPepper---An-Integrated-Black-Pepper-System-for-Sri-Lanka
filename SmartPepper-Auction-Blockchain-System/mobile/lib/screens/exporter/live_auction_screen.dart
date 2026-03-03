import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

class LiveAuctionScreen extends StatelessWidget {
  final String auctionId;

  const LiveAuctionScreen({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('auction_live'))),
      body: Center(
        child: Text(
            '${context.tr('auction_live')}: $auctionId - Implementation Pending'),
      ),
    );
  }
}
