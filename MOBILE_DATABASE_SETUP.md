# Mobile App Database Setup Guide

## Overview

This guide explains how to connect your Flutter mobile app to the same PostgreSQL database used by the web application, enabling shared authentication and data.

## Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   Web App       │         │  Mobile App     │
│  (Next.js)      │         │  (Flutter)      │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │                           │
         └───────────┬───────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Backend API Server   │
         │  (Node.js + Express)  │
         │  Port: 3002           │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  PostgreSQL Database  │
         │  Port: 5432           │
         └───────────────────────┘
```

## Step 1: PostgreSQL Database Setup

### Install PostgreSQL

If not already installed:

**Windows:**

```powershell
# Download from https://www.postgresql.org/download/windows/
# Or use chocolatey:
choco install postgresql
```

**After installation:**

1. Open pgAdmin or psql
2. Create the database:

```sql
CREATE DATABASE smartpepper;
```

### Run Database Migrations

```powershell
cd backend

# Create all necessary tables
psql -U postgres -d smartpepper -f create-tables.sql

# Or if you have migration scripts:
npm run migrate
```

## Step 2: Backend Configuration

### Update .env File

Ensure your `backend/.env` has PostgreSQL configured:

```env
# Database Configuration (PostgreSQL)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=smartpepper
DB_USER=postgres
DB_PASSWORD=your_postgres_password

# JWT Configuration (important for mobile auth)
JWT_SECRET=your-secure-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d

# Server Configuration
PORT=3002
NODE_ENV=development

# Allow mobile connections
CORS_ORIGIN=*
```

### Start Backend Server

```powershell
cd backend
npm start
```

The server should log: `Database: Using PostgreSQL`

## Step 3: Mobile App Configuration

### API Configuration File

Create or update `mobile/lib/config/api_config.dart`:

```dart
class ApiConfig {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3002';

  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:3002';

  // For Real Device (use your computer's IP)
  // static const String baseUrl = 'http://192.168.1.100:3002';

  // API Endpoints
  static const String authEndpoint = '/api/auth';
  static const String usersEndpoint = '/api/users';
  static const String auctionsEndpoint = '/api/auctions';
  static const String lotsEndpoint = '/api/lots';
  static const String bidsEndpoint = '/api/bids';
  static const String nftPassportEndpoint = '/api/nft-passports';

  // Full URLs
  static String get loginUrl => '$baseUrl$authEndpoint/login';
  static String get registerUrl => '$baseUrl$authEndpoint/register';
  static String get refreshUrl => '$baseUrl$authEndpoint/refresh';
  static String get logoutUrl => '$baseUrl$authEndpoint/logout';
}
```

### Authentication Service

Create `mobile/lib/services/auth_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Register User
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'farmer', 'exporter', 'admin'
    String? phone,
    String? walletAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'phone': phone,
          'walletAddress': walletAddress,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Save tokens
        await _saveTokens(data['token'], data['refreshToken']);
        await _saveUser(data['user']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Login User
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens and user data
        await _saveTokens(data['token'], data['refreshToken']);
        await _saveUser(data['user']);
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get Current User
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Private helper methods
  Future<void> _saveTokens(String token, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }
}
```

### API Service (for authenticated requests)

Create `mobile/lib/services/api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': jsonDecode(response.body),
        'statusCode': response.statusCode,
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get all auctions
  Future<List<dynamic>> getAuctions() async {
    final result = await get('/api/auctions');
    if (result['success']) {
      return result['data']['auctions'] ?? [];
    }
    return [];
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final result = await get('/api/users/$userId');
    if (result['success']) {
      return result['data']['user'];
    }
    return null;
  }

  // Place a bid
  Future<bool> placeBid(int auctionId, String amount) async {
    final result = await post('/api/auctions/$auctionId/bid', {
      'amount': amount,
    });
    return result['success'];
  }
}
```

### Add Dependencies

Update `mobile/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  provider: ^6.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Then run:

```bash
cd mobile
flutter pub get
```

## Step 4: Test the Connection

### Create a Test Login Screen

Create `mobile/lib/screens/test_login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TestLoginScreen extends StatefulWidget {
  @override
  _TestLoginScreenState createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _message = 'Login successful! User: ${result['user']['name']}';
      } else {
        _message = 'Error: ${result['error']}';
      }
    });
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
              onPressed: _isLoading ? null : _testLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Test Login'),
            ),
            SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
```

## Step 5: Network Configuration

### For Android Emulator

The API URL `http://10.0.2.2:3002` routes to your host machine's localhost.

No additional setup needed.

### For iOS Simulator

Use `http://localhost:3002` or your machine's IP address.

### For Real Device

1. Find your computer's local IP:

   ```powershell
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.100)
   ```

2. Update API config:

   ```dart
   static const String baseUrl = 'http://192.168.1.100:3002';
   ```

3. Ensure firewall allows connections on port 3002

4. Both devices must be on the same network

## Available API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user

### Users

- `GET /api/users` - Get all users (admin)
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `GET /api/users/:id/blockchain` - Get blockchain activity

### Auctions

- `GET /api/auctions` - Get all auctions
- `GET /api/auctions/:id` - Get auction details
- `POST /api/auctions` - Create auction
- `POST /api/auctions/:id/bid` - Place bid
- `GET /api/auctions/:id/bids` - Get auction bids

### Lots

- `GET /api/lots` - Get all lots
- `POST /api/lots` - Create lot
- `GET /api/lots/:lotId` - Get lot details

### NFT Passports

- `GET /api/nft-passports` - Get all NFT passports
- `GET /api/nft-passports/:tokenId` - Get NFT details

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- 'farmer', 'exporter', 'admin'
    wallet_address VARCHAR(42) UNIQUE,
    phone VARCHAR(20),
    verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ
);
```

## Testing Checklist

- [ ] PostgreSQL is installed and running
- [ ] Database `smartpepper` is created
- [ ] Tables are created (run migrations)
- [ ] Backend .env has correct DB credentials
- [ ] Backend server is running on port 3002
- [ ] Mobile app can reach the API (test with curl or Postman)
- [ ] Register a test user from mobile app
- [ ] Login with test user
- [ ] JWT token is saved and used for authenticated requests

## Troubleshooting

### "Network error" on mobile

- Check if backend is running: `curl http://localhost:3002/api/health`
- Verify API URL in mobile config
- For real device, ensure same WiFi network

### "Database not configured"

- Ensure `DB_PASSWORD` is set in `.env`
- Check PostgreSQL is running: `pg_isready`

### "Connection refused"

- Check firewall settings
- Verify port 3002 is not blocked
- For Windows: Allow Node.js through firewall

### "JWT token invalid"

- Token might be expired
- Check JWT_SECRET matches between requests
- Try logout and login again

## Production Considerations

1. **Security**:

   - Change JWT_SECRET to a strong secret
   - Use HTTPS for API
   - Implement rate limiting
   - Add input validation

2. **Database**:

   - Use connection pooling
   - Add database backups
   - Implement migrations properly

3. **API**:

   - Deploy backend to cloud (AWS, Azure, etc.)
   - Use environment-specific configs
   - Add API monitoring

4. **Mobile**:
   - Update API base URL to production server
   - Implement token refresh logic
   - Add offline support with local storage
