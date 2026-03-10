import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';

class QualityGradingScreen extends StatefulWidget {
  const QualityGradingScreen({super.key});

  @override
  State<QualityGradingScreen> createState() => _QualityGradingScreenState();
}

class _QualityGradingScreenState extends State<QualityGradingScreen> {
  final _random = Random();
  bool _isAnalyzing = false;
  bool _isSaving = false;

  // Simulation Metrics
  double? _density;
  double? _weight;
  Map<String, double>? _visuals;
  String? _finalGrade;

  void _runSimulation() async {
    setState(() {
      _isAnalyzing = true;
      _density = null;
      _visuals = null;
      _finalGrade = null;
    });

    // Simulate machine action delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 1. Simulate Samples
    final weight = 400 + _random.nextInt(250).toDouble(); // 400 - 650g
    final density = weight; // g/L typically

    // 2. Simulate Classification Distribution
    double pureProb = 60 + _random.nextInt(35).toDouble(); // 60 - 95%
    double leftOver = 100 - pureProb;
    double moldProb = _random.nextDouble() * leftOver;
    double discProb = leftOver - moldProb;

    // 3. Logic: Final Grading Decision
    String grade = 'Grade D (Low Density / Waste)';
    if (density >= 570 && pureProb >= 90) {
      grade = 'Grade A (Premium High Density)';
    } else if (density >= 550 && pureProb >= 80) {
      grade = 'Grade B (Standard High Quality)';
    } else if (density >= 500 && pureProb >= 70) {
      grade = 'Grade C (Lightweight / Industrial)';
    }

    setState(() {
      _weight = weight;
      _density = density;
      _visuals = {
        'pure': double.parse(pureProb.toStringAsFixed(1)),
        'molded': double.parse(moldProb.toStringAsFixed(1)),
        'discolored': double.parse(discProb.toStringAsFixed(1)),
      };
      _finalGrade = grade;
      _isAnalyzing = false;
    });
  }

  Future<void> _saveResult() async {
    if (_density == null || _visuals == null || _finalGrade == null) return;

    setState(() => _isSaving = true);

    try {
      final apiService = context.read<ApiService>();
      await apiService.saveQualityGrading({
        'weightGrams': _weight,
        'density': _density,
        'visualPercentages': _visuals,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('common_success')),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/farmer/quality-grading/history');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('common_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getBadgeColor(String? grade) {
    if (grade == null) return Colors.grey;
    if (grade.contains('Grade A')) return Colors.green;
    if (grade.contains('Grade B')) return Colors.blue;
    if (grade.contains('Grade C')) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          context.tr('grading_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.pepperGold),
            onPressed: () => context.push('/farmer/quality-grading/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Machine Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.forestGreen, Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.memory, size: 60, color: AppTheme.pepperGold),
                  const SizedBox(height: 16),
                  Text(
                    _isAnalyzing
                        ? context.tr('common_loading')
                        : context.tr('grading_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'IOT Sensor Connected', // English placeholder
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metrics Display Area
            if (_density != null && _visuals != null) ...[
              // Grade Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _getBadgeColor(_finalGrade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBadgeColor(_finalGrade)),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('grading_final_grade'),
                      style: TextStyle(
                        color: _getBadgeColor(_finalGrade),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _finalGrade!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getBadgeColor(_finalGrade),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Detailed Metrics
              Row(
                children: [
                   Expanded(
                    child: _buildMetricCard(
                      context.tr('lot_weight'),
                      '${_weight!.toStringAsFixed(1)}g',
                      Icons.scale,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context.tr('grading_sample_density'),
                      '${_density!.toStringAsFixed(1)} g/L',
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Analysis Proportions
              Text(
                context.tr('grading_visual_analysis'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVisualStatCircle(
                        context.tr('grading_pure'), '${_visuals!['pure']}%', AppTheme.pepperGold),
                    _buildVisualStatCircle(
                        context.tr('grading_molded'), '${_visuals!['molded']}%', Colors.red[400]!),
                    _buildVisualStatCircle(context.tr('grading_discolored'),
                        '${_visuals!['discolored']}%', Colors.orange[400]!),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Actions
            ElevatedButton(
              onPressed: _isAnalyzing || _isSaving ? null : _runSimulation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      context.tr('grading_simulate'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            
            if (_density != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isSaving ? null : _saveResult,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.forestGreen, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.forestGreen,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.tr('grading_save'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.forestGreen),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualStatCircle(String label, String value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: double.parse(value.replaceAll('%', '')) / 100,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                strokeWidth: 6,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
