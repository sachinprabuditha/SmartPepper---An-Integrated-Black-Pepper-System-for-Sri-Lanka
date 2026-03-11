import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/season_controller.dart';
import '../models/season_model.dart';
import '../../sessions/pages/create_session_page.dart';
import '../../sessions/widgets/session_card.dart';
import '../../sessions/controllers/session_controller.dart';
import '../../sessions/services/session_service.dart';
import '../../sessions/pages/edit_session_page.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../plantation/services/plantation_service.dart';
import '../../services/plantation_api_client.dart';
import '../pages/edit_season_page.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';
import '../services/season_service.dart';

class SeasonDetailsPage extends StatefulWidget {
  final String seasonId;

  const SeasonDetailsPage({super.key, required this.seasonId});

  @override
  State<SeasonDetailsPage> createState() => _SeasonDetailsPageState();
}

class _SeasonDetailsPageState extends State<SeasonDetailsPage> {
  late Future<SeasonModel> _seasonFuture;
  late Future<FarmRecord?> _farmFuture;
  late SeasonService _seasonService;
  late PlantationService _plantationService;
  late SeasonController _seasonController;
  late SessionController _sessionController;
  bool _isUpdated = false;
  SeasonModel? _lastSeason;
  FarmRecord? _lastFarm;

  @override
  void initState() {
    super.initState();
    final apiClient = PlantationApiClient();
    _seasonService = SeasonService(apiClient);
    _plantationService = PlantationService(apiClient);
    _seasonController = SeasonController(_seasonService);
    _sessionController = SessionController(SessionService(apiClient));
    _loadData();
    // Fetch sessions initially
    _sessionController.fetchSessions(widget.seasonId);
  }

  void _loadData() {
    _seasonFuture = _seasonService.getSeasonById(widget.seasonId);
    _farmFuture = _seasonFuture.then((season) {
      if (mounted) {
        setState(() {
          _lastSeason = season;
        });
      }
      return _plantationService.getFarms().then((farms) {
        try {
          final farm = farms.firstWhere((farm) => farm.id == season.farmId);
          if (mounted) {
            setState(() {
              _lastFarm = farm;
            });
          }
          return farm;
        } catch (e) {
          return null;
        }
      });
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _isUpdated = true;
      _loadData();
      _sessionController.fetchSessions(widget.seasonId);
    });
  }

  Future<void> _deleteSeason(String userId) async {
// ... (code omitted for brevity in instruction, will be handled by replace_file_content)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('plantation_delete_season')),
        content: Text(dialogContext.tr('plantation_confirm_delete_season')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(dialogContext.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dialogContext.tr('common_delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _seasonController.deleteSeason(widget.seasonId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_season_deleted')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _endSeason() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('plantation_end_season_button')),
        content: Text(dialogContext.tr('plantation_confirm_end_season')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(dialogContext.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(dialogContext.tr('plantation_end_season_button')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _seasonController.endSeason(widget.seasonId);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_season_ended')),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr('common_error')}: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _isUpdated);
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _seasonController),
          ChangeNotifierProvider.value(value: _sessionController),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.tr('plantation_season_details')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _isUpdated),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditSeasonPage(seasonId: widget.seasonId),
                    ),
                  );
                  if (result == true) {
                    _refresh();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final userId = auth.user?.id;
                  if (userId != null && userId.isNotEmpty) {
                    _deleteSeason(userId);
                  }
                },
              ),
            ],
          ),
          body: FutureBuilder<SeasonModel>(
            future: _seasonFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _lastSeason == null) {
                return Center(
                    child: LoadingSpinner(
                        message: context.tr('plantation_loading_season')));
              } else if (snapshot.hasError && _lastSeason == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${context.tr('common_error')}: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: Text(context.tr('common_retry')),
                      ),
                    ],
                  ),
                );
              }

              final season = snapshot.data ?? _lastSeason;
              if (season == null) {
                return Center(child: Text(context.tr('common_no_data')));
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  slivers: [
                    // Season Information Card - Matching farm details style
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  season.seasonName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                // Farm Name and District
                                FutureBuilder<FarmRecord?>(
                                  future: _farmFuture,
                                  builder: (context, farmSnapshot) {
                                    if (farmSnapshot.connectionState ==
                                            ConnectionState.waiting &&
                                        _lastFarm == null) {
                                      return _buildInfoRow(
                                          context,
                                          context.tr('plantation_farm'),
                                          context.tr('common_loading'));
                                    }

                                    final farm = farmSnapshot.data ?? _lastFarm;
                                    if (farm != null) {
                                      return Column(
                                        children: [
                                          _buildInfoRow(
                                              context,
                                              context.tr('plantation_farm'),
                                              farm.farmName),
                                          _buildInfoRow(
                                              context,
                                              context.tr('plantation_district'),
                                              farm.district.get(lang)),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                _buildInfoRow(
                                    context,
                                    context
                                        .tr('plantation_harvest_period_label'),
                                    season.period),
                                _buildInfoRow(
                                    context,
                                    context.tr('plantation_total_yield_label'),
                                    '${season.totalHarvestedYield.toStringAsFixed(2)} kg'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${context.tr('plantation_status')} ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: season.status == 'season-end'
                                            ? Colors.red[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        season.status == 'season-end'
                                            ? context.tr('plantation_ended')
                                            : context.tr('plantation_active'),
                                        style: TextStyle(
                                          color: season.status == 'season-end'
                                              ? Colors.red[800]
                                              : Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (season.status != 'season-end') ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _endSeason,
                                      child: Text(context
                                          .tr('plantation_end_season_button')),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Sessions Section Header
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr('plantation_harvesting_sessions'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Sessions List
                    Consumer<SessionController>(
                      builder: (context, sessionController, child) {
                        if (sessionController.isLoading) {
                          return SliverFillRemaining(
                            child: LoadingSpinner(
                                message: lang == 'si'
                                    ? 'වාර පූරණය වෙමින්...'
                                    : 'Loading sessions...'),
                          );
                        } else if (sessionController.error != null) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${context.tr('common_error')}: ${sessionController.error}',
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      sessionController
                                          .fetchSessions(widget.seasonId);
                                    },
                                    child: Text(context.tr('common_retry')),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final sessions = sessionController.sessions;
                        if (sessions.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: EmptyState(
                                message:
                                    context.tr('plantation_no_sessions_yet'),
                                icon: Icons.inventory_2_outlined,
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.only(bottom: 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final session = sessions[index];
                                return SessionCard(
                                  session: session,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditSessionPage(
                                          sessionId: session.id,
                                          seasonId: widget.seasonId,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _refresh();
                                    }
                                  },
                                );
                              },
                              childCount: sessions.length,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FutureBuilder<SeasonModel>(
            future: _seasonFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.status != 'season-end') {
                return FloatingActionButton.extended(
                  heroTag: 'season_details_fab',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateSessionPage(seasonId: widget.seasonId),
                      ),
                    );
                    if (result == true && mounted) {
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('plantation_add_session_label')),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
