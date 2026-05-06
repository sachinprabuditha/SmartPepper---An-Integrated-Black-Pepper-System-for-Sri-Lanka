class AppConfig {
  // Backend URL Configuration for physical device on local network
  // Old configuration (HEAD):
  // static const String backendBaseUrl = 'http://192.168.1.153:5000';

  // New configuration (Incoming):
  static const String backendBaseUrl = 'http://192.168.1.133:5005';

  static const String predictEndpoint = '/predict';

  // Full predict URL
  static String get predictUrl => '$backendBaseUrl$predictEndpoint';

  // Alternative URLs for different scenarios
  static const String emulatorUrl = 'http://10.0.2.2:5000/predict';
  static const String localhostUrl = 'http://localhost:5000/predict';
}
