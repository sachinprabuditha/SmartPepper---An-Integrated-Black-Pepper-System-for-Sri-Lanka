# SmartPepper Mobile App - Implementation Guide

## 🎯 Overview

This guide provides step-by-step instructions to complete the SmartPepper mobile application based on your research requirements.

## 📦 Setup Instructions

### Step 1: Initialize Flutter Project

```bash
cd mobile
flutter create .
flutter pub get
```

### Step 2: Update Android Configuration

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.NFC"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### Step 3: Update iOS Configuration

Edit `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan QR codes and capture lot images</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to upload certificates</string>
<key>NFCReaderUsageDescription</key>
<string>NFC is required to scan pepper lot tags</string>
```

### Step 4: Configure Environment

Create `lib/config/env.dart` and update with your backend URLs:

- Replace `CONTRACT_ADDRESS` with deployed contract address
- Update `apiBaseUrl` for your machine's IP (for physical devices)

## 🏗️ Implementation Roadmap

### Phase 1: Core Services (Priority: HIGH)

#### 1.1 API Service (`lib/services/api_service.dart`)

```dart
import 'package:dio/dio.dart';
import '../config/env.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors
        return handler.next(error);
      },
    ));
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/login', data: data);
    return response.data;
  }

  // Lot endpoints
  Future<List<dynamic>> getLots({String? farmerAddress}) async {
    final response = await _dio.get('/lots', queryParameters: {
      if (farmerAddress != null) 'farmer': farmerAddress,
    });
    return response.data['lots'];
  }

  Future<Map<String, dynamic>> createLot(Map<String, dynamic> data) async {
    final response = await _dio.post('/lots', data: data);
    return response.data;
  }

  // Auction endpoints
  Future<List<dynamic>> getAuctions() async {
    final response = await _dio.get('/auctions');
    return response.data['auctions'];
  }

  Future<Map<String, dynamic>> placeBid(String auctionId, double amount) async {
    final response = await _dio.post('/auctions/$auctionId/bid', data: {
      'amount': amount,
    });
    return response.data;
  }

  Future<String?> _getToken() async {
    // Implement token retrieval from secure storage
    return null;
  }
}
```

#### 1.2 Blockchain Service (`lib/services/blockchain_service.dart`)

```dart
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import '../config/env.dart';

class BlockchainService {
  late Web3Client _client;
  late DeployedContract _contract;

  BlockchainService() {
    _client = Web3Client(Environment.blockchainRpcUrl, Client());
    _initContract();
  }

  Future<void> _initContract() async {
    // Load ABI from assets/abis/PepperAuction.json
    final String abi = '...'; // Load from assets
    _contract = DeployedContract(
      ContractAbi.fromJson(abi, 'PepperAuction'),
      EthereumAddress.fromHex(Environment.contractAddress),
    );
  }

  Future<String> createAuction({
    required int tokenId,
    required double startingPrice,
    required int duration,
    required Credentials credentials,
  }) async {
    final function = _contract.function('createAuction');
    final result = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [
          BigInt.from(tokenId),
          EtherAmount.fromUnitAndValue(EtherUnit.ether, startingPrice).getInWei,
          BigInt.from(duration),
        ],
      ),
      chainId: 31337, // Hardhat local
    );
    return result;
  }

  Future<String> placeBid({
    required int tokenId,
    required double bidAmount,
    required Credentials credentials,
  }) async {
    final function = _contract.function('placeBid');
    final result = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [BigInt.from(tokenId)],
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, bidAmount),
      ),
      chainId: 31337,
    );
    return result;
  }
}
```

#### 1.3 Socket Service (`lib/services/socket_service.dart`)

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/env.dart';

class SocketService {
  late IO.Socket _socket;
  bool _connected = false;

  void connect() {
    _socket = IO.io(Environment.wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.on('connect', (_) {
      print('Socket connected');
      _connected = true;
    });

    _socket.on('disconnect', (_) {
      print('Socket disconnected');
      _connected = false;
    });
  }

  void disconnect() {
    _socket.disconnect();
    _connected = false;
  }

  void joinAuction(String auctionId) {
    _socket.emit('joinAuction', {'auctionId': auctionId});
  }

  void leaveAuction(String auctionId) {
    _socket.emit('leaveAuction', {'auctionId': auctionId});
  }

  void onNewBid(Function(dynamic) callback) {
    _socket.on('newBid', callback);
  }

  void onAuctionEnd(Function(dynamic) callback) {
    _socket.on('auctionEnded', callback);
  }

  bool get isConnected => _connected;
}
```

### Phase 2: Models (`lib/models/`)

#### 2.1 User Model

```dart
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'farmer' or 'exporter'
  final String? walletAddress;
  final bool verified;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.walletAddress,
    this.verified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      walletAddress: json['walletAddress'],
      verified: json['verified'] ?? false,
    );
  }
}
```

#### 2.2 Lot Model

```dart
class Lot {
  final String id;
  final String lotId;
  final String farmerName;
  final String farmerAddress;
  final String variety;
  final double quantity;
  final DateTime harvestDate;
  final String complianceStatus;
  final String? complianceCertificate;
  final String status;

