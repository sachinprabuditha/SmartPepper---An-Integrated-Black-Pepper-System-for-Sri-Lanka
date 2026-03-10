import 'package:google_maps_flutter/google_maps_flutter.dart';

class DiseaseLocation {
  final String id;
  final LatLng coordinates;
  final String diseaseName;
  final double severity;
  final DateTime detectedDate;
  final int totalLeaves;
  final Map<String, int> diseaseCounts;
  final String? imagePath;
  final bool isHealthy;

  DiseaseLocation({
    required this.id,
    required this.coordinates,
    required this.diseaseName,
    required this.severity,
    required this.detectedDate,
    required this.totalLeaves,
    required this.diseaseCounts,
    this.imagePath,
    this.isHealthy = false,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'diseaseName': diseaseName,
      'severity': severity,
      'detectedDate': detectedDate.toIso8601String(),
      'totalLeaves': totalLeaves,
      'diseaseCounts': diseaseCounts,
      'imagePath': imagePath,
      'isHealthy': isHealthy,
    };
  }


  factory DiseaseLocation.fromJson(Map<String, dynamic> json) {
    return DiseaseLocation(
      id: json['id'],
      coordinates: LatLng(json['latitude'], json['longitude']),
      diseaseName: json['diseaseName'],
      severity: json['severity'].toDouble(),
      detectedDate: DateTime.parse(json['detectedDate']),
      totalLeaves: json['totalLeaves'],
      diseaseCounts: Map<String, int>.from(json['diseaseCounts']),
      imagePath: json['imagePath'],
      isHealthy: json['isHealthy'] ?? false,
    );
  }

  BitmapDescriptor getMarkerColor() {
    // Healthy plants get a bright green marker
    if (isHealthy) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    
    // Diseased plants get color-coded by severity
    if (severity >= 70) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (severity >= 40) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    } else if (severity >= 20) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  String getSeverityLevel() {
    if (isHealthy) return 'Healthy';
    if (severity >= 70) return 'Critical';
    if (severity >= 40) return 'High';
    if (severity >= 20) return 'Moderate';
    return 'Low';
  }
}
