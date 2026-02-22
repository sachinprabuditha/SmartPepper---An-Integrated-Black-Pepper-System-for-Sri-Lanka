class AppConstants {
  // Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userFullNameKey = 'user_full_name';

  // API Endpoints
  static const String authSignUp = '/auth/signup';
  static const String authSignIn = '/auth/signin';
  static const String seasonsBase = '/seasons';
  static const String sessionsBase = '/sessions';
  static const String agronomyBase = '/agronomy';
  static const String plantationBase = '/plantation';
}

class DateFormats {
  static const String displayDate = 'MMM dd, yyyy';
  static const String displayDateTime = 'MMM dd, yyyy HH:mm';
  static const String apiDate = 'yyyy-MM-dd';
}

