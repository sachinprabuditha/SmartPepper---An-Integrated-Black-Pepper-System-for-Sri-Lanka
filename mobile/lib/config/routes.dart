import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/farmer/farmer_dashboard.dart';
import '../screens/exporter/exporter_dashboard.dart';
import '../screens/auth/wallet_connect_screen.dart';
import '../screens/farmer/create_lot_screen.dart';
import '../screens/farmer/my_lots_screen.dart';
import '../screens/farmer/notifications_screen.dart';
import '../screens/farmer/auction_monitor_screen.dart';
import '../screens/exporter/browse_lots_screen.dart';
import '../screens/exporter/live_auction_screen.dart';
import '../screens/shared/lot_details_screen.dart';
import '../screens/shared/traceability_screen.dart';
import '../screens/shared/qr_scanner_screen.dart';
import '../screens/shared/auctions_screen.dart';
import '../screens/shared/main_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/wallet-connect',
        name: 'walletConnect',
        builder: (context, state) => const WalletConnectScreen(),
      ),

      // Main App Route (with bottom navigation)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScaffold(),
      ),

      // Farmer Routes
      GoRoute(
        path: '/farmer/dashboard',
        name: 'farmerDashboard',
        builder: (context, state) => const FarmerDashboard(),
      ),
      GoRoute(
        path: '/farmer/create-lot',
        name: 'createLot',
        builder: (context, state) => const CreateLotScreen(),
      ),
      GoRoute(
        path: '/farmer/my-lots',
        name: 'myLots',
        builder: (context, state) => const MyLotsScreen(),
      ),
      GoRoute(
        path: '/farmer/lots',
        name: 'farmerLots',
        builder: (context, state) => const MyLotsScreen(),
      ),
      GoRoute(
        path: '/farmer/notifications',
        name: 'farmerNotifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/farmer/auction/:auctionId',
        name: 'farmerAuctionMonitor',
        builder: (context, state) {
          final auctionId = state.pathParameters['auctionId']!;
          return FarmerAuctionMonitorScreen(auctionId: auctionId);
        },
      ),

      // Exporter Routes
      GoRoute(
        path: '/exporter/dashboard',
        name: 'exporterDashboard',
        builder: (context, state) => const ExporterDashboard(),
      ),
      GoRoute(
        path: '/exporter/browse',
        name: 'browseLots',
        builder: (context, state) => const BrowseLotsScreen(),
      ),
      GoRoute(
        path: '/exporter/auction/:auctionId',
        name: 'liveAuction',
        builder: (context, state) {
          final auctionId = state.pathParameters['auctionId']!;
          return LiveAuctionScreen(auctionId: auctionId);
        },
      ),

      // Shared Routes
      GoRoute(
        path: '/lot/:lotId',
        name: 'lotDetails',
        builder: (context, state) {
          final lotId = state.pathParameters['lotId']!;
          return LotDetailsScreen(lotId: lotId);
        },
      ),
      GoRoute(
        path: '/traceability/:lotId',
        name: 'traceability',
        builder: (context, state) {
          final lotId = state.pathParameters['lotId']!;
          return TraceabilityScreen(lotId: lotId);
        },
      ),
      GoRoute(
        path: '/qr-scanner',
        name: 'qrScanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/shared/auctions',
        name: 'sharedAuctions',
        builder: (context, state) => const AuctionsScreen(),
      ),
      GoRoute(
        path: '/shared/qr-scanner',
        name: 'sharedQrScanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
