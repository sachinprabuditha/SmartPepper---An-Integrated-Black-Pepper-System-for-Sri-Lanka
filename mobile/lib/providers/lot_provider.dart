import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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
  final String? quality;
  final DateTime? createdAt;

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
    this.quality,
    this.createdAt,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json['id']?.toString() ?? '',
      lotId: json['lot_id'] ?? json['lotId'] ?? '',
      farmerName: json['farmer_name'] ?? json['farmerName'] ?? '',
      farmerAddress: json['farmer_address'] ?? json['farmerAddress'] ?? '',
      variety: json['variety'] ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      harvestDate: DateTime.tryParse(
              json['harvest_date'] ?? json['harvestDate'] ?? '') ??
          DateTime.now(),
      complianceStatus:
          json['compliance_status'] ?? json['complianceStatus'] ?? 'pending',
      complianceCertificate:
          json['compliance_certificate'] ?? json['complianceCertificate'],
      status: json['status'] ?? 'available',
      quality: json['quality'],
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
              DateTime.now(),
    );
  }
}

class LotProvider with ChangeNotifier {
  final ApiService apiService;
  final StorageService storageService;

  List<Lot> _lots = [];
  bool _loading = false;
  String? _error;

  LotProvider({required this.apiService, required this.storageService});

  List<Lot> get lots => _lots;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchLots({String? farmerAddress}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.getLots(farmerAddress: farmerAddress);
      _lots = response.map((json) => Lot.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> createLot(Map<String, dynamic> lotData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.createLot(lotData);
      await fetchLots(); // Refresh list
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
