# Multi-Language Quick Reference

## Quick Start

### Import Required

```dart
// Automatic via extension - no import needed!
// Just use context.tr('key')
```

### Basic Usage

```dart
// In any widget with BuildContext
Text(context.tr('common_save'))
```

## Common Translation Keys

### Buttons & Actions

```dart
context.tr('common_ok')          // OK
context.tr('common_cancel')      // Cancel
context.tr('common_confirm')     // Confirm
context.tr('common_save')        // Save
context.tr('common_delete')      // Delete
context.tr('common_edit')        // Edit
context.tr('common_submit')      // Submit
context.tr('common_search')      // Search
context.tr('common_back')        // Back
context.tr('common_next')        // Next
context.tr('common_yes')         // Yes
context.tr('common_no')          // No
```

### Navigation

```dart
context.tr('nav_home')           // Home
context.tr('nav_lots')           // Lots
context.tr('nav_auctions')       // Auctions
context.tr('nav_profile')        // Profile
context.tr('nav_settings')       // Settings
context.tr('nav_wallet')         // Wallet
context.tr('nav_notifications')  // Notifications
```

### Authentication

```dart
context.tr('auth_login')         // Login
context.tr('auth_logout')        // Logout
context.tr('auth_register')      // Register
context.tr('auth_email')         // Email
context.tr('auth_password')      // Password
context.tr('auth_sign_in')       // Sign In
context.tr('auth_sign_up')       // Sign Up
context.tr('auth_welcome')       // Welcome to SmartPepper
```

### Lots

```dart
context.tr('lot_title')          // Pepper Lots
context.tr('lot_create')         // Create New Lot
context.tr('lot_details')        // Lot Details
context.tr('lot_weight')         // Weight (kg)
context.tr('lot_quality_grade')  // Quality Grade
context.tr('lot_status')         // Status
context.tr('lot_pending')        // Pending
context.tr('lot_approved')       // Approved
context.tr('lot_rejected')       // Rejected
```

### Auctions

```dart
context.tr('auction_title')      // Auctions
context.tr('auction_live')       // Live Auctions
context.tr('auction_create')     // Create Auction
context.tr('auction_place_bid')  // Place Bid
context.tr('auction_bid_amount') // Bid Amount
context.tr('auction_ended')      // Ended
context.tr('auction_won')        // Won
context.tr('auction_lost')       // Lost
```

### Status Messages

```dart
context.tr('common_loading')     // Loading...
context.tr('common_error')       // Error
context.tr('common_success')     // Success
```

### Error Messages

```dart
context.tr('error_network')          // Network error...
context.tr('error_invalid_input')    // Invalid input...
context.tr('error_authentication')   // Authentication failed
context.tr('error_server')           // Server error...
```

### Success Messages

```dart
context.tr('success_lot_created')     // Lot created successfully
context.tr('success_auction_created') // Auction created successfully
context.tr('success_bid_placed')      // Bid placed successfully
context.tr('success_profile_updated') // Profile updated successfully
```

### Empty States

```dart
context.tr('empty_no_lots')       // No lots available
context.tr('empty_no_auctions')   // No auctions available
context.tr('empty_no_bids')       // No bids yet
```

## Changing Language

### Using LanguageProvider

```dart
import 'package:provider/provider.dart';

// Get provider (no rebuild)
final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

// Change language
await languageProvider.changeLanguage('si'); // Sinhala
await languageProvider.changeLanguage('ta'); // Tamil
await languageProvider.changeLanguage('en'); // English

// Get current language
String currentLang = languageProvider.locale.languageCode;
String langName = languageProvider.currentLanguageName;
```

### Using LanguageSelector Widget

```dart
import '../shared/language_selector.dart';

// Add to your settings screen
const LanguageSelector(),
```

## Language Codes

- `'en'` - English (Default)
- `'si'` - Sinhala (සිංහල)
- `'ta'` - Tamil (தமிழ்)

## Complete Example

```dart
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('lot_title')),
      ),
      body: Column(
        children: [
          Text(context.tr('lot_weight')),
          ElevatedButton(
            onPressed: () {},
            child: Text(context.tr('common_save')),
          ),
        ],
      ),
    );
  }
}
```

## Tips

1. **Always use context.tr()** - It's the simplest way
2. **Check all 3 JSON files** - When adding new keys
3. **Use descriptive keys** - `lot_weight` not `lw`
4. **Keep categories** - `category_screen_element`
5. **Test all languages** - Switch languages and verify UI

## Full Key List

See `assets/translations/en.json` for complete list of available keys with English translations.

---

**Quick Help**: If a key shows as text (like `my_key`), it means it's not in the translation files. Add it to all three JSON files (en.json, si.json, ta.json).
