import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season_model.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../plantation/services/plantation_service.dart';
import '../../services/plantation_api_client.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class SeasonCard extends StatefulWidget {
  final SeasonModel season;
  final VoidCallback onTap;

  const SeasonCard({
    super.key,
    required this.season,
    required this.onTap,
  });

  @override
  State<SeasonCard> createState() => _SeasonCardState();
}

class _SeasonCardState extends State<SeasonCard> {
  late Future<FarmRecord> _farmFuture;
  late PlantationService _plantationService;

  @override
  void initState() {
    super.initState();
    _plantationService = PlantationService(PlantationApiClient());
    _farmFuture = _plantationService.getFarmById(widget.season.farmId);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    final harvestSeasonLabel = context.tr('plantation_harvest_season');
    final endedLabel = context.tr('plantation_ended');
    final activeLabel = context.tr('plantation_active');
    final farmLabel = context.tr('plantation_farm');
    final districtLabel = context.tr('plantation_district');
    final periodLabel = context.tr('plantation_period');
    final loadingFarmLabel = context.tr('plantation_loading_farm');
    final loadingLabel = context.tr('common_loading');
    final naLabel = context.tr('plantation_na');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.green[50]!.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with season name and icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            harvestSeasonLabel,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.season.seasonName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.season.status == 'season-end'
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.season.status == 'season-end'
                              ? Colors.red[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Text(
                        widget.season.status == 'season-end'
                            ? endedLabel
                            : activeLabel,
                        style: TextStyle(
                          color: widget.season.status == 'season-end'
                              ? Colors.red[700]
                              : Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Farm Information with better styling
                FutureBuilder<FarmRecord>(
                  future: _farmFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              loadingFarmLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final farm = snapshot.data!;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.agriculture,
                              size: 18,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farmLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  farm.farmName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Location and Period in a grid layout
                FutureBuilder<FarmRecord>(
                  future: _farmFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.location_on,
                              districtLabel,
                              loadingLabel,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.access_time,
                              periodLabel,
                              widget.season.period,
                              Colors.orange,
                            ),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.location_on,
                              districtLabel,
                              naLabel,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.access_time,
                              periodLabel,
                              widget.season.period,
                              Colors.orange,
                            ),
                          ),
                        ],
                      );
                    }

                    final farm = snapshot.data!;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            Icons.location_on,
                            districtLabel,
                            farm.district.get(lang),
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            Icons.access_time,
                            periodLabel,
                            widget.season.period,
                            Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label,
      String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 13,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
