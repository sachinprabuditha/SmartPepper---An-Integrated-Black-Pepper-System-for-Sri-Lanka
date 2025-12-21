# ✅ Mobile Database Setup Complete!

## Overview

Your SmartPepper system now supports **shared authentication** between web and mobile applications using the same PostgreSQL database!

## What's Been Done

### 1. Database Schema Fixed ✅

- Made `wallet_address` column nullable
- Users can now register with email/password without blockchain wallet
- Created unique indexes for email and wallet_address
- Both authentication methods supported:
  - Email + Password (for mobile/web)
  - Wallet Address (for blockchain)

### 2. Test Users Created ✅

| Role     | Email                    | Password     |
| -------- | ------------------------ | ------------ |
| Farmer   | farmer@smartpepper.com   | Farmer123!   |
| Exporter | exporter@smartpepper.com | Exporter123! |

Plus existing users:

- admin@gmail.com (Admin)
- seller@gmail.com (Seller)
- sachin@gmail.com (Sachin)

### 3. Mobile App Configuration Created ✅

Created Flutter files:

- `mobile/lib/config/api_config.dart` - API endpoints configuration
- `mobile/lib/models/user.dart` - User data model
- `mobile/lib/services/auth_service.dart` - Complete authentication service

### 4. Documentation Created ✅

- [MOBILE_DATABASE_SETUP.md](./MOBILE_DATABASE_SETUP.md) - Comprehensive setup guide
- [QUICK_START_MOBILE_DB.md](./QUICK_START_MOBILE_DB.md) - Quick start instructions
- [TEST_CREDENTIALS.md](./TEST_CREDENTIALS.md) - Test user credentials
- [create-test-users.ps1](./create-test-users.ps1) - Script to create test users
- [fix-wallet-nullable.js](./backend/fix-wallet-nullable.js) - Database migration

##How It Works

```
┌─────────────┐          ┌──────────────┐          ┌──────────────┐
│   Web App   │          │   Mobile App │          │  PostgreSQL  │
│             │          │              │          │   Database   │
│ localhost:  │◄────────►│              │◄────────►│              │
│    3000     │   Same   │ API Client   │   JWT    │    users     │
│             │   Auth   │              │   Auth   │   table      │
└─────────────┘          └──────────────┘          └──────────────┘
      │                         │                          │
      │                         │                          │
      └─────────────────────────┴──────────────────────────┘
                        Backend API (localhost:3002)
```

## Mobile App Setup

### Step 1: Install Dependencies

```bash
cd mobile
flutter pub get
```

This will install:

- `http` - HTTP client
- `shared_preferences` - Local storage
- `provider` - State management

### Step 2: Start Your Emulator

**Android:**

```bash
# Open Android Studio > AVD Manager > Start emulator
# OR
emulator -avd Pixel_6_API_34
```

**iOS:**

```bash
open -a Simulator
```

### Step 3: Run the App

```bash
flutter run
```

### Step 4: Test Login

1. Open app on emulator
2. Navigate to Login screen
3. Enter:
   - Email: `farmer@smartpepper.com`
   - Password: `Farmer123!`
4. Click "Login"
5. Should see dashboard!

## Network Configuration

### For Android Emulator

The API is configured to use: `http://10.0.2.2:3002`

- `10.0.2.2` is the special Android emulator address for localhost

### For iOS Simulator

Use: `http://localhost:3002`

- iOS simulator uses localhost directly

### For Physical Device

1. Find your computer's IP address:

```powershell
ipconfig
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

2. Update `mobile/lib/config/api_config.dart`:

```dart
static const String baseUrl = 'http://192.168.1.100:3002';
```

3. Make sure your phone and computer are on the **same WiFi network**

## Testing the Setup

### Test 1: Backend Health Check

```powershell
curl http://localhost:3002/api/users -UseBasicParsing
```

Should return list of users.

### Test 2: Login via API

```powershell
curl http://localhost:3002/api/auth/login `
  -Method POST `
  -Body '{"email":"farmer@smartpepper.com","password":"Farmer123!"}' `
  -ContentType "application/json"
