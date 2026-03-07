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
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/language_picker_button.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';

class SeasonDetailsPage extends ConsumerWidget {
  final String seasonId;

  const SeasonDetailsPage({super.key, required this.seasonId});

  Future<void> _deleteSeason(BuildContext context, WidgetRef ref, String userId) async {
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context, listen: false);
    final lang = languageProvider.locale.languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang == 'en' ? 'Delete Season' : 'කන්නය මකන්න'),
        content: Text(
          lang == 'en'
              ? 'Are you sure you want to delete this season? This action cannot be undone.'
              : 'මෙම කන්නය මකා දැමීමට ඔබට විශ්වාසද? මෙම ක්‍රියාව ආපසු හැරවිය නොහැක.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang == 'en' ? 'Delete' : 'මකන්න'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(seasonControllerProvider.notifier).deleteSeason(seasonId, userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang == 'en' ? 'Season deleted successfully' : 'කන්නය සාර්ථකව මකා දැමීය'),
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
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    final seasonAsync = ref.watch(seasonProvider(seasonId));
    final auth = vanilla_provider.Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Season Details' : 'කන්න විස්තර'),
        actions: [
          const LanguagePickerButton(),
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
            final sessionsState = ref.watch(sessionControllerProvider(seasonId));
            
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Farm Name and District
                          farmAsync.when(
                            data: (farm) => Column(
                              children: [
                                _buildInfoRow(context, lang == 'en' ? 'Farm' : 'ගොවිපල', farm.farmName),
                                _buildInfoRow(context, lang == 'en' ? 'District' : 'දිස්ත්‍රික්කය', farm.district.get(lang)),
                              ],
                            ),
                            loading: () => _buildInfoRow(context, lang == 'en' ? 'Farm' : 'ගොවිපල', lang == 'en' ? 'Loading...' : 'පූරණය වෙමින්...'),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          _buildInfoRow(context, lang == 'en' ? 'Harvest Period' : 'අස්වනු කාලය', season.period),
                          _buildInfoRow(context, lang == 'en' ? 'Total Yield' : 'මුළු අස්වැන්න', '${season.totalHarvestedYield.toStringAsFixed(2)} kg'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                lang == 'en' ? 'Status: ' : 'තත්ත්වය: ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: season.status == 'season-end' ? Colors.red[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  season.status == 'season-end'
                                      ? (lang == 'en' ? 'Ended' : 'අවසන්')
                                      : (lang == 'en' ? 'Active' : 'සක්‍රිය'),
                                  style: TextStyle(
                                    color: season.status == 'season-end' ? Colors.red[800] : Colors.green[800],
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
                                child: Text(lang == 'en' ? 'End Season' : 'කන්නය අවසන් කරන්න'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        lang == 'en' ? 'Harvesting Sessions' : 'අස්වනු වාර',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          message: lang == 'en'
                              ? 'No harvesting sessions recorded yet.\nTap the + button below to add your first session.'
                              : 'තවම අස්වනු වාර වාර්තා වී නැත.\nඔබේ පළමු වාරය එක් කිරීමට පහත + බොත්තම ඔබන්න.',
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
                                ref.invalidate(sessionControllerProvider(seasonId));
                                ref.invalidate(seasonProvider(seasonId)); // Also refresh season to get updated yield
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
                    message: lang == 'en'
                        ? 'Loading sessions...'
                        : 'වාර පූරණය වෙමින්...',
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${lang == 'en' ? 'Error' : 'දෝෂය'}: ${error.toString()}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(sessionControllerProvider(seasonId));
                          },
                          child: Text(lang == 'en' ? 'Retry' : 'නැවත උත්සාහ කරන්න'),
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
            message: lang == 'en' ? 'Loading season...' : 'කන්නය පූරණය වෙමින්...',
          ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${lang == 'en' ? 'Error' : 'දෝෂය'}: ${error.toString()}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(seasonProvider(seasonId));
                },
                child: Text(lang == 'en' ? 'Retry' : 'නැවත උත්සාහ කරන්න'),
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
                ref.invalidate(seasonProvider(seasonId)); // Refresh season for yield
              }
            },
            icon: const Icon(Icons.add),
            label: Text(lang == 'en' ? 'Add Session' : 'වාරයක් එක් කරන්න'),
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
    final languageProvider =
        vanilla_provider.Provider.of<LanguageProvider>(context, listen: false);
    final lang = languageProvider.locale.languageCode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang == 'en' ? 'End Season' : 'කන්නය අවසන් කරන්න'),
        content: Text(
          lang == 'en'
              ? 'Are you sure you want to end this season? You will not be able to add new harvesting sessions.'
              : 'මෙම කන්නය අවසන් කිරීමට ඔබට විශ්වාසද? ඉන් පසු නව අස්වනු වාර එක් කළ නොහැක.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang == 'en' ? 'End Season' : 'කන්නය අවසන් කරන්න'),
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
              content: Text(
                lang == 'en'
                    ? 'Season ended successfully'
                    : 'කන්නය සාර්ථකව අවසන් විය',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${lang == 'en' ? 'Error' : 'දෝෂය'}: ${e.toString()}',
              ),
            ),
          );
        }
      }
    }
  }
}

