import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService(this._storage);

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // User data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: 'user_data', value: userData.toString());
  }

  Future<String?> getUserData() async {
    return await _storage.read(key: 'user_data');
  }

  Future<void> clearUserData() async {
    await _storage.delete(key: 'user_data');
  }

  // Wallet
  Future<void> saveWalletAddress(String address) async {
    await _storage.write(key: 'wallet_address', value: address);
  }

  Future<String?> getWalletAddress() async {
    return await _storage.read(key: 'wallet_address');
  }

  Future<void> savePrivateKey(String privateKey) async {
    await _storage.write(key: 'private_key', value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: 'private_key');
  }

  // Generic storage methods
  Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> saveInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<int?> getInt(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
