import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../config/theme.dart';
import '../../../../providers/language_provider.dart';
import '../agronomy/models/district_model.dart';
import '../services/plantation_api_client.dart';
import '../services/price_analytics_service.dart';

enum ChartType { bar, line }

class PriceAnalyticsPage extends StatefulWidget {
  const PriceAnalyticsPage({super.key});

  @override
  State<PriceAnalyticsPage> createState() => _PriceAnalyticsPageState();
}

class _PriceAnalyticsPageState extends State<PriceAnalyticsPage> {
  final PriceAnalyticsService _service =
      PriceAnalyticsService(PlantationApiClient());

  List<District> _districts = [];
  String? _selectedDistrictId;
  String? _selectedDistrictName;
  ChartType _selectedChartType = ChartType.bar;

  bool _isLoadingDistricts = true;
  bool _isLoadingAnalytics = false;

  Map<String, List<PricePoint>> _gradeData = {
    'GR-1': [],
    'GR-2': [],
    'WHITE': [],
  };

  List<String> _dates = [];
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    setState(() => _isLoadingDistricts = true);
    final districts = await _service.fetchDistricts();
    if (mounted) {
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _loadAnalytics(String districtName) async {
    setState(() {
      _isLoadingAnalytics = true;
      _selectedDistrictName = districtName;
    });

    final analytics = await _service.fetchPriceAnalytics(districtName);

    if (mounted) {
      if (analytics.isEmpty) {
        setState(() {
          _gradeData = {'GR-1': [], 'GR-2': [], 'WHITE': []};
          _dates = [];
          _hasData = false;
          _isLoadingAnalytics = false;
        });
        return;
      }

      // Extract unique dates and sort them
      final allDatesSet =
          analytics.map((e) => e['date'] as String).toSet().toList();
      allDatesSet.sort();
      final dateLabels = allDatesSet;

      final Map<String, List<PricePoint>> newGradeData = {
        'GR-1': [],
        'GR-2': [],
        'WHITE': [],
      };

      for (var entry in analytics) {
        final grade = entry['grade'] as String;
        final date = entry['date'] as String;
        final price = (entry['average_price'] as num).toDouble();

        if (newGradeData.containsKey(grade)) {
          final dateIndex = dateLabels.indexOf(date);
          if (dateIndex != -1) {
            newGradeData[grade]!
                .add(PricePoint(dateIndex.toDouble(), price, date));
          }
        }
      }

      // Sort points by x-axis (date index)
      newGradeData.forEach((key, value) {
        value.sort((a, b) => a.x.compareTo(b.x));
      });

      setState(() {
        _dates = dateLabels;
        _gradeData = newGradeData;
        _hasData = analytics.isNotEmpty;
        _isLoadingAnalytics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String lang =
        Provider.of<LanguageProvider>(context).locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('price_analytics_title')),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
      ),
      body: _isLoadingDistricts
          ? const LoadingSpinner()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDistrictSelector(lang),
                  const SizedBox(height: 16),
                  _buildChartTypeToggle(),
                  const SizedBox(height: 24),
                  if (_isLoadingAnalytics)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: LoadingSpinner(),
                    ))
                  else if (!_hasData && _selectedDistrictName != null)
                    Center(
                      child: EmptyState(
                        message: context.tr('price_analytics_no_data'),
                        icon: Icons.analytics_outlined,
                      ),
                    )
                  else if (_hasData)
                    Column(
                      children: [
                        _buildGradeChart(context.tr('price_analytics_gr1'),
                            _gradeData['GR-1']!, Colors.amber),
                        const SizedBox(height: 24),
                        _buildGradeChart(context.tr('price_analytics_gr2'),
                            _gradeData['GR-2']!, Colors.teal),
                        const SizedBox(height: 24),
                        _buildGradeChart(context.tr('price_analytics_white'),
                            _gradeData['WHITE']!, Colors.blueGrey),
                        const SizedBox(height: 40),
                      ],
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Text(
                          context.tr('agronomy_select_district_to_search'),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDistrictSelector(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDistrictId,
          isExpanded: true,
          hint: Text(
            context.tr('agronomy_select_district'),
            style: const TextStyle(color: Colors.white70),
          ),
          dropdownColor: AppTheme.deepEmerald,
          items: _districts.map((district) {
            return DropdownMenuItem<String>(
              value: district.id,
              child: Text(
                district.name.get(lang),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              final district = _districts.firstWhere((d) => d.id == value);
              setState(() {
                _selectedDistrictId = value;
              });
              _loadAnalytics(district.name.en);
            }
          },
        ),
      ),
    );
  }

  Widget _buildChartTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.tr('price_analytics_chart_type'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleItem(
                  context.tr('price_analytics_bar'),
                  ChartType.bar,
                  Icons.bar_chart,
                ),
              ),
              Expanded(
                child: _buildToggleItem(
                  context.tr('price_analytics_line'),
                  ChartType.line,
                  Icons.show_chart,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem(String label, ChartType type, IconData icon) {
    bool isSelected = _selectedChartType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pepperGold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeChart(String title, List<PricePoint> points, Color color) {
    if (points.isEmpty) {
      return Card(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white)),
              const Spacer(),
              const Center(
                  child: Text("No data for this grade",
                      style: TextStyle(color: Colors.white54))),
              const Spacer(),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: _selectedChartType == ChartType.bar
                  ? _buildBarChart(points, color)
                  : _buildLineChart(points, color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<PricePoint> points, Color color) {
    final spots = points.map((p) => FlSpot(p.x, p.y)).toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF37474F),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)}\nLKR',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<PricePoint> points, Color color) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: const Color(0xFF37474F),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(2)}\nLKR',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        barGroups: points.map((p) {
          return BarChartGroupData(
            x: p.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: p.y,
                color: color,
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: points.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                      1.1,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            if (value % 200 != 0) return const SizedBox.shrink();
            return Text(
              '${(value / 1000).toStringAsFixed(1)}K',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < _dates.length) {
              final date = _dates[index];
              final parts = date.split('-');
              if (parts.length == 3) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("${parts[1]}/${parts[2]}",
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10)),
                );
              }
            }
            return const Text('');
          },
          reservedSize: 28,
        ),
      ),
    );
  }
}

class PricePoint {
  final double x;
  final double y;
  final String date;

  PricePoint(this.x, this.y, this.date);
}
