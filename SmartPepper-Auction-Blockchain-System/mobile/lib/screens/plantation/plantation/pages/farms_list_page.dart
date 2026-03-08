import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import 'dart:developer' as developer;
import '../controllers/plantation_controller.dart';
import '../models/farm_record_model.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class FarmsListPage extends ConsumerStatefulWidget {
  const FarmsListPage({super.key});

  @override
  ConsumerState<FarmsListPage> createState() => _FarmsListPageState();
}

class _FarmsListPageState extends ConsumerState<FarmsListPage> {
  @override
  void initState() {
    super.initState();
    // Refresh farms list when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(farmsProvider);
    });
  }

  Future<void> _refreshFarms() async {
    ref.invalidate(farmsProvider);
  }

  @override
  Widget build(BuildContext context) {
    developer.log('FarmsListPage: Building...');
    
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    
    try {
      final farmsAsync = ref.watch(farmsProvider);
      
      return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_my_farms')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFarms,
            tooltip: context.tr('plantation_refresh'),
          ),
        ],
      ),
      body: farmsAsync.when(
        data: (farms) {
          if (farms.isEmpty) {
            return EmptyState(
              message: context.tr('plantation_no_farms_yet'),
              icon: Icons.agriculture_outlined,
              action: PrimaryButton(
                text: context.tr('plantation_start_plantation'),
                onPressed: () async {
                  final result = await context.pushNamed('plantationSetup');
                  if (result != null && mounted) {
                    _refreshFarms();
                  }
                },
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshFarms,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header section with summary
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
                      child: Row(
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
                                  context.tr('plantation_total_farms'),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                ),
                                Text(
                                  '${farms.length}',
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
                    ),
                  ),
                ),
                // Farms list
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16, bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final farm = farms[index];
                        return _buildFarmCard(context, ref, farm, lang);
                      },
                      childCount: farms.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => LoadingSpinner(message: context.tr('plantation_loading_farms')),
        error: (error, stack) {
          developer.log('FarmsListPage: Error state - $error', error: error, stackTrace: stack);
          return RefreshIndicator(
            onRefresh: _refreshFarms,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: EmptyState(
                message: '${context.tr('plantation_error_loading_farms')}: ${error.toString()}',
                icon: Icons.error_outline,
                action: ElevatedButton(
                  onPressed: _refreshFarms,
                  child: Text(context.tr('common_retry')),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'farms_list_fab',
        onPressed: () async {
          final result = await context.pushNamed('plantationSetup');
          if (result != null && mounted) {
            _refreshFarms();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr('plantation_start_plantation')),
      ),
    );
    } catch (e, stackTrace) {
      developer.log('FarmsListPage: Error in build - $e', error: e, stackTrace: stackTrace);
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Farms'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading farms page',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
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

  Widget _buildFarmCard(BuildContext context, WidgetRef ref, FarmRecord farm, String lang) {
    final dateFormat = '${farm.farmStartDate.day}/${farm.farmStartDate.month}/${farm.farmStartDate.year}';
    
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
                      onTap: () {
                      context.pushNamed(
                        'farmDetails',
                        pathParameters: {'farmId': farm.id},
                      ).then((result) {
                        if (result == true) {
                          // Invalidate all related providers
                          ref.invalidate(farmsProvider);
                          ref.invalidate(farmProvider(farm.id));
                        }
                      });
                    },
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
                // Header with farm name and menu
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture,
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
                            context.tr('plantation_farm'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farm.farmName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                           final farmDetails = await ref
                               .read(plantationControllerProvider.notifier)
                               .fetchFarmById(farm.id);
                           if (context.mounted) {
                             final result = await context.pushNamed<bool>(
                               'editFarm',
                               extra: farmDetails,
                             );
                             if (result == true && mounted) {
                               ref.invalidate(farmsProvider);
                               ref.invalidate(farmProvider(farm.id));
                             }
                           }
                        } else if (value == 'delete') {
                           final confirm = await showDialog<bool>(
                             context: context,
                             builder: (ctx) => AlertDialog(
                               title: Text(context.tr('plantation_delete_farm')),
                               content: Text(context.tr('plantation_confirm_delete_farm')),
                               actions: [
                                 TextButton(
                                   onPressed: () => Navigator.pop(ctx, false),
                                   child: Text(context.tr('common_cancel')),
                                 ),
                                 TextButton(
                                   onPressed: () => Navigator.pop(ctx, true),
                                   child: Text(
                                     context.tr('common_delete'),
                                     style: const TextStyle(color: Colors.red),
                                   ),
                                 ),
                               ],
                             ),
                           );
                           if (confirm == true) {
                             try {
                               await ref
                                   .read(plantationControllerProvider.notifier)
                                   .deleteFarm(farm.id);
                               _refreshFarms();
                             } catch (e) {
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text('Error: $e')),
                                 );
                               }
                             }
                           }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Farm details in a grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.location_on,
                        context.tr('plantation_district'),
                        farm.district.get(lang),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.eco,
                        context.tr('plantation_variety'),
                        farm.chosenVariety.get(lang),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.square_foot,
                        context.tr('plantation_area'),
                        '${farm.areaHectares} ${context.tr('plantation_hectares')}',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.agriculture,
                        context.tr('plantation_vines'),
                        '${farm.totalVines}',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Start date
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('plantation_started'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value, Color iconColor) {
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
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
