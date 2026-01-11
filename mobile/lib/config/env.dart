class Environment {
  // API Configuration
  // IMPORTANT: Update this based on your device type:
  // - Android Emulator: 'http://10.0.2.2:3002/api'
  // - iOS Simulator: 'http://localhost:3002/api'
  // - Physical Device: Use your computer's IP (check with ipconfig/ifconfig)

  static const String apiBaseUrl =
      'http://192.168.0.116:3002/api'; // Physical device (Wi-Fi)

  // Uncomment for emulator:
  // static const String apiBaseUrl = 'http://10.0.2.2:3002/api';

  // Blockchain Configuration
  static const String blockchainRpcUrl = 'http://192.168.0.116:8545';
  static const int chainId = 1337; // Hardhat chain ID
  static const String contractAddress = '0xYourDeployedContractAddress';

  // Smart Contract Addresses (Update after deployment)
  static const String passportContractAddress =
      '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6'; // PepperPassport
  static const String auctionContractAddress =
      '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318'; // PepperAuction

  // WebSocket Configuration (with /auction namespace)
  static const String wsUrl = 'ws://192.168.0.116:3002/auction';

  // IPFS Configuration
  static const String ipfsApiUrl = 'http://192.168.0.116:5001';
  static const String ipfsGatewayUrl = 'http://192.168.0.116:8080';

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
