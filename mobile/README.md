# SmartPepper Mobile Application

## Overview

Flutter-based mobile application for the SmartPepper blockchain-enabled real-time auction system. Designed for smallholder black pepper farmers and exporters to participate in transparent, compliant pepper exports.

## Features

### For Farmers

- **Lot Management**: Register and list pepper lots for auction
- **QR/NFC Tagging**: Generate digital passports for each lot
- **Live Auctions**: Participate in real-time bidding
- **Traceability**: Track lot journey from farm to export
- **Certification Upload**: Submit organic, fumigation, and export certificates
- **Price Analytics**: View historical prices and market trends
- **Notifications**: Real-time alerts for bids, compliance, and settlements

### For Exporters

- **Auction Browsing**: View available pepper lots with full traceability
- **Live Bidding**: Place real-time bids with sub-300ms updates
- **Compliance Verification**: Check certification and regulatory status
- **Escrow Payments**: Secure blockchain-based payment handling
- **Shipment Tracking**: Monitor export logistics
- **Digital Passport Scanner**: Verify lot authenticity via QR/NFC

## Technology Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider / Riverpod
- **Blockchain**: Web3Dart for Ethereum integration
- **Real-time**: Socket.IO for auction updates
- **Storage**: SQLite for local data, SharedPreferences for settings
- **QR/NFC**: qr_flutter, flutter_nfc_reader
- **Camera**: camera, image_picker for document scanning
- **Network**: http, dio for REST API calls

## Prerequisites

- Flutter SDK 3.0 or higher
- Android Studio / Xcode
- Node.js backend running on `http://localhost:3002`
- Blockchain node running on `http://127.0.0.1:8545`

## Installation

### 1. Install Flutter

```bash
# Visit https://flutter.dev/docs/get-started/install
flutter doctor
```

### 2. Clone and Setup

```bash
cd mobile
flutter pub get
```

### 3. Configure Environment

Create `lib/config/env.dart`:

```dart
class Environment {
  static const String apiBaseUrl = 'http://10.0.2.2:3002/api'; // Android emulator
  static const String blockchainRpcUrl = 'http://10.0.2.2:8545';
  static const String contractAddress = '0xYourContractAddress';
  static const String wsUrl = 'ws://10.0.2.2:3002';
}
```

### 4. Run Application

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Release build
flutter build apk --release
```

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   ├── env.dart             # Environment configuration
│   │   ├── routes.dart          # Navigation routes
│   │   └── theme.dart           # App theme
│   ├── models/
│   │   ├── user.dart            # User model
│   │   ├── lot.dart             # Pepper lot model
│   │   ├── auction.dart         # Auction model
│   │   └── compliance.dart      # Compliance model
│   ├── services/
│   │   ├── api_service.dart     # REST API client
│   │   ├── blockchain_service.dart # Web3 integration
│   │   ├── socket_service.dart  # WebSocket for auctions
│   │   ├── auth_service.dart    # Authentication
│   │   └── storage_service.dart # Local storage
│   ├── providers/
│   │   ├── auth_provider.dart   # Auth state management
│   │   ├── auction_provider.dart # Auction state
│   │   └── lot_provider.dart    # Lot management
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── wallet_connect_screen.dart
│   │   ├── farmer/
│   │   │   ├── farmer_dashboard.dart
│   │   │   ├── create_lot_screen.dart
│   │   │   ├── my_lots_screen.dart
│   │   │   └── upload_certificate_screen.dart
│   │   ├── exporter/
│   │   │   ├── exporter_dashboard.dart
│   │   │   ├── browse_lots_screen.dart
│   │   │   ├── live_auction_screen.dart
│   │   │   └── my_bids_screen.dart
│   │   ├── shared/
│   │   │   ├── lot_details_screen.dart
│   │   │   ├── traceability_screen.dart
│   │   │   ├── qr_scanner_screen.dart
│   │   │   └── notifications_screen.dart
│   │   └── splash_screen.dart
│   ├── widgets/
│   │   ├── lot_card.dart        # Lot display card
│   │   ├── auction_timer.dart   # Countdown timer
│   │   ├── bid_button.dart      # Bidding UI
│   │   ├── compliance_badge.dart # Status indicator
│   │   └── qr_code_widget.dart  # QR code generator
│   └── utils/
│       ├── constants.dart       # App constants
│       ├── validators.dart      # Form validation
│       └── helpers.dart         # Utility functions
├── assets/
│   ├── images/
│   └── icons/
├── pubspec.yaml                 # Dependencies
└── README.md
```

## Key Features Implementation

### 1. Real-Time Auctions

- WebSocket connection for live bid updates (<300ms)
- Optimistic UI updates for smooth bidding experience
- Automatic reconnection on network failure

### 2. Blockchain Integration

- MetaMask mobile deep linking for wallet connection
- Smart contract interaction via Web3Dart
- Transaction signing and escrow management

### 3. QR/NFC Digital Passports

- Generate unique QR codes for each lot
- NFC tag writing for physical tagging
- Instant traceability verification

### 4. Offline Support

- SQLite local database for offline lot creation
- Automatic sync when connection restored
- Cached compliance rules

### 5. Multilingual Support

- English, Sinhala, Tamil, Hindi
- RTL support for applicable languages
- Localized date/time formats

## API Integration

### Authentication

```dart
POST /api/auth/register
POST /api/auth/login
POST /api/auth/wallet-connect
```

### Lots

```dart
GET /api/lots
POST /api/lots (Farmer)
GET /api/lots/:id
PATCH /api/lots/:id
```

### Auctions

```dart
GET /api/auctions
POST /api/auctions (Farmer)
GET /api/auctions/:id
POST /api/auctions/:id/bid (Exporter)
```

### Compliance

```dart
POST /api/compliance/check
GET /api/compliance/:lotId
```

## Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widgets/
```

## Building for Production

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Security Considerations

- Secure storage for private keys (flutter_secure_storage)
- Certificate pinning for API calls
- Biometric authentication option
- Encrypted local database

## Performance Optimization

- Lazy loading for lot lists
- Image caching and compression
- Debounced search inputs
- Pagination for large datasets

## Support

For issues and questions, refer to the main project documentation or contact the development team.

## License

This project is part of academic research at [Your University].
