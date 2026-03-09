import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartpepper_mobile/models/disease_location.dart';
import 'package:smartpepper_mobile/config/theme.dart';
import '../../localization/app_localizations.dart';
import '../../services/disease_api_service.dart';
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
  final DiseaseApiService _apiService = DiseaseApiService();

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
    String primaryDisease = 'Healthy';
    int healthyCount = 0;

    for (var entry in counts.entries) {
      if (entry.key.toLowerCase() == 'healthy leaves' ||
          entry.key.toLowerCase() == 'healthy') {
        healthyCount += (entry.value as int);
      } else if (entry.value > 0) {
        hasDisease = true;
        if (primaryDisease == 'Healthy' ||
            entry.value > (counts[primaryDisease] ?? 0)) {
          primaryDisease = entry.key;
        }
      }
    }

    // Save location for both healthy and diseased plants (if GPS available)
    if (widget.currentPosition != null) {
      if (hasDisease) {
        // Save diseased plant location
        await _saveDiseaseLocation(primaryDisease, severity, isHealthy: false);
      } else if (healthyCount > 0) {
        // Save healthy plant location
        await _saveDiseaseLocation('Healthy', 0.0, isHealthy: true);
      }
    } else if (widget.currentPosition == null &&
        (hasDisease || healthyCount > 0)) {
      // Detection successful but no GPS location (image from gallery)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.tr('disease_location_not_saved_gallery')),
                ),
              ],
            ),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveDiseaseLocation(String diseaseName, double severity,
      {bool isHealthy = false}) async {
    if (_isSavingLocation || widget.currentPosition == null) return;

    setState(() {
      _isSavingLocation = true;
    });

    try {
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
        isHealthy: isHealthy,
      );

      await _apiService.saveDiseaseLocation(newLocation);

      if (mounted) {
        final message = isHealthy
            ? context.tr('disease_healthy_location_saved')
            : '${context.tr('disease_location_saved')}: $diseaseName';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message),
                ),
              ],
            ),
            backgroundColor: AppTheme.sriLankanLeaf,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: context.tr('disease_view_map'),
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
            content: Text('${context.tr('disease_error_saving_location')}: $e'),
            backgroundColor: AppTheme.errorColor,
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
      return const Color(0xFF66BB6A); // Light green
    } else if (severity < 40) {
      return const Color(0xFFFFA726); // Light orange
    } else {
      return const Color(0xFFEF5350); // Light red
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
    if (health >= 80) return const Color(0xFF66BB6A); // Light green
    if (health >= 50) return const Color(0xFFFFA726); // Light orange
    return const Color(0xFFEF5350); // Light red
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE8F5E9), // Light green
              const Color(0xFFF1F8E9), // Very light green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: cardColor.withOpacity(0.4),
            width: 2,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
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
              radius: 75.0,
              lineWidth: 14.0,
              percent: score / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cardColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              progressColor: cardColor,
              backgroundColor: cardColor.withOpacity(0.2),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cardColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, color: cardColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${context.tr('disease_total_detected')} $totalLeaves',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cardColor,
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
        title: context.tr('disease_whole_tree_severity'),
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
            title: '$disease ${context.tr('disease_severity')}',
            score: diseaseSeverity.toDouble(),
            isHealthScore: false,
            totalLeaves: totalLeaves,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        title: Text(context.tr('disease_analysis_results')),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
        centerTitle: true,
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
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.forestGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('disease_location_captured_label'),
                                style: const TextStyle(
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
                        color: _currentCarouselIndex == index
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
                            color: AppTheme.pepperGold,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('disease_detailed_analysis'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.pepperGold,
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
                                      '$count ${count == 1 ? context.tr('disease_leaf_detected') : context.tr('disease_leaves_detected')}',
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
                                builder: (context) => SpreadForecastingScreen(
                                  analysisResult: widget.analysisResult,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.timeline, size: 20),
                          label: Text(
                            context.tr('disease_forecast_spread'),
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
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
                          label: Text(context.tr('disease_analyze_another')),
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
