# Multi-Language Support Documentation

## Overview

The SmartPepper mobile application supports three languages:

- **English** (en) - Default
- **Sinhala** (si) - සිංහල
- **Tamil** (ta) - தமிழ்

The localization system uses Flutter's built-in internationalization support with custom JSON-based translation files.

## Architecture

### Components

1. **AppLocalizations** (`lib/localization/app_localizations.dart`)
   - Core localization class that loads and manages translations
   - Provides translation methods and locale configuration
   - Implements LocalizationsDelegate for Flutter integration

2. **LanguageProvider** (`lib/providers/language_provider.dart`)
   - State management for language selection
   - Persists language preference using SharedPreferences
   - Notifies UI when language changes

3. **Translation Files** (`assets/translations/`)
   - `en.json` - English translations
   - `si.json` - Sinhala translations
   - `ta.json` - Tamil translations

4. **UI Components**
   - **LanguageSelector** - Widget for language selection dialog
   - **LanguageSettingsScreen** - Example settings screen with language selector

## Setup

### 1. Dependencies

Already configured in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1
  shared_preferences: ^2.2.2
  provider: ^6.1.1
```

### 2. Assets Configuration

Translation files are stored in `assets/translations/`:

```yaml
flutter:
  assets:
    - assets/translations/
```

### 3. Main App Configuration

The app is already configured in `main.dart` with:

- LanguageProvider added to MultiProvider
- MaterialApp.router wrapped with Consumer<LanguageProvider>
- Localization delegates configured
- Locale resolution callback implemented

## Usage

### Basic Translation

Use the extension method `tr()` on BuildContext:

```dart
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav_home')),
      ),
      body: Center(
        child: Text(context.tr('dashboard_welcome')),
      ),
    );
  }
}
```

### Alternative Translation Method

If you prefer to use the AppLocalizations directly:

```dart
import '../../localization/app_localizations.dart';

String translatedText = AppLocalizations.of(context).translate('key');
// or
String translatedText = AppLocalizations.of(context).tr('key');
```

### Changing Language

Access the LanguageProvider to change language:

```dart
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

// In your widget
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
await languageProvider.changeLanguage('si'); // Change to Sinhala
```

Supported language codes:

- `'en'` - English
- `'si'` - Sinhala
- `'ta'` - Tamil

### Using the LanguageSelector Widget

Add the pre-built language selector to your settings screen:

```dart
import '../shared/language_selector.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const LanguageSelector(),
          // Other settings...
        ],
      ),
    );
  }
}
```

## Translation Keys

### Categories

All translation keys are organized by category:

- **Common**: `common_*` (OK, Cancel, Save, Loading, etc.)
- **Authentication**: `auth_*` (Login, Register, Email, Password, etc.)
- **Navigation**: `nav_*` (Home, Lots, Auctions, Profile, etc.)
- **Lots**: `lot_*` (Title, Create, Details, Status, etc.)
- **Auctions**: `auction_*` (Live, Create, Bid, History, etc.)
- **Compliance**: `compliance_*` (Check, Status, Certificate, etc.)
- **Payment**: `payment_*` (Escrow, Amount, Status, etc.)
- **Shipment**: `shipment_*` (Details, Tracking, Status, etc.)
- **Profile**: `profile_*` (Edit, Info, Documents, etc.)
- **Settings**: `settings_*` (Language, Notifications, Security, etc.)
- **Notifications**: `notification_*` (New bid, Won, Lost, etc.)
- **Errors**: `error_*` (Network, Authentication, Server, etc.)
- **Success**: `success_*` (Created, Updated, Completed, etc.)
- **Confirmations**: `confirm_*` (Delete, Place bid, Logout, etc.)
- **Blockchain**: `blockchain_*` (Connecting, Pending, Confirmed, etc.)
- **Dashboard**: `dashboard_*` (Welcome, Statistics, Activity, etc.)
- **Empty States**: `empty_*` (No lots, No auctions, etc.)

### Adding New Translations

1. **Add to all three JSON files** (`en.json`, `si.json`, `ta.json`):

```json
// en.json
{
  "my_new_key": "My English Text"
}

// si.json
{
  "my_new_key": "මගේ සිංහල පෙළ"
}

