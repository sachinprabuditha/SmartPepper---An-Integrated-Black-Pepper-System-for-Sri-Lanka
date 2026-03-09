import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as vanilla_provider;

import '../seasons/controllers/season_controller.dart';
import '../seasons/models/season_model.dart';
import '../sessions/controllers/session_controller.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../config/theme.dart';

class YieldAnalyticsPage extends ConsumerStatefulWidget {
  const YieldAnalyticsPage({super.key});

  @override
  ConsumerState<YieldAnalyticsPage> createState() => _YieldAnalyticsPageState();
}

class _YieldAnalyticsPageState extends ConsumerState<YieldAnalyticsPage> {
  String? _selectedSeasonId;
  String? _userId;
  bool _initialized = false; // becomes true after first auto-fetch triggers

  // Aggregated data
  Map<String, double> _seasonYields = {};
  double _totalLifetimeYield = 0;
  int _totalSessionsCount = 0;
  bool _loadingAggregated = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth =
        vanilla_provider.Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;

    // AuthProvider may become ready AFTER this screen is first built.
    // Trigger initial fetch as soon as we have a valid userId.
    if (userId != null &&
        userId.isNotEmpty &&
        (userId != _userId || !_initialized)) {
      setState(() {
        _userId = userId;
        _initialized = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshData(userId);
      });
    }
  }

  Future<void> _refreshData(String userId) async {
    await ref.read(seasonControllerProvider.notifier).fetchSeasons(userId);
    final seasons = ref.read(seasonControllerProvider).value ?? [];
    if (seasons.isNotEmpty) {
      await _loadAggregatedData(seasons);
    }
  }

  Future<void> _loadAggregatedData(List<SeasonModel> seasons) async {
    if (_loadingAggregated) return;
    setState(() => _loadingAggregated = true);

    try {
      // Refresh all session providers to get the latest data from backend
      final results = await Future.wait(
          seasons.map((s) => ref.refresh(sessionsProvider(s.id).future)));

      double totalYield = 0;
      int totalSessions = 0;
      Map<String, double> seasonYields = {};

      for (int i = 0; i < seasons.length; i++) {
        final sessions = results[i];
        double sYield = sessions.fold(0.0, (sum, s) => sum + s.yieldKg);
        seasonYields[seasons[i].id] = sYield;
        totalYield += sYield;
        totalSessions += sessions.length;
      }

      if (mounted) {
        setState(() {
          _seasonYields = seasonYields;
          _totalLifetimeYield = totalYield;
          _totalSessionsCount = totalSessions;
          _loadingAggregated = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAggregated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider =
        vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    if (_userId == null) {
      return Scaffold(
        body: LoadingSpinner(
          message: context.tr('yield_analytics_initializing'),
        ),
      );
    }

    final seasonsAsync = ref.watch(seasonControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('yield_analytics_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(_userId!),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(_userId!),
        child: seasonsAsync.when(
          data: (seasons) {
            if (seasons.isEmpty) {
              return Center(
                child: EmptyState(
                  message: context.tr('yield_analytics_no_data'),
                  icon: Icons.analytics_outlined,
                ),
              );
            }

            // Sort seasons for trend chart
            final sortedSeasons = [...seasons]..sort((a, b) {
                if (a.startYear != b.startYear)
                  return a.startYear.compareTo(b.startYear);
                return a.startMonth.compareTo(b.startMonth);
              });

            SeasonModel? bestSeason;
            SeasonModel? worstSeason;
            double bestYield = -1;
            double worstYield = double.maxFinite;

            for (final season in seasons) {
              final yieldVal = _seasonYields[season.id] ?? 0;
              if (yieldVal > bestYield) {
                bestYield = yieldVal;
                bestSeason = season;
              }
              if (yieldVal < worstYield) {
                worstYield = yieldVal;
                worstSeason = season;
              }
            }

            // Set default selected season if not set
            if (_selectedSeasonId == null && seasons.isNotEmpty) {
              _selectedSeasonId = sortedSeasons.last.id;
            }

            final averageYieldPerSeason =
                seasons.isEmpty ? 0.0 : _totalLifetimeYield / seasons.length;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingAggregated)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                  _buildSummaryGrid(
                    context,
                    lang,
                    seasons.length,
                    _totalLifetimeYield,
                    averageYieldPerSeason,
                    bestSeason,
                    _totalSessionsCount.toString(),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    context.tr('yield_analytics_season_trend'),
                    Icons.show_chart,
                  ),
                  const SizedBox(height: 16),
                  _buildLineChart(context, sortedSeasons),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    context.tr('yield_analytics_season_comparison'),
                    Icons.bar_chart,
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(context, sortedSeasons),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    _selectedSeasonId != null
                        ? '${context.tr('yield_analytics_harvest_distribution')}: ${seasons.firstWhere((s) => s.id == _selectedSeasonId).seasonName}'
                        : context.tr('yield_analytics_harvest_distribution'),
                    Icons.pie_chart_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildSeasonSelector(seasons),
                  const SizedBox(height: 16),
                  if (_selectedSeasonId != null)
                    _buildDistributionChart(context, _selectedSeasonId!),
                  const SizedBox(height: 24),
                  _buildBestWorstCard(context, lang, bestSeason, worstSeason),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => LoadingSpinner(
            message: context.tr('yield_analytics_calculating'),
          ),
          error: (error, stack) => Center(
            child: Text(
              '${context.tr('common_error')}: ${error.toString()}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.pepperGold, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    String lang,
    int totalSeasons,
    double totalYield,
    double avgYield,
    SeasonModel? best,
    String sessionCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildSummaryCard(
              context,
              context.tr('yield_analytics_total_seasons'),
              totalSeasons.toString(),
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildSummaryCard(
              context,
              context.tr('yield_analytics_total_sessions'),
              sessionCount,
              Icons.history,
              Colors.teal,
            ),
            _buildSummaryCard(
              context,
              context.tr('yield_analytics_lifetime_yield'),
              '${totalYield.toStringAsFixed(1)} kg',
              Icons.balance,
              Colors.orange,
            ),
            _buildSummaryCard(
              context,
              context.tr('yield_analytics_avg_per_season'),
              '${avgYield.toStringAsFixed(1)} kg',
              Icons.functions,
              Colors.purple,
            ),
            _buildSummaryCard(
              context,
              context.tr('yield_analytics_best_season'),
              best?.seasonName ?? context.tr('plantation_na'),
              Icons.emoji_events,
              Colors.amber,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
      BuildContext context, List<SeasonModel> sortedSeasons) {
    if (sortedSeasons.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          minX: -0.5,
          maxX: sortedSeasons.length == 1 ? 0.5 : sortedSeasons.length - 0.5,
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedSeasons.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        sortedSeasons[index].seasonName.split(' ').first,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: sortedSeasons.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), _seasonYields[e.value.id] ?? 0);
              }).toList(),
              isCurved: true,
              color: AppTheme.pepperGold,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.pepperGold.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<SeasonModel> seasons) {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: seasons.isEmpty
              ? 100
              : (seasons
                          .map((e) => _seasonYields[e.id] ?? 0)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2)
                  .clamp(100, double.infinity),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < seasons.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        seasons[index].seasonName.substring(0, 3),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 28,
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: seasons.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: _seasonYields[e.value.id] ?? 0,
                  color: AppTheme.pepperGold,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeasonSelector(List<SeasonModel> seasons) {
    final languageProvider =
        vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSeasonId,
          isExpanded: true,
          hint: Text(context.tr('yield_analytics_select_season')),
          items: seasons.map((s) {
            return DropdownMenuItem(
              value: s.id,
              child: Text(s.seasonName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSeasonId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDistributionChart(BuildContext context, String seasonId) {
    final sessionsAsync = ref.watch(sessionControllerProvider(seasonId));

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(context.tr('yield_analytics_no_sessions_season')),
              ),
            ),
          );
        }

        // Sort sessions by date (oldest first)
        final sortedSessions = [...sessions]
          ..sort((a, b) => a.date.compareTo(b.date));

        return Column(
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: sessions
                          .map((e) => e.yieldKg)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedSessions.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd')
                                    .format(sortedSessions[index].date),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedSessions.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.yieldKg,
                          color: Colors.blueAccent,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => LoadingSpinner(
        message: context.tr('plantation_loading_sessions'),
      ),
      error: (e, _) => Text('${context.tr('common_error')}: $e'),
    );
  }

  Widget _buildBestWorstCard(
    BuildContext context,
    String lang,
    SeasonModel? best,
    SeasonModel? worst,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildHighlightRow(
              context,
              '🏆 ${context.tr('yield_analytics_best_season')}',
              best?.seasonName ?? context.tr('plantation_na'),
              '${_seasonYields[best?.id ?? '']?.toStringAsFixed(1) ?? '0.0'} kg',
              Colors.amber[800]!,
            ),
            const Divider(height: 32),
            _buildHighlightRow(
              context,
              '⚠️ ${context.tr('yield_analytics_lowest_season')}',
              worst?.seasonName ?? context.tr('plantation_na'),
              '${_seasonYields[worst?.id ?? '']?.toStringAsFixed(1) ?? '0.0'} kg',
              Colors.red[800]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightRow(BuildContext context, String title, String name,
      String yield, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Flexible(
          child: Text(
            yield,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),
      ],
    );
  }
}
