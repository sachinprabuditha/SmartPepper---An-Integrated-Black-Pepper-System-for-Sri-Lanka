import 'package:flutter/material.dart';

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
            .toList() ?? [];
            
    final chemList = (widget.remedies['chemical'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.diseaseName} Remedies'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.eco), text: 'Eco Friendly Solutions'),
            Tab(icon: Icon(Icons.science), text: 'Chemical Solutions'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[800],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity Stage $stage (${widget.severity.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStageDescription(stage),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
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
                _buildRemedyList(ecoList, Colors.green),
                // Chemical Solutions Tab
                _buildRemedyList(chemList, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStageDescription(int stage) {
    switch(stage) {
      case 1: return 'Initial infection. Focus on prevention and light suppression.';
      case 2: return 'Moderate spread. Requires immediate targeted intervention.';
      case 3: return 'Significant infection. Aggressive treatment needed to save the crop.';
      case 4: return 'Severe infection. High risk of crop loss; robust salvaging required.';
      case 5: return 'Critical condition. Vine may not recover; focus on containment and clearing.';
      default: return '';
    }
  }

  Widget _buildRemedyList(List<String> items, Color color) {
    if (items.isEmpty) {
      return const Center(child: Text("No remedies found for this stage."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[index],
                    style: const TextStyle(fontSize: 16, height: 1.4),
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

