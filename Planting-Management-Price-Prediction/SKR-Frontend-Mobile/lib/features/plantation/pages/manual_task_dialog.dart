import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/utils/validators.dart';

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
  final _instructionsController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime? _dueDate;
  String _priority = 'Medium';
  String? _selectedPhase;

  @override
  void dispose() {
    _taskNameController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
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
