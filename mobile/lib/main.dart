import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/auction_provider.dart';
import 'providers/lot_provider.dart';
import 'services/api_service.dart';
import 'services/blockchain_service.dart';
import 'services/socket_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/offline_sync_service.dart';
import 'services/ipfs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final storage = FlutterSecureStorage();
  final storageService = StorageService(storage);
  final apiService = ApiService();
  final blockchainService = BlockchainService();
  final socketService = SocketService();
  final ipfsService = IpfsService();

  // Initialize notification and offline sync services
  final notificationService = NotificationService(
    apiService: apiService,
    storageService: storageService,
  );
  final offlineSyncService = OfflineSyncService(
    storageService: storageService,
    apiService: apiService,
  );

  // Initialize services
  await notificationService.initialize();
  await offlineSyncService.initialize();
  await blockchainService.initialize(); // Initialize blockchain contracts

  runApp(
    MultiProvider(
      providers: [
        // Provide service instances
        Provider<ApiService>.value(value: apiService),
        Provider<StorageService>.value(value: storageService),
        Provider<BlockchainService>.value(value: blockchainService),
        Provider<SocketService>.value(value: socketService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<OfflineSyncService>.value(value: offlineSyncService),
        Provider<IpfsService>.value(value: ipfsService),

        // Provide state management providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
            blockchainService: blockchainService,
          )..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => LotProvider(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AuctionProvider>(
          create: (_) => AuctionProvider(
            apiService: apiService,
            socketService: socketService,
            blockchainService: blockchainService,
          ),
          update: (_, auth, previous) =>
              previous ??
              AuctionProvider(
                apiService: apiService,
                socketService: socketService,
                blockchainService: blockchainService,
              ),
        ),
      ],
      child: const SmartPepperApp(),
    ),
  );
}

class SmartPepperApp extends StatelessWidget {
  const SmartPepperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartPepper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
