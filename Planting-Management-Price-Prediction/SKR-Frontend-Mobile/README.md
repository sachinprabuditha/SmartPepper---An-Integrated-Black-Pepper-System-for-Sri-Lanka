# Harvest Tracking System - Mobile App

Flutter mobile application for tracking harvest seasons and sessions.

## Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Generate JSON serialization code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **IMPORTANT: Configure API Base URL**
   
   Update the `baseUrl` in `lib/core/network/api_client.dart`:
   - For Android Emulator: Use `http://10.0.2.2:5000/api`
   - For iOS Simulator: Use `http://localhost:5000/api`
   - For Physical Device: Use your computer's IP address (e.g., `http://192.168.1.100:5000/api`)

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/              # Core utilities, theme, network
│   ├── network/       # API client and interceptors
│   ├── theme/         # App theme configuration
│   ├── utils/         # Constants and validators
│   └── widgets/       # Reusable widgets
├── features/          # Feature modules
│   ├── auth/          # Authentication
│   ├── seasons/       # Season management
│   └── sessions/      # Session management
└── main.dart          # App entry point
```

## Features

- ✅ User authentication with JWT tokens
- ✅ Create and manage harvest seasons
- ✅ Add and manage harvesting sessions
- ✅ View season and session details
- ✅ Edit and delete seasons/sessions
- ✅ Material 3 UI with green/organic theme
- ✅ Pull-to-refresh functionality
- ✅ Error handling and loading states

## API Endpoints Used

### Authentication
- `POST /api/auth/signin` - Sign in
- `POST /api/auth/signup` - Sign up

### Seasons
- `GET /api/seasons/user/{userId}` - Get user's seasons
- `POST /api/seasons` - Create season
- `GET /api/seasons/{seasonId}` - Get season details
- `PUT /api/seasons/{seasonId}` - Update season
- `DELETE /api/seasons/{seasonId}` - Delete season

### Sessions
- `GET /api/sessions/season/{seasonId}` - Get sessions for season
- `POST /api/sessions` - Create session
- `GET /api/sessions/{sessionId}` - Get session details
- `PUT /api/sessions/{sessionId}` - Update session
- `DELETE /api/sessions/{sessionId}` - Delete session

## State Management

This app uses **Riverpod** for state management with:
- `StateNotifierProvider` for controllers
- `FutureProvider` for async data
- `Provider` for services and dependencies

## Notes

- JWT tokens are stored securely using `flutter_secure_storage`
- All API requests automatically include the JWT token via `AuthInterceptor`
- The app automatically redirects to login if not authenticated

