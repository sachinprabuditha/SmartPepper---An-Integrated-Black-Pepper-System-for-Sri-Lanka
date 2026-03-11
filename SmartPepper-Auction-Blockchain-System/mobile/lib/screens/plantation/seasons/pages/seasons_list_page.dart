import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/season_controller.dart';
import '../services/season_service.dart';
import '../models/season_model.dart';
import '../pages/create_season_page.dart';
import '../pages/season_details_page.dart';
import '../../plantation/services/plantation_service.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../services/plantation_api_client.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../localization/app_localizations.dart';
import '../widgets/season_card.dart';

class SeasonsListPage extends StatefulWidget {
  const SeasonsListPage({super.key});

  @override
  State<SeasonsListPage> createState() => _SeasonsListPageState();
}

class _SeasonsListPageState extends State<SeasonsListPage> {
  String? _userId;
  String? _selectedFarmId;
  late Future<List<FarmRecord>> _farmsFuture;
  late PlantationService _plantationService;
  late SeasonController _seasonController;

  @override
  void initState() {
    super.initState();
    final apiClient = PlantationApiClient();
    _plantationService = PlantationService(apiClient);
    _seasonController = SeasonController(SeasonService(apiClient));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId != null && userId.isNotEmpty && userId != _userId) {
      if (mounted) {
        setState(() {
          _userId = userId;
          _farmsFuture = _plantationService.getFarms();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _seasonController.fetchSeasons(userId);
        });
      }
    }
  }

  Future<void> _refreshSeasons() async {
    if (_userId != null) {
      await _seasonController.fetchSeasons(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return LoadingSpinner(
        message: context.tr('plantation_loading_user'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_harvest_seasons')),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSeasons,
        child: ChangeNotifierProvider.value(
          value: _seasonController,
          child: Consumer<SeasonController>(
            builder: (context, seasonController, child) {
              if (seasonController.isLoading &&
                  seasonController.seasons.isEmpty) {
                return LoadingSpinner(
                  message: context.tr('plantation_loading_seasons'),
                );
              }

              if (seasonController.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '${context.tr('common_error')}: ${seasonController.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshSeasons,
                          child: Text(context.tr('common_retry')),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final seasons = seasonController.seasons;
              final sortedSeasons = List<SeasonModel>.from(seasons)
                ..sort((a, b) {
                  if (a.startYear != b.startYear)
                    return b.startYear.compareTo(a.startYear);
                  return b.startMonth.compareTo(a.startMonth);
                });

              final filteredSeasons = _selectedFarmId == null
                  ? sortedSeasons
                  : sortedSeasons
                      .where((s) => s.farmId == _selectedFarmId)
                      .toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: Theme.of(context).colorScheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.agriculture,
                                  color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('plantation_total_seasons'),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Spacer(),
                              Text(
                                '${filteredSeasons.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<FarmRecord>>(
                            future: _farmsFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty)
                                return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: DropdownButton<String?>(
                                  value: _selectedFarmId,
                                  isExpanded: true,
                                  underline: const SizedBox.shrink(),
                                  style: const TextStyle(color: Colors.black),
                                  dropdownColor: Colors.white,
                                  hint: Text(
                                      context.tr('plantation_filter_by_farm'),
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                  items: [
                                    DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                            context.tr('plantation_all_farms'),
                                            style: const TextStyle(
                                                color: Colors.black))),
                                    ...snapshot.data!
                                        .map(
                                          (f) => DropdownMenuItem(
                                              value: f.id,
                                              child: Text(f.farmName,
                                                  style: const TextStyle(
                                                      color: Colors.black))),
                                        )
                                        .toList(),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedFarmId = v),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filteredSeasons.isEmpty)
                    SliverFillRemaining(
                      child: EmptyState(
                        message: context.tr('plantation_no_seasons_yet'),
                        icon: Icons.calendar_today_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final season = filteredSeasons[index];
                            return SeasonCard(
                              season: season,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SeasonDetailsPage(
                                          seasonId: season.id)),
                                );
                                if (result == true) _refreshSeasons();
                              },
                            );
                          },
                          childCount: filteredSeasons.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CreateSeasonPage(userId: _userId!)),
          );
          if (result == true) _refreshSeasons();
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr('plantation_create_season')),
      ),
    );
  }
}
