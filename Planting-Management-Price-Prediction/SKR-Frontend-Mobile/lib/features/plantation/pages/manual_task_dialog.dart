import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_template_model.dart';
import '../services/emergency_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/validators.dart';

final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService(ApiClient());
});

final emergencyTemplatesProvider = FutureProvider.family<List<EmergencyTemplate>, String?>((ref, search) async {
  final service = ref.read(emergencyServiceProvider);
  return await service.getEmergencyTemplates(search: search);
});

class ManualTaskDialog extends ConsumerStatefulWidget {
  final String farmId;

  const ManualTaskDialog({
    super.key,
    required this.farmId,
  });

  @override
  ConsumerState<ManualTaskDialog> createState() => _ManualTaskDialogState();
}

class _ManualTaskDialogState extends ConsumerState<ManualTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _searchController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime? _dueDate;
  String _priority = 'Medium';
  String? _selectedPhase;
  EmergencyTemplate? _selectedTemplate;

  @override
  void dispose() {
    _taskNameController.dispose();
    _searchController.dispose();
    _instructionsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _selectEmergencyTemplate(EmergencyTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _taskNameController.text = template.treatmentTask;
      _instructionsController.text = template.instructions;
      _priority = template.priority;
      _reasonController.text = 'Emergency: ${template.issueName} - ${template.symptoms}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchTerm = _searchController.text.isEmpty ? null : _searchController.text;
    final templatesAsync = ref.watch(emergencyTemplatesProvider(searchTerm));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_task,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Manual Task',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Emergency Template Search Section
                      Card(
                        color: Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.emergency, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Search for Pest/Disease (Optional)',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              InputField(
                                label: 'Search',
                                controller: _searchController,
                                hint: 'e.g., wilt, thrips, disease',
                                onChanged: (value) {
                                  setState(() {}); // Trigger rebuild to refresh search
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      templatesAsync.when(
                        data: (templates) {
                          if (templates.isEmpty && _searchController.text.isNotEmpty) {
                            return Card(
                              color: Colors.grey[100],
                              child: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  'No emergency templates found',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          if (templates.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: templates.length,
                              itemBuilder: (context, index) {
                                final template = templates[index];
                                final isSelected = _selectedTemplate?.id == template.id;
                                return Card(
                                  margin: const EdgeInsets.all(4),
                                  color: isSelected ? Colors.blue[50] : Colors.white,
                                  elevation: isSelected ? 2 : 0,
                                  child: InkWell(
                                    onTap: () => _selectEmergencyTemplate(template),
                                    child: ListTile(
                                      leading: Icon(
                                        isSelected ? Icons.check_circle : Icons.info_outline,
                                        color: isSelected ? Colors.blue : Colors.grey,
                                      ),
                                      title: Text(
                                        template.issueName,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.blue[900] : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        template.symptoms,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          template.priority,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: _getPriorityColor(template.priority),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, stack) => Card(
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Error: $error',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedTemplate != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: Colors.green[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.green[300]!, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Template Selected',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[900],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Issue: ${_selectedTemplate!.issueName}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Treatment: ${_selectedTemplate!.treatmentTask}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Task Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Task Name',
                        controller: _taskNameController,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      // Priority Dropdown
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Low',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                const Flexible(child: Text('Low')),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.remove, size: 16, color: Colors.yellow[700]),
                                const SizedBox(width: 8),
                                const Flexible(child: Text('Medium')),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'High',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_upward, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Flexible(child: Text('High')),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Emergency',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                const Flexible(child: Text('Emergency')),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _priority = value ?? 'Medium';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phase Dropdown
                      DropdownButtonFormField<String?>(
                        value: _selectedPhase,
                        decoration: InputDecoration(
                          labelText: 'Phase (Optional)',
                          hintText: 'Default: Maintenance',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (Default)'),
                          ),
                          DropdownMenuItem(value: 'Landscaping', child: Text('Landscaping')),
                          DropdownMenuItem(value: 'Planting', child: Text('Planting')),
                          DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                          DropdownMenuItem(value: 'Harvesting', child: Text('Harvesting')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPhase = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: InputField(
                            label: 'Due Date',
                            controller: TextEditingController(
                              text: _dueDate != null
                                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                  : '',
                            ),
                            validator: (value) {
                              if (_dueDate == null) {
                                return 'Please select a due date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Instructions/Steps',
                        controller: _instructionsController,
                        hint: 'Detailed instructions for this task...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Reason (Optional)',
                        controller: _reasonController,
                        hint: 'Why is this task needed?',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Create Task'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && _dueDate != null) {
      final detailedSteps = _instructionsController.text.trim().isEmpty
          ? null
          : [_instructionsController.text.trim()];

      Navigator.pop(context, {
        'taskName': _taskNameController.text.trim(),
        'phase': _selectedPhase,
        'dueDate': _dueDate,
        'priority': _priority,
        'detailedSteps': detailedSteps,
        'reasonWhy': _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      });
    }
  }
}

