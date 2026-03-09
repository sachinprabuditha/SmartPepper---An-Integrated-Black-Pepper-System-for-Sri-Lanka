import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../controllers/season_controller.dart';
import '../../sessions/pages/create_session_page.dart';
import '../../sessions/widgets/session_card.dart';
import '../../sessions/controllers/session_controller.dart';
import '../../sessions/pages/edit_session_page.dart';
import '../../plantation/controllers/plantation_controller.dart';
import '../pages/edit_season_page.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';

class SeasonDetailsPage extends ConsumerWidget {
  final String seasonId;

  const SeasonDetailsPage({super.key, required this.seasonId});

  Future<void> _deleteSeason(
      BuildContext context, WidgetRef ref, String userId) async {
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
        await ref
            .read(seasonControllerProvider.notifier)
            .deleteSeason(seasonId, userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_season_deleted')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageProvider =
        vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    final seasonAsync = ref.watch(seasonProvider(seasonId));
    final auth =
        vanilla_provider.Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_season_details')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSeasonPage(seasonId: seasonId),
                ),
              );
              if (result == true) {
                ref.invalidate(seasonProvider(seasonId));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final userId = auth.user?.id;
              if (userId != null && userId.isNotEmpty) {
                _deleteSeason(context, ref, userId);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(seasonProvider(seasonId));
          ref.invalidate(sessionControllerProvider(seasonId));
        },
        child: seasonAsync.when(
          data: (season) {
            final farmAsync = ref.watch(farmProvider(season.farmId));
            final sessionsState =
                ref.watch(sessionControllerProvider(seasonId));

            return CustomScrollView(
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
                            farmAsync.when(
                              data: (farm) => Column(
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
                              ),
                              loading: () => _buildInfoRow(
                                  context,
                                  context.tr('plantation_farm'),
                                  context.tr('common_loading')),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                            _buildInfoRow(
                                context,
                                context.tr('plantation_harvest_period_label'),
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
                                      ?.copyWith(fontWeight: FontWeight.w600),
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
                                  onPressed: () => _endSeason(context, ref),
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sessions List
                sessionsState.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: EmptyState(
                            message: context.tr('plantation_no_sessions_yet'),
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
                                      seasonId: seasonId,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  ref.invalidate(
                                      sessionControllerProvider(seasonId));
                                  ref.invalidate(seasonProvider(
                                      seasonId)); // Also refresh season to get updated yield
                                }
                              },
                            );
                          },
                          childCount: sessions.length,
                        ),
                      ),
                    );
                  },
                  loading: () => SliverFillRemaining(
                    child: LoadingSpinner(
                      message: lang == 'si'
                          ? 'වාර පූරණය වෙමින්...'
                          : 'Loading sessions...',
                    ),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${context.tr('common_error')}: ${error.toString()}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(
                                  sessionControllerProvider(seasonId));
                            },
                            child: Text(context.tr('common_retry')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => LoadingSpinner(
            message: context.tr('plantation_loading_season'),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${context.tr('common_error')}: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(seasonProvider(seasonId));
                  },
                  child: Text(context.tr('common_retry')),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: seasonAsync.when(
        data: (season) {
          if (season.status == 'season-end') return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: 'season_details_fab',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateSessionPage(seasonId: seasonId),
                ),
              );
              if (result == true && context.mounted) {
                ref.invalidate(sessionControllerProvider(seasonId));
                ref.invalidate(
                    seasonProvider(seasonId)); // Refresh season for yield
              }
            },
            icon: const Icon(Icons.add),
            label: Text(context.tr('plantation_add_session_label')),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
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

  Future<void> _endSeason(BuildContext context, WidgetRef ref) async {
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
        await ref.read(seasonControllerProvider.notifier).endSeason(seasonId);
        ref.invalidate(seasonProvider(seasonId)); // Refresh details
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_season_ended')),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr('common_error')}: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }
}
