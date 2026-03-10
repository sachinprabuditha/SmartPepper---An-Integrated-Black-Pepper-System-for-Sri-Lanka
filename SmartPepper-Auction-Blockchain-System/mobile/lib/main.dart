import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/auction_provider.dart';
import 'providers/lot_provider.dart';
import 'providers/language_provider.dart';
import 'services/api_service.dart';
import 'services/blockchain_service.dart';
import 'services/socket_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/offline_sync_service.dart';
import 'services/ipfs_service.dart';
import 'localization/app_localizations.dart';
import 'utils/notification_navigation_helper.dart';

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

  // Connect WebSocket for real-time auction updates immediately
  print('🚀 Initializing WebSocket connection...');
  socketService.connect().then((_) {
    print('🚀 WebSocket initialization complete');
  }).catchError((error) {
    print('❌ WebSocket initialization error: $error');
  });

  print('🚀 App initialization complete');

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

        // Language Provider
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),

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
          create: (context) => AuctionProvider(
            apiService: apiService,
            socketService: socketService,
            blockchainService: blockchainService,
            notificationService: context.read<NotificationService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              AuctionProvider(
                apiService: apiService,
                socketService: socketService,
                blockchainService: blockchainService,
                notificationService: context.read<NotificationService>(),
              ),
        ),
      ],
      child: const SmartPepperApp(),
    ),
  );
}

class SmartPepperApp extends StatefulWidget {
  const SmartPepperApp({super.key});

  @override
  State<SmartPepperApp> createState() => _SmartPepperAppState();
}

class _SmartPepperAppState extends State<SmartPepperApp> {
  @override
  void initState() {
    super.initState();
    // Set up notification tap callback after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallback();
    });
  }

  void _setupNotificationCallback() {
    final notificationService = context.read<NotificationService>();
    notificationService.onNotificationTap = (payload) {
      if (mounted) {
        NotificationNavigationHelper.handleNotificationTap(context, payload);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp.router(
          title: 'SmartPepper',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
          // Localization configuration
          locale: languageProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            // For Sinhala and Tamil, use English as base locale for Material/Cupertino widgets
            // but keep the app translations in the selected language
            if (locale?.languageCode == 'si' || locale?.languageCode == 'ta') {
              // Return the requested locale - AppLocalizations handles it
              // Material/Cupertino will fallback to English automatically
              return locale;
            }

            // For other locales, check if supported
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }

            // Default fallback to English
            return const Locale('en', 'US');
          },
        );
      },
    );
  }
}
