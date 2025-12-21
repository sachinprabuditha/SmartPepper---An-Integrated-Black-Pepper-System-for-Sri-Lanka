# Quick Reference - Mobile Database Setup

## Test Credentials

```
Farmer:   farmer@smartpepper.com    / Farmer123!
Exporter: exporter@smartpepper.com  / Exporter123!
Admin:    admin@gmail.com           / (use your password)
```

## API URLs

```dart
// Android Emulator
'http://10.0.2.2:3002'

// iOS Simulator
'http://localhost:3002'

// Physical Device (replace with your IP)
'http://192.168.1.100:3002'
```

## Quick Start Mobile

```bash
cd mobile
flutter pub get
flutter run
```

## Quick Test Backend

```powershell
# Check backend
curl http://localhost:3002/api/users -UseBasicParsing

# Test login
curl http://localhost:3002/api/auth/login -Method POST -Body '{"email":"farmer@smartpepper.com","password":"Farmer123!"}' -ContentType "application/json"

# Create test users
.\create-test-users.ps1
```

## Login Code (Dart)

```dart
final authService = AuthService();
final result = await authService.login(
  email: 'farmer@smartpepper.com',
  password: 'Farmer123!',
);

if (result.success) {
  // Success - navigate to home
  final user = result.data['user'];
  print('Welcome ${user['name']}!');
}
```

## Check Login Status (Dart)

```dart
final token = await authService.getToken();
if (token != null) {
  // User is logged in
  final user = await authService.getCurrentUser();
} else {
  // Show login screen
}
```

## Make Authenticated Request (Dart)

```dart
final token = await authService.getToken();
final response = await dio.get(
  '/users/me',
  options: Options(
    headers: {'Authorization': 'Bearer $token'},
  ),
);
```

## Common Issues

### Connection Refused

- Android: Use `10.0.2.2:3002`
- iOS: Use `localhost:3002`
- Device: Use your computer's IP

### Backend Not Running

```powershell
cd backend
npm start
```

### Database Errors

```powershell
cd backend
node fix-wallet-nullable.js
```

## Files You Need

### Mobile App

- `lib/config/api_config.dart` ✅
- `lib/models/user.dart` ✅
- `lib/services/auth_service.dart` ✅

### Backend Running

- Port 3002 ✅
- PostgreSQL connected ✅
- Test users created ✅

## Documentation

- [MOBILE_DB_COMPLETE.md](./MOBILE_DB_COMPLETE.md) - Full guide
- [MOBILE_DATABASE_SETUP.md](./MOBILE_DATABASE_SETUP.md) - Setup details
- [TEST_CREDENTIALS.md](./TEST_CREDENTIALS.md) - All test users

---

**Ready to develop! 🚀**
