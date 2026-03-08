import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the current language code ('en' or 'si')
final languageProvider = StateProvider<String>((ref) => 'en');
