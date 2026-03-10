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
import '../screens/farmer/quality_grading_screen.dart';
import '../screens/farmer/quality_grading_history_screen.dart';
import '../screens/exporter/browse_lots_screen.dart';
import '../screens/exporter/my_bids_screen.dart';
import '../screens/exporter/won_auctions_screen.dart';
import '../screens/exporter/payment_escrow_screen.dart';
import '../screens/exporter/exporter_profile_screen.dart';
import '../screens/exporter/exporter_notifications_screen.dart';
import '../screens/exporter/live_auctions_browser_screen.dart';
import '../screens/shared/lot_details_screen.dart';
import '../screens/shared/traceability_screen.dart';
import '../screens/shared/qr_scanner_screen.dart';
import '../screens/shared/auctions_screen.dart';
import '../screens/shared/auction_by_id_screen.dart';
import '../screens/shared/main_scaffold.dart';

import '../screens/plantation/plantation_management_dashboard.dart';
import '../screens/plantation/agronomy/agronomy_guide_screen.dart';
import '../screens/plantation/plantation/pages/farms_list_page.dart';
import '../screens/plantation/plantation/pages/farm_details_page.dart';
import '../screens/plantation/plantation/pages/plantation_setup_page.dart';
import '../screens/plantation/plantation/pages/edit_farm_page.dart';
import '../screens/plantation/plantation/pages/task_completion_page.dart';
import '../screens/plantation/seasons/seasons_screen.dart';
import '../screens/plantation/predictions/price_prediction_screen.dart';
import '../screens/plantation/chat/ai_chat_screen.dart';
import '../screens/plantation/yield_analytics/yield_analytics_page.dart';
import '../screens/plantation/price_analytics/price_analytics_page.dart';
import '../screens/plantation/plantation/models/farm_record_model.dart';
import '../screens/plantation/plantation/models/farm_task_model.dart';
import '../screens/diseases/image_upload_screen.dart';

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
        path: '/farmer/quality-grading',
        name: 'qualityGrading',
        builder: (context, state) => const QualityGradingScreen(),
      ),
      GoRoute(
        path: '/farmer/quality-grading/history',
        name: 'qualityGradingHistory',
        builder: (context, state) => const QualityGradingHistoryScreen(),
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
          return AuctionByIdScreen(auctionId: auctionId);
        },
      ),
      GoRoute(
        path: '/exporter/bids',
        name: 'myBids',
        builder: (context, state) => const MyBidsScreen(),
      ),
      GoRoute(
        path: '/exporter/live-auctions',
        name: 'liveAuctions',
        builder: (context, state) => const LiveAuctionsBrowserScreen(),
      ),
      GoRoute(
        path: '/exporter/won',
        name: 'wonAuctions',
        builder: (context, state) => const WonAuctionsScreen(),
      ),
      GoRoute(
        path: '/exporter/payment/:auctionId',
        name: 'paymentEscrow',
        builder: (context, state) {
          final auctionId = state.pathParameters['auctionId']!;
          final auctionData = state.extra as Map<String, dynamic>? ?? {};
          return PaymentEscrowScreen(
            auctionId: auctionId,
            auctionData: auctionData,
          );
        },
      ),
      GoRoute(
        path: '/exporter/profile',
        name: 'exporterProfile',
        builder: (context, state) => const ExporterProfileScreen(),
      ),
      GoRoute(
        path: '/exporter/notifications',
        name: 'exporterNotifications',
        builder: (context, state) => const ExporterNotificationsScreen(),
      ),

      // Shared Routes
      GoRoute(
        path: '/auction/:auctionId',
        name: 'auctionDetails',
        builder: (context, state) {
          final auctionId = state.pathParameters['auctionId']!;
          return AuctionByIdScreen(auctionId: auctionId);
        },
      ),
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
      GoRoute(
        path: '/shared/farm-management',
        name: 'farmManagement',
        builder: (context, state) => const PlantationManagementDashboard(),
      ),

      // Disease Management Routes
      GoRoute(
        path: '/diseases/image-upload',
        name: 'diseaseImageUpload',
        builder: (context, state) => const ImageUploadScreen(),
      ),

      // Plantation feature routes
      GoRoute(
        path: '/plantation/price-analytics',
        name: 'priceAnalytics',
        builder: (context, state) => const PriceAnalyticsPage(),
      ),
      GoRoute(
        path: '/plantation/farms',
        name: 'plantationFarms',
        builder: (context, state) => const FarmsListPage(),
      ),
      GoRoute(
        path: '/plantation/farm/:farmId',
        name: 'farmDetails',
        builder: (context, state) {
          final farmId = state.pathParameters['farmId']!;
          return FarmDetailsPage(farmId: farmId);
        },
      ),
      GoRoute(
        path: '/plantation/setup',
        name: 'plantationSetup',
        builder: (context, state) => const PlantationSetupPage(),
      ),
      GoRoute(
        path: '/plantation/edit-farm',
        name: 'editFarm',
        builder: (context, state) {
          final farm = state.extra as FarmRecord;
          return EditFarmPage(farm: farm);
        },
      ),
      GoRoute(
        path: '/plantation/task-completion',
        name: 'taskCompletion',
        builder: (context, state) {
          final task = state.extra as FarmTask;
          return TaskCompletionPage(task: task);
        },
      ),
      GoRoute(
        path: '/plantation/agronomy-guide',
        name: 'agronomyGuide',
        builder: (context, state) => const AgronomyGuideScreen(),
      ),
      GoRoute(
        path: '/plantation/seasons',
        name: 'seasons',
        builder: (context, state) => const SeasonsScreen(),
      ),
      GoRoute(
        path: '/plantation/price-prediction',
        name: 'pricePrediction',
        builder: (context, state) => const PricePredictionScreen(),
      ),
      GoRoute(
        path: '/plantation/yield-analytics',
        name: 'yieldAnalytics',
        builder: (context, state) => const YieldAnalyticsPage(),
      ),
      GoRoute(
        path: '/plantation/ai-chat',
        name: 'aiChat',
        builder: (context, state) => const AiChatScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}
