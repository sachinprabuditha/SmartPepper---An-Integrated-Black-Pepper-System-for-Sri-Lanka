import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../controllers/season_controller.dart';
import '../models/season_model.dart';
import '../pages/create_season_page.dart';
import '../pages/season_details_page.dart';
import '../../plantation/controllers/plantation_controller.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/language_picker_button.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/loading_spinner.dart';
import '../widgets/season_card.dart';

class SeasonsListPage extends ConsumerStatefulWidget {
  const SeasonsListPage({super.key});

  @override
  ConsumerState<SeasonsListPage> createState() => _SeasonsListPageState();
}

class _SeasonsListPageState extends ConsumerState<SeasonsListPage> {
  String? _userId;
  String? _selectedFarmId; // For filtering by farm

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = vanilla_provider.Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId != null && userId.isNotEmpty && userId != _userId) {
      setState(() {
        _userId = userId;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(seasonControllerProvider.notifier).fetchSeasons(userId);
      });
    }
  }

  Future<void> _refreshSeasons() async {
    if (_userId != null) {
      await ref.read(seasonControllerProvider.notifier).fetchSeasons(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final languageProvider =
          vanilla_provider.Provider.of<LanguageProvider>(context);
      final lang = languageProvider.locale.languageCode;
      final seasonsState = ref.watch(seasonControllerProvider);

      return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Harvest Seasons' : 'අස්වනු කන්න'),
        elevation: 0,
        actions: const [
          LanguagePickerButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _userId == null
          ? LoadingSpinner(
              message: lang == 'en' ? 'Loading user...' : 'පරිශීලකයා පූරණය වෙමින්...',
            )
          : RefreshIndicator(
              onRefresh: _refreshSeasons,
              child: seasonsState.when(
                data: (seasons) {
                  // Sort seasons by startYear (descending) and startMonth (descending) - newest first
                  final sortedSeasons = List<SeasonModel>.from(seasons)
                    ..sort((a, b) {
                      // First compare by year (descending)
                      if (a.startYear != b.startYear) {
                        return b.startYear.compareTo(a.startYear);
                      }
                      // If same year, compare by month (descending)
                      return b.startMonth.compareTo(a.startMonth);
                    });

                  // Filter by selected farm if a farm is selected
                  final filteredSeasons = _selectedFarmId == null
                      ? sortedSeasons
                      : sortedSeasons.where((season) => season.farmId == _selectedFarmId).toList();

                  return CustomScrollView(
                    slivers: [
                      // Header section with summary and filter
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.agriculture,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFarmId == null
                                                ? (lang == 'en' ? 'Total Seasons' : 'මුළු කන්න')
                                                : (lang == 'en'
                                                    ? 'Filtered Seasons'
                                                    : 'පෙරහන් කළ කන්න'),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 12,
                                                ),
                                          ),
                                          Text(
                                            '${filteredSeasons.length}',
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Farm Filter Dropdown
                                Consumer(
                                  builder: (context, ref, child) {
                                    final farmsAsync = ref.watch(farmsProvider);
                                    return farmsAsync.when(
                                      data: (farms) {
                                        if (farms.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: DropdownButton<String?>(
                                            value: _selectedFarmId,
                                            isExpanded: true,
                                            hint: Row(
                                              children: [
                                                Icon(
                                                  Icons.filter_list,
                                                  size: 18,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  lang == 'en'
                                                      ? 'Filter by Farm'
                                                      : 'ගොවිපල අනුව පෙරන්න',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            underline: const SizedBox.shrink(),
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            items: [
                                              DropdownMenuItem<String?>(
                                                value: null,
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                                                    const SizedBox(width: 8),
                                                    Text(lang == 'en' ? 'All Farms' : 'සියලු ගොවිපල'),
                                                  ],
                                                ),
                                              ),
                                              ...farms.map((farm) => DropdownMenuItem<String?>(
                                                    value: farm.id,
                                                    child: Text(farm.farmName),
                                                  )),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedFarmId = value;
                                              });
                                            },
                                          ),
                                        );
                                      },
                                      loading: () => Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ),
                                      error: (_, __) => const SizedBox.shrink(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Seasons list or empty state
                      filteredSeasons.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: EmptyState(
                                  message: _selectedFarmId == null
                                      ? (lang == 'en'
                                          ? 'No harvest seasons yet.\nCreate your first season to start tracking your harvests!'
                                          : 'තවම අස්වනු කන්න නැත.\nඔබේ අස්වැන්න වාර්තා කිරීම ආරම්භ කිරීමට පළමු කන්නය සාදන්න!')
                                      : (lang == 'en'
                                          ? 'No seasons found for the selected farm.'
                                          : 'තෝරාගත් ගොවිපල සඳහා කන්න හමු නොවීය.'),
                                  icon: Icons.agriculture_outlined,
                                  action: _selectedFarmId == null
                                      ? FloatingActionButton.extended(
                                          heroTag: 'seasons_list_empty_fab',
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CreateSeasonPage(userId: _userId!),
                                              ),
                                            );
                                            if (result == true) {
                                              _refreshSeasons();
                                            }
                                          },
                                          icon: const Icon(Icons.add),
                                          label: Text(lang == 'en' ? 'Create Season' : 'කන්නයක් සාදන්න'),
                                        )
                                      : null,
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.only(top: 16, bottom: 80),
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
                                            builder: (_) => SeasonDetailsPage(seasonId: season.id),
                                          ),
                                        );
                                        if (result == true) {
                                          _refreshSeasons();
                                        }
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
                loading: () => LoadingSpinner(
                  message: lang == 'en' ? 'Loading seasons...' : 'කන්න පූරණය වෙමින්...',
                ),
                error: (error, stack) {
                  print('Error loading seasons: $error');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            '${lang == 'en' ? 'Error' : 'දෝෂය'}: ${error.toString()}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshSeasons,
                            child: Text(lang == 'en' ? 'Retry' : 'නැවත උත්සාහ කරන්න'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _userId != null
          ? FloatingActionButton.extended(
              heroTag: 'seasons_list_fab',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateSeasonPage(userId: _userId!),
                  ),
                );
                if (result == true) {
                  _refreshSeasons();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(lang == 'en' ? 'Create Season' : 'කන්නයක් සාදන්න'),
            )
          : null,
      );
    } catch (e, stackTrace) {
      print('Error building SeasonsListPage: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Harvest Seasons'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

