import 'package:flutter/material.dart';
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
    final forecastReport = widget.analysisResult['forecast_report'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Spread Forecasting'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: forecastReport.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Disease Spread Detected',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your plants are healthy or no verifiable disease instances were found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                  riskColor = Colors.red;
                } else if (days <= 30) {
                  riskColor = Colors.orange;
                } else {
                  riskColor = Colors.yellow[800]!;
                }

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: riskColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                diseaseName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Severity:',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            Text(
                              '${severity.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: riskColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Est. Days to Full Spread:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${days.toStringAsFixed(1)} Days',
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
                                    remedies: report['remedies'] as Map<String, dynamic>? ?? {'chemical': <String>[], 'ecoFriendly': <String>[]},
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.medical_services, size: 20),
                            label: const Text('View Remedies'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
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
