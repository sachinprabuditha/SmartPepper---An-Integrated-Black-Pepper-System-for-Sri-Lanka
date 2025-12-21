# Quick Start Guide - Shared Database Setup

## ✅ Your Current Setup

Your project already has most components configured! Here's what's ready:

### Backend (Node.js + Express)

- ✅ PostgreSQL configuration in `.env`
- ✅ Authentication system (`/api/auth/login`, `/api/auth/register`)
- ✅ JWT-based authentication
- ✅ CORS enabled for API access
- ✅ All necessary routes (auctions, lots, users, nft-passports)

### Mobile App (Flutter)

- ✅ API service with Dio
- ✅ Environment configuration (`lib/config/env.dart`)
- ✅ All required dependencies installed

## 🚀 Steps to Connect Mobile to PostgreSQL

### 1. Ensure PostgreSQL is Running

```powershell
# Check if PostgreSQL is running
pg_isready

# If not running, start the service:
Start-Service postgresql-x64-16  # Adjust version number as needed
```

### 2. Verify Backend Configuration

Check that your `backend/.env` file has the PostgreSQL password set:

```env
DB_PASSWORD=postgres  # or your actual password
```

If the password is missing, the backend will use the mock database.

### 3. Start the Backend Server

```powershell
cd backend
npm start
```

You should see:

```
2025-12-21 XX:XX:XX [info]: Database: Using PostgreSQL
2025-12-21 XX:XX:XX [info]: Server running on port 3002
```

### 4. Test the Connection

```powershell
# Test the API is accessible
curl http://localhost:3002/api/auth/login -Method POST -Body '{"email":"test@example.com","password":"password"}' -ContentType "application/json"
```

### 5. Update Mobile App Configuration

Your mobile app already has the correct configuration in `mobile/lib/config/env.dart`:

```dart
static const String apiBaseUrl = 'http://10.0.2.2:3002/api'; // Android emulator
```

**For different testing scenarios:**

- **Android Emulator**: Use `http://10.0.2.2:3002/api` ✅ (Already configured)
- **iOS Simulator**: Change to `http://localhost:3002/api`
- **Physical Device**: Use your PC's IP address (e.g., `http://192.168.1.100:3002/api`)

To find your IP address:

```powershell
ipconfig
# Look for IPv4 Address under your active network adapter
```

### 6. Run the Mobile App

```bash
cd mobile

# For Android Emulator
flutter run

# For specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## 🔐 Using the Same Logins

### Register a User from Web

1. Open web app: `http://localhost:3000`
2. Register a new user (e.g., `farmer@test.com`)
3. User data is stored in PostgreSQL `users` table

### Login from Mobile

1. Open mobile app
2. Use the same credentials: `farmer@test.com`
3. The mobile app will authenticate against the same database!

### How It Works

```
┌─────────────┐         ┌─────────────┐
│   Web App   │         │  Mobile App │
│ (Next.js)   │         │  (Flutter)  │
└──────┬──────┘         └──────┬──────┘
       │                       │
       │  POST /api/auth/login │
       │                       │
       └──────────┬────────────┘
                  │
                  ▼
       ┌──────────────────────┐
       │   Backend API        │
       │   (Port 3002)        │
       └──────────┬───────────┘
                  │
                  ▼
       ┌──────────────────────┐
       │  PostgreSQL Database │
       │  (users table)       │
       └──────────────────────┘
```

## 📱 Test Authentication Flow

### From Mobile App

The mobile app should have authentication screens. If not, here's a quick test:

Create a test file: `mobile/lib/screens/auth_test_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthTestScreen extends StatefulWidget {
  @override
  _AuthTestScreenState createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _result = '';

  Future<void> _testLogin() async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      setState(() {
        if (response.data['success']) {
          _result = 'Success! Logged in as: ${response.data['user']['name']}';
        } else {
          _result = 'Failed: ${response.data['error']}';
        }
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Database Connection')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testLogin,
              child: Text('Test Login'),
            ),
            SizedBox(height: 20),
            Text(_result),
          ],
        ),
      ),
    );
  }
}
```

## 🔧 Troubleshooting

### "Connection Refused" Error

**Problem**: Mobile app can't connect to backend

**Solutions**:

1. Verify backend is running: `curl http://localhost:3002/health`
2. For physical device, ensure same WiFi network
3. Check Windows Firewall allows port 3002
4. Update mobile app API URL to use correct IP

### "Database not configured" Message

**Problem**: Backend is using mock database

**Solution**: Set `DB_PASSWORD` in `backend/.env`

### "JWT Token Invalid"

**Problem**: Token expired or not sent correctly

**Solution**:

1. Check if token is being saved in mobile app (SharedPreferences)
2. Verify token is included in request headers
3. Try logout and login again

### "Network Error" on Physical Device

**Problem**: Device can't reach the server

**Solutions**:

1. Find PC IP: `ipconfig` (e.g., 192.168.1.100)
2. Update mobile `env.dart`:
   ```dart
   static const String apiBaseUrl = 'http://192.168.1.100:3002/api';
   ```
3. Allow firewall rule:
   ```powershell
   New-NetFirewallRule -DisplayName "Node Backend" -Direction Inbound -LocalPort 3002 -Protocol TCP -Action Allow
   ```

## 📊 Verify Database Connection

### Check Users in Database

```powershell
# Connect to PostgreSQL
psql -U postgres -d smartpepper

# List all users
SELECT id, email, name, role, verified FROM users;

# Exit
\q
```

### API Endpoints Available

All these work with the same authentication:

**Authentication:**

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user

**Users:**

- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user

**Auctions:**

- `GET /api/auctions` - Get all auctions
- `POST /api/auctions` - Create auction
- `GET /api/auctions/:id` - Get auction details
- `POST /api/auctions/:id/bid` - Place bid

**Lots:**

- `GET /api/lots` - Get all lots
- `POST /api/lots` - Create lot
- `GET /api/lots/:lotId` - Get lot details

**NFT Passports:**

- `GET /api/nft-passports` - Get all NFT passports
- `GET /api/nft-passports/:tokenId` - Get NFT details

## ✨ You're All Set!

Your mobile app and web app now share:

- ✅ Same PostgreSQL database
- ✅ Same user accounts
- ✅ Same authentication system
- ✅ Same auction data
- ✅ Same NFT passport data

Login credentials work across both platforms!

## 📝 Next Steps

1. Start developing mobile UI screens
2. Implement real-time updates via WebSocket
3. Add blockchain wallet integration
4. Test with real devices on same network
5. Prepare for production deployment

For detailed API documentation, see: [MOBILE_DATABASE_SETUP.md](./MOBILE_DATABASE_SETUP.md)
