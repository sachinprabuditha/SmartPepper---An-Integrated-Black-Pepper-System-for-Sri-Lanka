class Environment {
  // API Configuration
  static const String apiBaseUrl =
      'http://10.0.2.2:3002/api'; // Android emulator
  // For iOS simulator use: 'http://localhost:3002/api'
  // For physical device use your machine's IP: 'http://192.168.1.x:3002/api'

  // Blockchain Configuration
  static const String blockchainRpcUrl = 'http://10.0.2.2:8545';
  static const String contractAddress = '0xYourDeployedContractAddress';

  // WebSocket Configuration
  static const String wsUrl = 'ws://10.0.2.2:3002';

  // App Configuration
  static const String appName = 'SmartPepper';
  static const String appVersion = '1.0.0';

  // Supported Languages
  static const List<String> supportedLanguages = [
    'en', // English
    'si', // Sinhala
    'ta', // Tamil
    'hi', // Hindi
  ];

  // Auction Configuration
  static const int auctionUpdateInterval = 300; // milliseconds
  static const int bidIncrementPercentage = 5; // 5% minimum increment

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocTypes = ['pdf'];
}
