import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/plantation_controller.dart';
import '../models/farm_task_model.dart';
import '../models/farm_record_model.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state.dart';
import 'task_completion_page.dart';
import 'edit_farm_page.dart';
import 'manual_task_dialog.dart';

class FarmDetailsPage extends ConsumerWidget {
  final String farmId;

  const FarmDetailsPage({super.key, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmProvider(farmId));
    final tasksAsync = ref.watch(farmTasksProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: farmAsync.when(
          data: (farm) => Text(farm.farmName),
          loading: () => const Text('Farm Details'),
          error: (_, __) => const Text('Farm Details'),
        ),
        actions: [
          // Add Manual Task Button in AppBar
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Add Manual Task',
            onPressed: () {
              if (farmAsync.hasValue) {
                _showManualTaskDialog(context, ref, farmAsync.value!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Farm',
            onPressed: () async {
              if (farmAsync.hasValue) {
                final farm = farmAsync.value!;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditFarmPage(farm: farm),
                  ),
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
            tooltip: 'Delete Farm',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Farm'),
                  content: const Text(
                      'Are you sure you want to delete this farm? All related tasks will be removed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
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
                      const SnackBar(
                        content: Text('Farm deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
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
                          _buildInfoRow(context, 'District', farm.district),
                          _buildInfoRow(context, 'Variety', farm.chosenVariety),
                          _buildInfoRow(context, 'Area', '${farm.areaHectares} hectares'),
                          _buildInfoRow(context, 'Total Vines', '${farm.totalVines}'),
                          _buildInfoRow(
                            context,
                            'Farm Start Date',
                            '${farm.farmStartDate.day}/${farm.farmStartDate.month}/${farm.farmStartDate.year}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tasks Lifecycle Journey
                  Text(
                    'Farm Task Journey',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  tasksAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return const EmptyState(
                          message: 'No tasks scheduled yet.',
                          icon: Icons.task_alt,
                        );
                      }

                      // Debug: Log all tasks
                      debugPrint('Total tasks received: ${tasks.length}');
                      for (var task in tasks) {
                        debugPrint('Task: ${task.taskName}, Phase: ${task.phase}, Status: ${task.status}');
                      }

                      return _buildPhaseStepper(context, ref, farm, tasks);
                    },
                    loading: () => const LoadingSpinner(message: 'Loading tasks...'),
                    error: (error, stack) => EmptyState(
                      message: 'Error loading tasks: ${error.toString()}',
                      icon: Icons.error_outline,
                      action: ElevatedButton(
                        onPressed: () {
                          ref.invalidate(farmTasksProvider(farmId));
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingSpinner(message: 'Loading farm details...'),
        error: (error, stack) => EmptyState(
          message: 'Error loading farm: ${error.toString()}',
          icon: Icons.error_outline,
          action: ElevatedButton(
            onPressed: () {
              ref.invalidate(farmProvider(farmId));
            },
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  Future<void> _showManualTaskDialog(
    BuildContext context,
    WidgetRef ref,
    FarmRecord farm,
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
            const SnackBar(
              content: Text('Manual task created successfully!'),
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
  ) {
    final phases = _groupTasksByPhase(farm, tasks);

    // Use ExpansionTile instead of Stepper for better control and visibility
    return Column(
      children: [
        _buildPhaseSection(
          context,
          ref,
          farm,
          'Phase 1: Landscaping & Prep',
          phases[1]!,
          Icons.landscape,
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildPhaseSection(
          context,
          ref,
          farm,
          'Phase 2: Planting Day',
          phases[2]!,
          Icons.eco,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildPhaseSection(
          context,
          ref,
          farm,
          'Phase 3: Maintenance',
          phases[3]!,
          Icons.build,
          Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildPhaseSection(
          context,
          ref,
          farm,
          'Phase 4: Harvesting & Processing',
          phases[4]!,
          Icons.agriculture,
          Colors.purple,
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
          '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        initiallyExpanded: tasks.isNotEmpty, // Auto-expand if has tasks
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildTaskListForPhase(context, ref, farm, tasks),
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
      
      // First, try to determine phase from the task's phase field
      // This respects the phase selected when creating a manual task
      final taskPhase = task.phase.toLowerCase().trim();
      debugPrint('Task: ${task.taskName}, Phase: "${task.phase}", Lowercase: "$taskPhase"');
      
      // Check for exact matches first (from manual task dropdown)
      if (taskPhase == 'landscaping' || 
          taskPhase.contains('landscaping') || 
          taskPhase.contains('prep') || 
          taskPhase.contains('preparation')) {
        phaseIndex = 1; // Phase 1: Landscaping & Prep
        debugPrint('  -> Assigned to Phase 1 (Landscaping)');
      } else if (taskPhase == 'planting' || taskPhase.contains('planting')) {
        phaseIndex = 2; // Phase 2: Planting Day
        debugPrint('  -> Assigned to Phase 2 (Planting)');
      } else if (taskPhase == 'maintenance' || taskPhase.contains('maintenance')) {
        // Maintenance tasks always go to Phase 3, regardless of date
        phaseIndex = 3; // Phase 3: Maintenance
        debugPrint('  -> Assigned to Phase 3 (Maintenance by phase field)');
      } else if (taskPhase == 'harvesting' || 
                 taskPhase.contains('harvesting') || 
                 taskPhase.contains('processing')) {
        phaseIndex = 4; // Phase 4: Harvesting & Processing
        debugPrint('  -> Assigned to Phase 4 (Harvesting)');
      } else {
        // Fallback to date-based calculation only if phase is not recognized
        // This handles auto-generated tasks that might have different phase names
        final monthsDiff = ((task.dueDate.year - farm.farmStartDate.year) * 12) +
            (task.dueDate.month - farm.farmStartDate.month);

        if (monthsDiff < 0) {
          phaseIndex = 1; // Pre-planting (before farm start)
          debugPrint('  -> Assigned to Phase 1 (Pre-planting by date)');
        } else if (monthsDiff == 0) {
          phaseIndex = 2; // Planting Day (month 0)
          debugPrint('  -> Assigned to Phase 2 (Month 0, default to Planting)');
        } else if (monthsDiff >= 24) {
          phaseIndex = 4; // Harvesting & processing (24+ months)
          debugPrint('  -> Assigned to Phase 4 (24+ months)');
        } else {
          phaseIndex = 3; // Maintenance (between 1-23 months)
          debugPrint('  -> Assigned to Phase 3 (Maintenance by date)');
        }
      }

      result[phaseIndex]!.add(task);
      debugPrint('  -> Added to result[$phaseIndex], total tasks in phase: ${result[phaseIndex]!.length}');
    }

    debugPrint('Final phase counts: Phase 1: ${result[1]!.length}, Phase 2: ${result[2]!.length}, Phase 3: ${result[3]!.length}, Phase 4: ${result[4]!.length}');
    return result;
  }

  Widget _buildTaskListForPhase(
    BuildContext context,
    WidgetRef ref,
    FarmRecord farm,
    List<FarmTask> tasks,
  ) {
    debugPrint('_buildTaskListForPhase called with ${tasks.length} tasks');
    if (tasks.isEmpty) {
      return Text(
        'No tasks in this phase yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: tasks.map((task) {
        debugPrint('  Rendering task: ${task.taskName}, Status: ${task.status}');
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskCompletionPage(
                    task: task,
                  ),
                ),
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
                                task.taskName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                              'Type: ${task.taskType}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isManual)
                              Chip(
                                label: Text(
                                  task.priority,
                                  style: const TextStyle(fontSize: 9),
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
                          'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (task.status == 'Completed' && task.dateCompleted != null)
                          Text(
                            'Completed: ${task.dateCompleted!.day}/${task.dateCompleted!.month}/${task.dateCompleted!.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
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
                        task.status,
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
}

