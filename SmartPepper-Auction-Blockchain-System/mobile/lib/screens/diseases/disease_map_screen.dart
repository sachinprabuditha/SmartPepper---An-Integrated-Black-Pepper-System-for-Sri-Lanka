import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartpepper_mobile/models/disease_location.dart';
import 'package:smartpepper_mobile/config/theme.dart';
import 'package:intl/intl.dart';
import '../../localization/app_localizations.dart';
import '../../services/disease_api_service.dart';

class DiseaseMapScreen extends StatefulWidget {
  const DiseaseMapScreen({super.key});

  @override
  State<DiseaseMapScreen> createState() => _DiseaseMapScreenState();
}

class _DiseaseMapScreenState extends State<DiseaseMapScreen> {
  GoogleMapController? _mapController;
  List<DiseaseLocation> _diseaseLocations = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final DiseaseApiService _apiService = DiseaseApiService();

  // Default location (Sri Lanka - Pepper growing region)
  static const LatLng _defaultLocation = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _loadDiseaseLocations();
  }

  Future<void> _loadDiseaseLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _apiService.getDiseaseLocations();

      setState(() {
        _diseaseLocations = locations;
        _createMarkers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content:
                Text('${context.tr('disease_error_loading_locations')}: $e')));
      }
    }
  }

  void _createMarkers() {
    _markers.clear();

    for (var location in _diseaseLocations) {
      _markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: location.coordinates,
          icon: location.getMarkerColor(),
          infoWindow: InfoWindow(
            title: location.diseaseName,
            snippet:
                '${location.getSeverityLevel()} - ${DateFormat('MMM dd, yyyy').format(location.detectedDate)}',
            onTap: () => _showDiseaseDetails(location),
          ),
        ),
      );
    }
  }

  void _showDiseaseDetails(DiseaseLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DiseaseDetailsSheet(location: location),
    );
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.map, color: AppTheme.pepperGold),
            const SizedBox(width: 8),
            Text(context.tr('disease_map_legend')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem('Healthy Plants', AppTheme.sriLankanLeaf),
            const SizedBox(height: 8),
            _buildLegendItem('Critical Severity (70%+)', Colors.red),
            const SizedBox(height: 8),
            _buildLegendItem('High Severity (40-69%)', Colors.orange),
            const SizedBox(height: 8),
            _buildLegendItem(
              'Moderate Severity (20-39%)',
              Colors.yellow[700]!,
            ),
            const SizedBox(height: 8),
            _buildLegendItem('Low Severity (<20%)', AppTheme.sriLankanLeaf),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.deepEmerald.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child:const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.pepperGold,
                      ),
                       SizedBox(width: 8),
                       Expanded(
                        child: Text(
                          'Disease Tracking Info:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Both healthy and infected plants are tracked\n• Green markers indicate healthy plants\n• Other colors indicate disease severity\n• Map displays your farm monitoring areas',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common_close')),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('disease_map_title')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLegend,
            tooltip: 'Show Legend',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _diseaseLocations.isNotEmpty
                        ? _diseaseLocations.first.coordinates
                        : _defaultLocation,
                    zoom: _diseaseLocations.isNotEmpty ? 15 : 8,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: true,
                ),

                // Info Card at bottom
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppTheme.pepperGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tracked Locations: ${_diseaseLocations.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  size: 20,
                                ),
                                onPressed: _showLegend,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          if (_diseaseLocations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green[600],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Great news! No infected plants detected yet.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Analyze plant images to track disease locations on this map.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Bottom Sheet for Disease Details
class DiseaseDetailsSheet extends StatelessWidget {
  final DiseaseLocation location;

  const DiseaseDetailsSheet({super.key, required this.location});

  Color _getSeverityColor(double severity) {
    if (severity >= 70) return Colors.red;
    if (severity >= 40) return Colors.orange;
    if (severity >= 20) return Colors.yellow[700]!;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  location.diseaseName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getSeverityColor(location.severity),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  location.getSeverityLevel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Severity
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '${context.tr('disease_severity')}: ${location.severity.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '${context.tr('disease_detected')} ${DateFormat('MMMM dd, yyyy').format(location.detectedDate)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Leaves
          Row(
            children: [
              const Icon(Icons.eco, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(
                '${context.tr('disease_total_leaves')} ${location.totalLeaves}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              const Icon(Icons.place, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('disease_location_label')} ${location.coordinates.latitude.toStringAsFixed(6)}, ${location.coordinates.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Disease Breakdown
          Text(
            context.tr('disease_breakdown'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...location.diseaseCounts.entries.map((entry) {
            if (entry.value == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('• ${entry.key}'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.tr('common_close')),
            ),
          ),
        ],
      ),
    );
  }
}
