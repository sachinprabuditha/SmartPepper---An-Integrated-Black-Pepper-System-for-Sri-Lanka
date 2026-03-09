import 'package:flutter/material.dart';
import 'package:smartpepper_mobile/config/theme.dart';
import '../../localization/app_localizations.dart';

class RemedySuggestionsScreen extends StatefulWidget {
  final String diseaseName;
  final double severity;
  final int stage;
  final Map<String, dynamic> remedies;

  const RemedySuggestionsScreen({
    super.key,
    required this.diseaseName,
    required this.severity,
    required this.stage,
    required this.remedies,
  });

  @override
  State<RemedySuggestionsScreen> createState() =>
      _RemedySuggestionsScreenState();
}

class _RemedySuggestionsScreenState extends State<RemedySuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int stage = widget.stage;

    // Convert dynamic lists to typed String lists safely
    final ecoList = (widget.remedies['ecoFriendly'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final chemList = (widget.remedies['chemical'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        title: Text(
            '${widget.diseaseName} ${context.tr('disease_remedies_title')}'),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pepperGold,
          indicatorWeight: 3,
          labelColor: AppTheme.pepperGold,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(
                icon: const Icon(Icons.eco),
                text: context.tr('disease_eco_friendly_solutions')),
            Tab(
                icon: const Icon(Icons.science),
                text: context.tr('disease_chemical_solutions')),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.pepperGold.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFFFA726),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('disease_severity_stage')} $stage (${widget.severity.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFA726),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStageDescription(stage),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Eco Friendly Tab
                _buildRemedyList(ecoList, const Color(0xFF66BB6A)),
                // Chemical Solutions Tab
                _buildRemedyList(chemList, const Color(0xFFFFA726)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStageDescription(int stage) {
    switch (stage) {
      case 1:
        return context.tr('disease_stage_1_desc');
      case 2:
        return context.tr('disease_stage_2_desc');
      case 3:
        return context.tr('disease_stage_3_desc');
      case 4:
        return context.tr('disease_stage_4_desc');
      case 5:
        return context.tr('disease_stage_5_desc');
      default:
        return '';
    }
  }

  Widget _buildRemedyList(List<String> items, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          context.tr('disease_no_remedies'),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFFE8F5E9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.4), width: 2),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
