class AppConfig {
  // Backend URL Configuration for physical device on local network
  // 192.168.8.173 is the internal IP address of the computer running the server
  static const String backendBaseUrl = 'http://192.168.8.173:5000';
  static const String predictEndpoint = '/predict';

  // Full predict URL
  static String get predictUrl => '$backendBaseUrl$predictEndpoint';

  // Alternative URLs for different scenarios
  static const String emulatorUrl = 'http://10.0.2.2:5000/predict';
  static const String localhostUrl = 'http://localhost:5000/predict';
}
