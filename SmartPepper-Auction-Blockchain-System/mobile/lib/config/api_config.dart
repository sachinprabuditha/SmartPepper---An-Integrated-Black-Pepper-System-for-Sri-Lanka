class ApiConfig {
  // IMPORTANT: Update this based on your testing environment

  // For Android Emulator (routes to host machine's localhost)
  static const String baseUrl = 'http://10.0.2.2:3002';

  // For iOS Simulator (use localhost or your machine's IP)
  // static const String baseUrl = 'http://localhost:3002';

  // For Real Device (replace with your computer's IP address)
  // Find your IP: Run 'ipconfig' on Windows and use IPv4 Address
  // static const String baseUrl = 'http://192.168.1.100:3002';

  // API Endpoints
  static const String authEndpoint = '/api/auth';
  static const String usersEndpoint = '/api/users';
  static const String auctionsEndpoint = '/api/auctions';
  static const String lotsEndpoint = '/api/lots';
  static const String bidsEndpoint = '/api/bids';
  static const String nftPassportEndpoint = '/api/nft-passports';
  static const String complianceEndpoint = '/api/compliance';

  // Full Auth URLs
  static String get loginUrl => '$baseUrl$authEndpoint/login';
  static String get registerUrl => '$baseUrl$authEndpoint/register';
  static String get refreshUrl => '$baseUrl$authEndpoint/refresh';
  static String get logoutUrl => '$baseUrl$authEndpoint/logout';
  static String get meUrl => '$baseUrl$authEndpoint/me';

  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