  Lot({
    required this.id,
    required this.lotId,
    required this.farmerName,
    required this.farmerAddress,
    required this.variety,
    required this.quantity,
    required this.harvestDate,
    required this.complianceStatus,
    this.complianceCertificate,
    required this.status,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json['id'],
      lotId: json['lotId'],
      farmerName: json['farmerName'],
      farmerAddress: json['farmerAddress'],
      variety: json['variety'],
      quantity: json['quantity'].toDouble(),
      harvestDate: DateTime.parse(json['harvestDate']),
      complianceStatus: json['complianceStatus'],
      complianceCertificate: json['complianceCertificate'],
      status: json['status'],
    );
  }
}
```

#### 2.3 Auction Model

```dart
class Auction {
  final String id;
  final String tokenId;
  final String lotId;
  final String farmerAddress;
  final double startingPrice;
  final double currentBid;
  final String? highestBidder;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Auction({
    required this.id,
    required this.tokenId,
    required this.lotId,
    required this.farmerAddress,
    required this.startingPrice,
    required this.currentBid,
    this.highestBidder,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'],
      tokenId: json['tokenId'],
      lotId: json['lotId'],
      farmerAddress: json['farmerAddress'],
      startingPrice: json['startingPrice'].toDouble(),
      currentBid: json['currentBid'].toDouble(),
      highestBidder: json['highestBidder'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
    );
  }
}
```

### Phase 3: Providers (State Management)

#### 3.1 Auth Provider (`lib/providers/auth_provider.dart`)

```dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/blockchain_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;
  final StorageService storageService;
  final BlockchainService blockchainService;

  User? _user;
  bool _isAuthenticated = false;
  bool _loading = false;

  AuthProvider({
    required this.apiService,
    required this.storageService,
    required this.blockchainService,
  });

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get loading => _loading;

  Future<void> checkAuthStatus() async {
    _loading = true;
    notifyListeners();

    final token = await storageService.getToken();
    if (token != null) {
      // Validate token and fetch user
      try {
        final userData = await apiService.getCurrentUser();
        _user = User.fromJson(userData);
        _isAuthenticated = true;
      } catch (e) {
        await logout();
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();

      final response = await apiService.login({
        'email': email,
        'password': password,
      });

      await storageService.saveToken(response['token']);
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await storageService.clearToken();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

### Phase 4: UI Screens

#### 4.1 Splash Screen (`lib/screens/splash_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      if (authProvider.user?.role == 'farmer') {
        context.go('/farmer/dashboard');
      } else {
        context.go('/exporter/dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'SmartPepper',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            const Text('Blockchain-Enabled Pepper Exports'),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 Next Steps

### Immediate Tasks:

1. ✅ Run `flutter pub get` to install dependencies
2. ✅ Update contract address in `lib/config/env.dart`
3. ✅ Copy smart contract ABI to `assets/abis/PepperAuction.json`
4. ✅ Implement remaining screens (login, register, dashboards)
5. ✅ Test on Android emulator first
6. ✅ Add error handling and loading states
7. ✅ Implement QR code generation and scanning
8. ✅ Add multilingual support

### Testing Checklist:

- [ ] User registration and login
- [ ] Wallet connection via MetaMask
- [ ] Lot creation with image upload
- [ ] Certificate upload and validation
- [ ] Real-time auction bidding (<300ms)
- [ ] QR code generation and scanning
- [ ] Traceability dashboard
- [ ] Offline mode and sync
- [ ] Push notifications

### Performance Optimization:

- [ ] Implement image compression
- [ ] Add pagination for lot lists
- [ ] Cache API responses
- [ ] Optimize blockchain calls
- [ ] Reduce app size

## 📱 Running the App

```bash
# Check Flutter setup
flutter doctor

# Get dependencies
flutter pub get

# Run on Android
flutter run

# Run on iOS (Mac only)
flutter run -d ios

# Build release APK
flutter build apk --release

# Build iOS app
flutter build ios --release
```

## 🔗 Integration with Backend

Ensure your backend is running:

```bash
# Terminal 1: Blockchain
cd blockchain
npm run node

# Terminal 2: Deploy Contract
cd blockchain
npm run deploy:local

# Terminal 3: Backend
cd backend
npm run dev
```

Update contract address in mobile app after deployment.

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Web3Dart Guide](https://pub.dev/packages/web3dart)
- [Go Router](https://pub.dev/packages/go_router)
- [Provider State Management](https://pub.dev/packages/provider)

## 🆘 Troubleshooting

### Issue: Cannot connect to backend

**Solution**: Use correct IP address:

- Android emulator: `10.0.2.2`
- iOS simulator: `localhost`
- Physical device: Your machine's IP (e.g., `192.168.1.x`)

### Issue: Contract calls failing

**Solution**:

- Verify contract is deployed
- Check contract address is correct
- Ensure blockchain node is running
- Verify wallet has test ETH

### Issue: WebSocket not connecting

**Solution**:

- Check backend WebSocket server is running
- Verify firewall allows WebSocket connections
- Test with different network

---

**Your mobile app foundation is ready!** Focus on implementing the remaining screens based on the patterns established above. Each component follows the research requirements for blockchain traceability, real-time auctions, and compliance automation.
