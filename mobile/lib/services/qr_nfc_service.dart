import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

/// Service for generating QR codes and NFC tags for pepper lots
class QrNfcService {
  /// Generate QR code data for a lot
  /// Returns a JSON string containing lot identifier and verification info
  String generateQrData({
    required String lotId,
    required String farmerId,
    required String farmerName,
    required String variety,
    required double quantity,
    required String quality,
    required DateTime harvestDate,
    String? blockchainHash,
  }) {
    final data = {
      'lotId': lotId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'variety': variety,
      'quantity': quantity,
      'quality': quality,
      'harvestDate': harvestDate.toIso8601String(),
      'blockchainHash': blockchainHash,
      'timestamp': DateTime.now().toIso8601String(),
      'verified': blockchainHash != null,
    };

    return jsonEncode(data);
  }

  /// Parse QR code data back to a map
  Map<String, dynamic>? parseQrData(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Generate NFC tag identifier
  /// Creates a unique NFC identifier for physical tags
  String generateNfcTag({
    required String lotId,
    required String farmerId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'NFC-$farmerId-$lotId-$timestamp';
  }

  /// Verify QR code data integrity
  bool verifyQrData(String qrData) {
    final data = parseQrData(qrData);
    if (data == null) return false;

    // Check required fields
    final requiredFields = ['lotId', 'farmerId', 'variety', 'quantity'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return false;
      }
    }

    return true;
  }

  /// Generate a QR code widget for display
  Widget buildQrCode({
    required String qrData,
    double size = 200,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor ?? Colors.white,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor ?? Colors.black,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor ?? Colors.black,
      ),
    );
  }

  /// Generate printable QR code with lot information
  Widget buildPrintableQrCard({
    required String lotId,
    required String qrData,
    required String variety,
    required double quantity,
    required String quality,
    required DateTime harvestDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'SmartPepper Lot',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lotId,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          buildQrCode(qrData: qrData, size: 250),
          const SizedBox(height: 24),
          _buildInfoRow('Variety', variety),
          _buildInfoRow('Quantity', '$quantity kg'),
          _buildInfoRow('Quality', quality),
          _buildInfoRow(
            'Harvest Date',
            '${harvestDate.year}-${harvestDate.month.toString().padLeft(2, '0')}-${harvestDate.day.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan for complete traceability',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Create verification URL for QR code
  String generateVerificationUrl({
    required String lotId,
    required String baseUrl,
  }) {
    return '$baseUrl/verify/$lotId';
  }
}
