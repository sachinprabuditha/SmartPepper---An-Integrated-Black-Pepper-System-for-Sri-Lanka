import 'package:flutter/material.dart';
import 'package:smartpepper_mobile/config/theme.dart';
import '../../localization/app_localizations.dart';
import 'remedy_suggestions_screen.dart';

class SpreadForecastingScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;

  const SpreadForecastingScreen({super.key, required this.analysisResult});

  @override
  State<SpreadForecastingScreen> createState() =>
      _SpreadForecastingScreenState();
}

class _SpreadForecastingScreenState extends State<SpreadForecastingScreen> {
  @override
  Widget build(BuildContext context) {
    final forecastReport =
        widget.analysisResult['forecast_report'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        title: Text(context.tr('disease_spread_forecasting')),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
      ),
      body: forecastReport.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: AppTheme.pepperGold,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('disease_no_spread_detected'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('disease_plants_healthy'),
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: forecastReport.length,
              itemBuilder: (context, index) {
                final report = forecastReport[index] as Map<String, dynamic>;
                final diseaseName = report['disease'] as String;
                final severity = (report['severity'] as num).toDouble();
                final days = (report['days_to_full_spread'] as num).toDouble();

                Color riskColor;
                if (days <= 14) {
                  riskColor = const Color(0xFFEF5350); // Light red
                } else if (days <= 30) {
                  riskColor = const Color(0xFFFFA726); // Light orange
                } else {
                  riskColor = const Color(0xFF66BB6A); // Light green
                }

                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color(0xFFE8F5E9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: riskColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                diseaseName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('disease_current_severity'),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                            Text(
                              '${severity.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: riskColor.withOpacity(0.4), width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('disease_est_days_spread'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                '${days.toStringAsFixed(1)} ${context.tr('disease_days')}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: riskColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RemedySuggestionsScreen(
                                    diseaseName: diseaseName,
                                    severity: severity,
                                    stage: report['stage'] as int? ?? 1,
                                    remedies: report['remedies']
                                            as Map<String, dynamic>? ??
                                        {
                                          'chemical': <String>[],
                                          'ecoFriendly': <String>[]
                                        },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.medical_services, size: 20),
                            label: Text(context.tr('disease_view_remedies')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