// ta.json
{
  "my_new_key": "எனது தமிழ் உரை"
}
```

2. **Use in your code**:

```dart
Text(context.tr('my_new_key'))
```

## Best Practices

### 1. Key Naming Convention

Use descriptive, hierarchical keys:

```
{category}_{screen/component}_{element}
```

Examples:

- `auction_create_button`
- `lot_details_weight_label`
- `error_network_connection`

### 2. Keep Keys Consistent

Always update all three translation files when adding new keys.

### 3. Context-Aware Translations

For context-specific translations, include the context in the key:

```json
{
  "button_save": "Save",
  "button_save_changes": "Save Changes",
  "button_save_and_continue": "Save and Continue"
}
```

### 4. Use Meaningful Defaults

If a key is missing, the key itself is displayed. Use descriptive keys:
❌ Bad: `k1`, `txt_01`, `label`
✅ Good: `lot_weight_label`, `auction_start_time`, `error_network`

### 5. Handle Pluralization

For numbers that may need pluralization, create separate keys:

```json
{
  "auction_one_bid": "1 bid",
  "auction_multiple_bids": "{count} bids"
}
```

Then handle in code:

```dart
String getBidText(int count) {
  return count == 1
    ? context.tr('auction_one_bid')
    : context.tr('auction_multiple_bids').replaceAll('{count}', count.toString());
}
```

## Example Screens

### Complete Example: Auction List Screen

```dart
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

class AuctionListScreen extends StatelessWidget {
  const AuctionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('auction_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
            tooltip: context.tr('common_filter'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(context),
          Expanded(
            child: _buildAuctionList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text(context.tr('auction_create')),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: TabBar(
        tabs: [
          Tab(text: context.tr('auction_live')),
          Tab(text: context.tr('auction_upcoming')),
          Tab(text: context.tr('auction_completed')),
        ],
      ),
    );
  }

  Widget _buildAuctionList(BuildContext context) {
    // If empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gavel, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            context.tr('empty_no_auctions'),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
```

## Testing Translations

### Manual Testing

1. Run the app
2. Navigate to Settings
3. Use the LanguageSelector to switch languages
4. Navigate through different screens to verify translations

### Testing Checklist

- [ ] All screens display correctly in English
- [ ] All screens display correctly in Sinhala
- [ ] All screens display correctly in Tamil
- [ ] Language preference persists after app restart
- [ ] UI layouts accommodate longer text in different languages
- [ ] RTL (Right-to-Left) text displays correctly for applicable languages

## Common Issues & Solutions

### Issue 1: Missing Translation Key

**Symptom**: Key name displayed instead of translation

```
Settings Screen
  language_settings  ← Key displayed instead of text
```

**Solution**: Add the key to all translation files

### Issue 2: Text Overflow

**Symptom**: Text gets cut off in different languages

**Solution**: Use flexible widgets

```dart
// Instead of fixed width
Container(
  width: 100,
  child: Text(context.tr('key')),
)

// Use flexible width
Expanded(
  child: Text(context.tr('key')),
)
```

### Issue 3: Language Not Changing

**Symptom**: UI doesn't update after changing language

**Solution**: Ensure Provider is listening

```dart
// Wrong
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

// Correct (for display)
final languageProvider = Provider.of<LanguageProvider>(context);
```

### Issue 4: Translations Not Loading

**Symptom**: App crashes or shows errors when accessing translations

**Solution**:

1. Check `pubspec.yaml` includes translation assets
2. Verify JSON files are valid (use JSON validator)
3. Ensure all three files have matching keys

## Future Enhancements

### Planned Features

1. **Dynamic Translation Loading**
   - Load translations from server
   - Allow real-time translation updates

2. **Translation Management**
   - Admin panel for managing translations
   - Translation versioning

3. **Additional Languages**
   - Add more languages as needed
   - Community-contributed translations

4. **Context-Based Translations**
   - Role-based translations (farmer vs exporter terminology)
   - Region-specific translations

## Resources

- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Intl Package](https://pub.dev/packages/intl)
- [Provider Package](https://pub.dev/packages/provider)

## Support

For issues or questions about the multi-language support:

1. Check this documentation
2. Review the example screens
3. Check the translation JSON files for reference keys
4. Contact the development team

---

**Last Updated**: February 2026  
**Version**: 1.0.0