```

Should return user object and JWT token.

### Test 3: Get User Profile

```powershell
# First, login to get token
$response = curl http://localhost:3002/api/auth/login `
  -Method POST `
  -Body '{"email":"farmer@smartpepper.com","password":"Farmer123!"}' `
  -ContentType "application/json" `
  -UseBasicParsing | ConvertFrom-Json

$token = $response.token

# Then get profile
curl http://localhost:3002/api/auth/me `
  -Headers @{Authorization="Bearer $token"} `
  -UseBasicParsing
```

## Mobile App Authentication Flow

### 1. Login

```dart
final authService = AuthService();
final result = await authService.login(
  email: 'farmer@smartpepper.com',
  password: 'Farmer123!',
);

if (result.success) {
  // Token is automatically saved
  // Navigate to home screen
  Navigator.pushReplacementNamed(context, '/home');
}
```

### 2. Get Current User

```dart
final user = await authService.getCurrentUser();
if (user != null) {
  print('Welcome ${user.name}!');
}
```

### 3. Check if Logged In

```dart
final token = await authService.getToken();
if (token != null) {
  // User is logged in
} else {
  // Show login screen
}
```

### 4. Logout

```dart
await authService.logout();
Navigator.pushReplacementNamed(context, '/login');
```

## API Endpoints Available

All endpoints are at: `http://localhost:3002/api`

### Authentication

- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `POST /auth/refresh` - Refresh token
- `GET /auth/me` - Get current user (requires Bearer token)

### Users

- `GET /users` - Get all users (admin only)
- `GET /users/:id` - Get single user
- `PUT /users/:id` - Update user
- `GET /users/:id/blockchain` - Get user's blockchain activity

### Auctions

- `GET /auctions` - List auctions
- `POST /auctions` - Create auction
- `GET /auctions/:id` - Get auction details
- `POST /auctions/:id/bid` - Place bid

## Troubleshooting

### "Connection refused" on mobile

✅ **Solution:** Make sure you're using the correct base URL:

- Android emulator: `10.0.2.2:3002`
- iOS simulator: `localhost:3002`
- Physical device: Your computer's IP (e.g., `192.168.1.100:3002`)

### "Invalid credentials"

✅ **Solution:**

- Check password is correct
- Verify user exists in database
- Run `.\create-test-users.ps1` to recreate users

### "Backend not responding"

✅ **Solution:**

```powershell
# Check if backend is running
netstat -ano | findstr :3002

# If not running, start it
cd backend
npm start
```

### "Database connection error"

✅ **Solution:**

- Make sure PostgreSQL is running
- Check `.env` file has DB_PASSWORD set
- Run database migrations:

```powershell
cd backend
node fix-wallet-nullable.js
```

## Next Steps

1. **Implement UI Screens:**

   - Login screen
   - Register screen
   - Home/Dashboard
   - Auctions list
   - Auction details
   - Profile screen

2. **Add State Management:**

   - Use Provider or Riverpod
   - Store user state globally
   - Handle authentication state

3. **Implement Features:**

   - View auctions
   - Place bids
   - View NFT passports
   - Update profile
   - Upload images

4. **Add Real-time Updates:**

   - WebSocket connection
   - Live auction updates
   - Bid notifications

5. **Security Enhancements:**
   - Use `flutter_secure_storage` instead of SharedPreferences
   - Add biometric authentication
   - Implement token refresh
   - Add SSL certificate pinning

## Files Created

1. **Backend:**

   - `fix-wallet-nullable.js` - Database migration script

2. **Mobile:**

   - `lib/config/api_config.dart` - API configuration
   - `lib/models/user.dart` - User model
   - `lib/services/auth_service.dart` - Authentication service

3. **Scripts:**

   - `create-test-users.ps1` - PowerShell script to create test users

4. **Documentation:**
   - `MOBILE_DATABASE_SETUP.md` - Complete setup guide
   - `QUICK_START_MOBILE_DB.md` - Quick reference
   - `TEST_CREDENTIALS.md` - Test user credentials
   - `MOBILE_DB_COMPLETE.md` - This file!

## Summary

✅ PostgreSQL database configured and running  
✅ Backend API accessible at http://localhost:3002  
✅ Test users created for development  
✅ Mobile app services configured  
✅ Same authentication works for web and mobile  
✅ Documentation completed

**You're ready to start mobile app development! 🎉**

Login with:

- Email: farmer@smartpepper.com
- Password: Farmer123!

---

Need help? Check the documentation files or run `.\create-test-users.ps1` to see all available test accounts.
