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
      id: json['id'] ?? '',
      lotId: json['lotId'] ?? '',
      farmerName: json['farmerName'] ?? '',
      farmerAddress: json['farmerAddress'] ?? '',
      variety: json['variety'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      harvestDate:
          DateTime.tryParse(json['harvestDate'] ?? '') ?? DateTime.now(),
      complianceStatus: json['complianceStatus'] ?? 'pending',
      complianceCertificate: json['complianceCertificate'],
      status: json['status'] ?? 'available',
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
