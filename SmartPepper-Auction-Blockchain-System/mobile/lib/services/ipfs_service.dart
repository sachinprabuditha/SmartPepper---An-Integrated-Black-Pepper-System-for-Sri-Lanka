import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env.dart';

/// Service for interacting with IPFS for certificate and document storage
class IpfsService {
  final String _ipfsApiUrl;
  final String _ipfsGatewayUrl;

  IpfsService({
    String? ipfsApiUrl,
    String? ipfsGatewayUrl,
  })  : _ipfsApiUrl = ipfsApiUrl ?? Environment.ipfsApiUrl,
        _ipfsGatewayUrl = ipfsGatewayUrl ?? Environment.ipfsGatewayUrl;

  /// Upload a file to IPFS
  /// Returns the IPFS hash (CID) of the uploaded file
  Future<String> uploadFile(File file) async {
    try {
      print('Uploading to IPFS: ${file.path}');
      print('IPFS API URL: $_ipfsApiUrl/api/v0/add');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ipfsApiUrl/api/v0/add'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      // Set timeout for the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('IPFS upload timed out after 60 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('IPFS upload response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hash = data['Hash'] as String;
        print('IPFS upload successful: $hash');
        return hash;
      } else {
        throw Exception(
            'Failed to upload to IPFS: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('IPFS upload error: $e');
      throw Exception('IPFS upload error: $e');
    }
  }

  /// Upload multiple files to IPFS
  /// Returns a list of IPFS hashes
  Future<List<String>> uploadMultipleFiles(List<File> files) async {
    final hashes = <String>[];

    for (final file in files) {
      try {
        final hash = await uploadFile(file);
        hashes.add(hash);
      } catch (e) {
        // Continue uploading other files even if one fails
        print('Failed to upload ${file.path}: $e');
      }
    }

    return hashes;
  }

  /// Upload JSON data to IPFS
  /// Useful for storing lot metadata
  Future<String> uploadJson(Map<String, dynamic> data) async {
    try {
      print('Uploading JSON to IPFS');
      final jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_ipfsApiUrl/api/v0/add'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'metadata.json',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('IPFS JSON upload timed out after 30 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('IPFS JSON upload response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final hash = responseData['Hash'] as String;
        print('IPFS JSON upload successful: $hash');
        return hash;
      } else {
        throw Exception(
            'Failed to upload JSON to IPFS: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('IPFS JSON upload error: $e');
      throw Exception('IPFS JSON upload error: $e');
    }
  }

  /// Get the full IPFS URL for a hash
  String getIpfsUrl(String hash) {
    return '$_ipfsGatewayUrl/ipfs/$hash';
  }

  /// Download file from IPFS
  Future<List<int>> downloadFile(String hash) async {
    try {
      final url = getIpfsUrl(hash);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download from IPFS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('IPFS download error: $e');
    }
  }

  /// Retrieve JSON data from IPFS
  Future<Map<String, dynamic>> downloadJson(String hash) async {
    try {
      final bytes = await downloadFile(hash);
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('IPFS JSON download error: $e');
    }
  }

  /// Upload lot certificates and metadata to IPFS
  /// Returns a map with certificate hashes and metadata URI
  Future<Map<String, dynamic>> uploadLotData({
    required List<File> certificates,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Upload certificates
      final certificateHashes = await uploadMultipleFiles(certificates);

      // Add certificate references to metadata
      metadata['certificates'] = certificateHashes;
      metadata['uploadedAt'] = DateTime.now().toIso8601String();

      // Upload metadata
      final metadataHash = await uploadJson(metadata);

      return {
        'certificateHashes': certificateHashes,
        'metadataHash': metadataHash,
        'metadataUri': getIpfsUrl(metadataHash),
        'certificateUrls': certificateHashes.map((h) => getIpfsUrl(h)).toList(),
      };
    } catch (e) {
      throw Exception('Failed to upload lot data to IPFS: $e');
    }
  }

  /// Verify if an IPFS hash is accessible
  Future<bool> verifyHash(String hash) async {
    try {
      final url = getIpfsUrl(hash);
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Pin a file to ensure it persists in IPFS
  Future<bool> pinFile(String hash) async {
    try {
      final response = await http.post(
        Uri.parse('$_ipfsApiUrl/api/v0/pin/add?arg=$hash'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to pin file: $e');
      return false;
    }
  }
}
