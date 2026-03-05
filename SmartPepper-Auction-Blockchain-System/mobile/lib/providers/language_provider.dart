import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');
  static const String _languageKey = 'selected_language';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _locale = _getLocaleFromCode(languageCode);
      notifyListeners();
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = _getLocaleFromCode(languageCode);

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }

  // Get locale from language code
  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en', 'US');
      case 'si':
        return const Locale('si', 'LK');
      case 'ta':
        return const Locale('ta', 'LK');
      default:
        return const Locale('en', 'US');
    }
  }

  // Get current language name
  String get currentLanguageName {
    return AppLocalizations.getLanguageName(_locale.languageCode);
  }

  // Get current language flag
  String get currentLanguageFlag {
    return AppLocalizations.getLanguageFlag(_locale.languageCode);
  }

  // Get all supported languages
  List<Map<String, String>> get supportedLanguages {
    return [
      {
        'code': 'en',
        'name': 'English',
        'nativeName': 'English',
        'flag': '🇬🇧',
      },
      {
        'code': 'si',
        'name': 'Sinhala',
        'nativeName': 'සිංහල',
        'flag': '🇱🇰',
      },
      {
        'code': 'ta',
        'name': 'Tamil',
        'nativeName': 'தமிழ்',
        'flag': '🇱🇰',
      },
    ];
  }
}
