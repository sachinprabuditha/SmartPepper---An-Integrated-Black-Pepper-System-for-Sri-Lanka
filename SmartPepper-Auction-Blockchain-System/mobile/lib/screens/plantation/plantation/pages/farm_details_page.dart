import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../controllers/plantation_controller.dart';
import '../models/farm_task_model.dart';
import '../models/farm_record_model.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/language_picker_button.dart';
import 'manual_task_dialog.dart';

class FarmDetailsPage extends ConsumerWidget {
  final String farmId;

  const FarmDetailsPage({super.key, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    
    final farmAsync = ref.watch(farmProvider(farmId));
    final tasksAsync = ref.watch(farmTasksProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: farmAsync.when(
          data: (farm) => Text(farm.farmName),
          loading: () => Text(lang == 'en' ? 'Farm Details' : 'ගොවිපළේ විස්තර'),
          error: (_, __) => Text(lang == 'en' ? 'Farm Details' : 'ගොවිපළේ විස්තර'),
        ),
        actions: [
          const LanguagePickerButton(),
          const SizedBox(width: 4),
          // Add Manual Task Button in AppBar
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: lang == 'en' ? 'Add Manual Task' : 'කාර්යයක් එක් කරන්න',
            onPressed: () {
              if (farmAsync.hasValue) {
                _showManualTaskDialog(context, ref, farmAsync.value!, lang);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: lang == 'en' ? 'Edit Farm' : 'ගොවිපළ සංස්කරණය කරන්න',
            onPressed: () async {
              if (farmAsync.hasValue) {
                final farm = farmAsync.value!;
                final result = await context.pushNamed<bool>(
                  'editFarm',
                  extra: farm,
                );
                if (result == true) {
                  // Invalidate all related providers to refresh data
                  ref.invalidate(farmProvider(farmId));
                  ref.invalidate(farmTasksProvider(farmId));
                  ref.invalidate(farmsProvider);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: lang == 'en' ? 'Delete Farm' : 'ගොවිපළ මකන්න',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(lang == 'en' ? 'Delete Farm' : 'ගොවිපළ මකන්න'),
                  content: Text(lang == 'en' 
                      ? 'Are you sure you want to delete this farm? All related tasks will be removed.'
                      : 'මෙම ගොවිපළ මකා දැමීමට ඔබට විශ්වාසද? සියලුම අදාළ කාර්යයන් ඉවත් කරනු ලැබේ.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        lang == 'en' ? 'Delete' : 'මකන්න',
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
                      .deleteFarm(farmId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang == 'en' ? 'Farm deleted' : 'ගොවිපළ මකා දමන ලදී'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Error deleting farm: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: farmAsync.when(
        data: (farm) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(farmProvider(farmId));
              ref.invalidate(farmTasksProvider(farmId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.farmName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context, lang == 'en' ? 'District' : 'දිස්ත්‍රික්කය', farm.district.get(lang)),
                          _buildInfoRow(context, lang == 'en' ? 'Variety' : 'ප්‍රභේදය', farm.chosenVariety.get(lang)),
                          _buildInfoRow(context, lang == 'en' ? 'Area' : 'වපසරිය', '${farm.areaHectares} ${lang == 'en' ? 'hectares' : 'හෙක්ටයාර'}'),
                          _buildInfoRow(context, lang == 'en' ? 'Total Vines' : 'මුළු වැල් ගණන', '${farm.totalVines}'),
                          _buildInfoRow(
                            context,
                            lang == 'en' ? 'Farm Start Date' : 'ගොවිපළ ආරම්භ කළ දිනය',
                            '${farm.farmStartDate.day}/${farm.farmStartDate.month}/${farm.farmStartDate.year}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tasks Lifecycle Journey
                  Text(
                    lang == 'en' ? 'Farm Task Journey' : 'වගාවේ කාර්යයන් ගමන',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  tasksAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return EmptyState(
                          message: lang == 'en' ? 'No tasks scheduled yet.' : 'තවම කාර්යයන් සැලසුම් කර නොමැත.',
                          icon: Icons.task_alt,
                        );
                      }

                      return _buildPhaseStepper(context, ref, farm, tasks, lang);
                    },
                    loading: () => LoadingSpinner(message: lang == 'en' ? 'Loading tasks...' : 'කාර්යයන් පටවමින්...'),
                    error: (error, stack) => EmptyState(
                      message: lang == 'en' ? 'Error loading tasks: ${error.toString()}' : 'කාර්යයන් පැටවීමේ දෝෂයකි: ${error.toString()}',
                      icon: Icons.error_outline,
                      action: ElevatedButton(
                        onPressed: () {
                          ref.invalidate(farmTasksProvider(farmId));
                        },
                        child: Text(lang == 'en' ? 'Retry' : 'නැවත උත්සාහ කරන්න'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => LoadingSpinner(message: lang == 'en' ? 'Loading farm details...' : 'ගොවිපළේ විස්තර පටවමින්...'),
        error: (error, stack) => EmptyState(
          message: lang == 'en' ? 'Error loading farm: ${error.toString()}' : 'ගොවිපළ පැටවීමේ දෝෂයකි: ${error.toString()}',
          icon: Icons.error_outline,
          action: ElevatedButton(
            onPressed: () {
              ref.invalidate(farmProvider(farmId));
            },
            child: Text(lang == 'en' ? 'Retry' : 'නැවත උත්සාහ කරන්න'),
          ),
        ),
      ),
    );
  }

  Future<void> _showManualTaskDialog(
    BuildContext context,
    WidgetRef ref,
    FarmRecord farm,
    String lang,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ManualTaskDialog(farmId: farm.id),
    );

    if (result != null) {
      try {
        await ref.read(plantationControllerProvider.notifier).createManualTask(
              farmId: farm.id,
              taskName: result['taskName'] as String,
              phase: result['phase'] as String?,
              dueDate: result['dueDate'] as DateTime,
              priority: result['priority'] as String,
              detailedSteps: result['detailedSteps'] as List<String>?,
              reasonWhy: result['reasonWhy'] as String?,
            );

        ref.invalidate(farmTasksProvider(farm.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang == 'en' ? 'Manual task created successfully!' : 'අතින් සැකසූ කාර්යය සාර්ථකව නිර්මාණය කරන ලදී!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating task: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

  Color _getTaskColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green[50]!;
      case 'Overdue':
        return Colors.red[50]!;
      default:
        return Colors.blue[50]!;
    }
  }

  Icon _getTaskIcon(String status) {
    switch (status) {
      case 'Completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Overdue':
        return const Icon(Icons.warning, color: Colors.red);
      default:
        return const Icon(Icons.schedule, color: Colors.blue);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'emergency':
        return Colors.red[300]!;
      case 'high':
        return Colors.orange[300]!;
      case 'medium':
        return Colors.yellow[300]!;
      case 'low':
        return Colors.green[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Widget _buildPhaseStepper(
    BuildContext context,
    WidgetRef ref,
    FarmRecord farm,
    List<FarmTask> tasks,
    String lang,
  ) {
    final phases = _groupTasksByPhase(farm, tasks);

    // Use ExpansionTile instead of Stepper for better control and visibility
    return Column(
      children: [
        _buildPhaseSection(
          context,
          ref,
          farm,
          lang == 'en' ? 'Phase 1: Landscaping & Prep' : 'අදියර 1: ඉඩම් සකස් කිරීම',
          phases[1]!,
          Icons.landscape,
          Colors.green,
          lang,
        ),
        const SizedBox(height: 8),
        _buildPhaseSection(
          context,
          ref,
          farm,
          lang == 'en' ? 'Phase 2: Planting Day' : 'අදියර 2: පැළ සිටුවීම',
          phases[2]!,
          Icons.eco,
          Colors.blue,
          lang,
        ),
        const SizedBox(height: 8),
        _buildPhaseSection(
          context,
          ref,
          farm,
          lang == 'en' ? 'Phase 3: Maintenance' : 'අදියර 3: නඩත්තුව',
          phases[3]!,
          Icons.build,
          Colors.orange,
          lang,
        ),
        const SizedBox(height: 8),
        _buildPhaseSection(
          context,
          ref,
          farm,
          lang == 'en' ? 'Phase 4: Harvesting & Processing' : 'අදියර 4: අස්වැන්න නෙළීම',
          phases[4]!,
          Icons.agriculture,
          Colors.purple,
          lang,
        ),
      ],
    );
  }

  Widget _buildPhaseSection(
    BuildContext context,
    WidgetRef ref,
    FarmRecord farm,
    String phaseTitle,
    List<FarmTask> tasks,
    IconData icon,
    Color color,
    String lang,
  ) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          phaseTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          lang == 'en' ? '${tasks.length} task${tasks.length != 1 ? 's' : ''}' : 'කාර්යයන් ${tasks.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        initiallyExpanded: tasks.isNotEmpty, // Auto-expand if has tasks
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildTaskListForPhase(context, ref, farm, tasks, lang),
          ),
        ],
      ),
    );
  }

  Map<int, List<FarmTask>> _groupTasksByPhase(FarmRecord farm, List<FarmTask> tasks) {
    final Map<int, List<FarmTask>> result = {
      1: [],
      2: [],
      3: [],
      4: [],
    };

    for (final task in tasks) {
      int phaseIndex;
      
      final taskPhase = task.phase.toLowerCase().trim();
      
      if (taskPhase == 'landscaping' || 
          taskPhase.contains('landscaping') || 
          taskPhase.contains('prep') || 
          taskPhase.contains('preparation')) {
        phaseIndex = 1; // Phase 1: Landscaping & Prep
      } else if (taskPhase == 'planting' || taskPhase.contains('planting')) {
        phaseIndex = 2; // Phase 2: Planting Day
      } else if (taskPhase == 'maintenance' || taskPhase.contains('maintenance')) {
        phaseIndex = 3; // Phase 3: Maintenance
      } else if (taskPhase == 'harvesting' || 
                 taskPhase.contains('harvesting') || 
                 taskPhase.contains('processing')) {
        phaseIndex = 4; // Phase 4: Harvesting & Processing
      } else {
        final monthsDiff = ((task.dueDate.year - farm.farmStartDate.year) * 12) +
            (task.dueDate.month - farm.farmStartDate.month);

        if (monthsDiff < 0) {
          phaseIndex = 1;
        } else if (monthsDiff == 0) {
          phaseIndex = 2;
        } else if (monthsDiff >= 24) {
          phaseIndex = 4;
        } else {
          phaseIndex = 3;
        }
      }

      result[phaseIndex]!.add(task);
    }

    return result;
  }

  Widget _buildTaskListForPhase(
    BuildContext context,
    WidgetRef ref,
    FarmRecord farm,
    List<FarmTask> tasks,
    String lang,
  ) {
    if (tasks.isEmpty) {
      return Text(
        lang == 'en' ? 'No tasks in this phase yet.' : 'මෙම අදියරේ කාර්යයන් නොමැත.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: tasks.map((task) {
        final isManual = task.isManual;
        final isEmergency = task.priority.toLowerCase() == 'emergency' || task.priority.toLowerCase() == 'high';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: _getTaskColor(task.status),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isManual && isEmergency
                ? const BorderSide(color: Colors.red, width: 2)
                : isManual
                    ? const BorderSide(color: Colors.orange, width: 1.5)
                    : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              context.pushNamed(
                'taskCompletion',
                extra: task,
              ).then((_) {
                ref.invalidate(farmTasksProvider(farm.id));
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Icon
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                    child: isManual && isEmergency
                        ? const Icon(Icons.warning, color: Colors.red, size: 24)
                        : isManual
                            ? const Icon(Icons.edit, color: Colors.orange, size: 24)
                            : _getTaskIcon(task.status),
                  ),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.taskName.get(lang),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black.withOpacity(0.85),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            if (isManual)
                              const Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Icon(Icons.person, size: 14, color: Colors.orange),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Type and Priority
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${lang == 'en' ? 'Type' : 'වර්ගය'}: ${_getTaskTypeTranslation(task.taskType, lang)}',
                              style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.65)),
                            ),
                            if (isManual)
                              Chip(
                                label: Text(
                                  task.priority,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: _getPriorityColor(task.priority),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Due Date
                        Text(
                          '${lang == 'en' ? 'Due' : 'අවසන් දිනය'}: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.65)),
                        ),
                        if (task.status == 'Completed' && task.dateCompleted != null)
                          Text(
                            '${lang == 'en' ? 'Completed' : 'සම්පූර්ණ කළේ'}: ${task.dateCompleted!.day}/${task.dateCompleted!.month}/${task.dateCompleted!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Trailing Status Chip
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: Text(
                        _getStatusTranslation(task.status, lang),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: _getStatusColor(task.status),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getStatusTranslation(String status, String lang) {
    if (lang == 'en') return status;
    switch (status) {
      case 'Scheduled':
        return 'සැලසුම් කළ';
      case 'Completed':
        return 'සම්පූර්ණයි';
      case 'Overdue':
        return 'පසුගිය';
      default:
        return status;
    }
  }

  String _getTaskTypeTranslation(String type, String lang) {
    if (lang == 'en') return type;
    switch (type) {
      case 'Manual':
        return 'අතින් සැකසූ';
      case 'Scheduled':
        return 'සැලසුම් කළ';
      default:
        return type;
    }
  }
}
