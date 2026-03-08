import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpepper_mobile/models/disease_location.dart';
import 'image_upload_screen.dart';
import 'spread_forecasting_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AnalysisResultScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final File originalImage;
  final Position? currentPosition;

  const AnalysisResultScreen({
    super.key,
    required this.analysisResult,
    required this.originalImage,
    this.currentPosition,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _isSavingLocation = false;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveLocationIfInfected();
    });
  }

  Future<void> _saveLocationIfInfected() async {
    final severity = (widget.analysisResult['severity'] as num).toDouble();
    final counts = widget.analysisResult['counts'] as Map<String, dynamic>;

    bool hasDisease = false;
    String primaryDisease = 'Unknown';

    for (var entry in counts.entries) {
      if (entry.key.toLowerCase() != 'healthy leaves' &&
          entry.key.toLowerCase() != 'healthy' &&
          entry.value > 0) {
        hasDisease = true;
        if (primaryDisease == 'Unknown' ||
            entry.value > counts[primaryDisease]) {
          primaryDisease = entry.key;
        }
      }
    }

    if (hasDisease && widget.currentPosition != null) {
      await _saveDiseaseLocation(primaryDisease, severity);
    }
  }

  Future<void> _saveDiseaseLocation(String diseaseName, double severity) async {
    if (_isSavingLocation || widget.currentPosition == null) return;

    setState(() {
      _isSavingLocation = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList('disease_locations') ?? [];

      final newLocation = DiseaseLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        coordinates: LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        diseaseName: diseaseName,
        severity: severity,
        detectedDate: DateTime.now(),
        totalLeaves: widget.analysisResult['total_detected'] ?? 0,
        diseaseCounts: Map<String, int>.from(widget.analysisResult['counts']),
        imagePath: widget.originalImage.path,
      );

      locationsJson.add(jsonEncode(newLocation.toJson()));
      await prefs.setStringList('disease_locations', locationsJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Disease location saved to map: $diseaseName'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Map',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSavingLocation = false;
      });
    }
  }

  Color _getSeverityColor(double severity) {
    if (severity < 20) {
      return Colors.green;
    } else if (severity <= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getSeverityLabel(double severity) {
    if (severity < 20) {
      return 'Low';
    } else if (severity <= 50) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  Color _getHealthColor(double health) {
    if (health >= 80) return Colors.green;
    if (health >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getHealthLabel(double health) {
    if (health >= 80) return 'Good';
    if (health >= 50) return 'Fair';
    return 'Poor';
  }

  Widget _buildSeverityCard({
    required String title,
    required double score,
    required bool isHealthScore,
    required int totalLeaves,
  }) {
    Color cardColor =
        isHealthScore ? _getHealthColor(score) : _getSeverityColor(score);
    String label =
        isHealthScore ? _getHealthLabel(score) : _getSeverityLabel(score);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [cardColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CircularPercentIndicator(
              radius: 70.0,
              lineWidth: 12.0,
              percent: score / 100,
              center: Text(
                '${score.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              progressColor: cardColor,
              backgroundColor: Colors.grey[300]!,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Total Leaves Detected: $totalLeaves',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severity = (widget.analysisResult['severity'] as num).toDouble();
    final diseaseSpecificSeverity =
        widget.analysisResult['disease_specific_severity']
            as Map<String, dynamic>? ??
        {};
    final totalLeaves = widget.analysisResult['total_detected'] ?? 0;
    final counts = widget.analysisResult['counts'] as Map<String, dynamic>;

    List<Widget> severityCards = [];

    // Whole Tree Severity Card
    severityCards.add(
      _buildSeverityCard(
        title: 'Whole Tree Severity',
        score: severity,
        isHealthScore: false,
        totalLeaves: totalLeaves,
      ),
    );

    // Disease Specific Cards
    diseaseSpecificSeverity.forEach((disease, diseaseSeverity) {
      if ((diseaseSeverity as num).toDouble() > 0) {
        severityCards.add(
          _buildSeverityCard(
            title: '$disease Severity',
            score: diseaseSeverity.toDouble(),
            isHealthScore: false,
            totalLeaves: totalLeaves,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate back to home with fresh image upload screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const ImageUploadScreen(),
                ),
                (route) => false,
              );
            },
            tooltip: 'Back to Home',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Info Card (if available)
              if (widget.currentPosition != null)
                Card(
                  elevation: 4,
                  color: Colors.green[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location Captured',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.currentPosition!.latitude.toStringAsFixed(6)}, ${widget.currentPosition!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.currentPosition != null) const SizedBox(height: 16),

              CarouselSlider(
                options: CarouselOptions(
                  height: 320.0,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: severityCards.length > 1,
                  viewportFraction: 1.0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentCarouselIndex = index;
                    });
                  },
                ),
                items: severityCards,
              ),
              const SizedBox(height: 12),
              // Dot Indicator
              if (severityCards.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    severityCards.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentCarouselIndex == index ? 12 : 8,
                      height: _currentCarouselIndex == index ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentCarouselIndex == index
                                ? const Color(0xFF2E7D32)
                                : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Detailed Analysis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ...counts.entries.map((entry) {
                        final disease = entry.key;
                        final count = entry.value;

                        if (count == 0) return const SizedBox.shrink();

                        IconData icon;
                        Color iconColor;
                        Color bgColor;

                        if (disease.toLowerCase().contains('healthy')) {
                          icon = Icons.check_circle;
                          iconColor = Colors.green;
                          bgColor = Colors.green[50]!;
                        } else if (disease.toLowerCase().contains(
                          'uncertain',
                        )) {
                          icon = Icons.help_outline;
                          iconColor = Colors.orange;
                          bgColor = Colors.orange[50]!;
                        } else {
                          icon = Icons.warning;
                          iconColor = Colors.red;
                          bgColor = Colors.red[50]!;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: iconColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: iconColor, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      disease,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$count ${count == 1 ? 'leaf' : 'leaves'} detected',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // Action Buttons
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SpreadForecastingScreen(
                                      analysisResult: widget.analysisResult,
                                    ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.timeline, size: 20),
                          label: const Text(
                            'Spread Forecast',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate back to home with fresh image upload screen
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const ImageUploadScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Analyze Another Image'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
