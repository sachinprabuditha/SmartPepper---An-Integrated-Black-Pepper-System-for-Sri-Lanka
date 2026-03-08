import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../../../../localization/app_localizations.dart';
import '../../../../widgets/input_field.dart';
import '../../../../utils/validators.dart';
import '../../../../providers/language_provider.dart';

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
      helpText: context.tr('manual_task_dialog_select_due_date'),
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
                      context.tr('plantation_add_manual_task'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: context.tr('common_close'),
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
                        context.tr('manual_task_dialog_task_details'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: context.tr('manual_task_dialog_task_name'),
                        controller: _taskNameController,
                        validator: (value) => Validators.required(value, fieldName: context.tr('manual_task_dialog_task_name')),
                      ),
                      const SizedBox(height: 16),
                      // Priority Dropdown
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: context.tr('manual_task_dialog_priority'),
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
                                const Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Flexible(child: Text(context.tr('manual_task_dialog_low'))),
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
                                Flexible(child: Text(context.tr('manual_task_dialog_medium'))),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'High',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_upward, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Flexible(child: Text(context.tr('manual_task_dialog_high'))),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Emergency',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Flexible(child: Text(context.tr('manual_task_dialog_emergency'))),
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
                          labelText: context.tr('manual_task_dialog_phase_optional'),
                          hintText: context.tr('manual_task_dialog_default_maintenance'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(context.tr('manual_task_dialog_none_default')),
                          ),
                          DropdownMenuItem(value: 'Landscaping', child: Text(context.tr('manual_task_dialog_landscaping'))),
                          DropdownMenuItem(value: 'Planting', child: Text(context.tr('manual_task_dialog_planting'))),
                          DropdownMenuItem(value: 'Maintenance', child: Text(context.tr('manual_task_dialog_maintenance'))),
                          DropdownMenuItem(value: 'Harvesting', child: Text(context.tr('manual_task_dialog_harvesting'))),
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
                            label: context.tr('manual_task_dialog_due_date'),
                            controller: TextEditingController(
                              text: _dueDate != null
                                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                  : '',
                            ),
                            validator: (value) {
                              if (_dueDate == null) {
                                return context.tr('manual_task_dialog_please_select_due_date');
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: context.tr('manual_task_dialog_instructions_optional'),
                        controller: _instructionsController,
                        hint: context.tr('manual_task_dialog_instructions_hint'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: context.tr('manual_task_dialog_reason_optional'),
                        controller: _reasonController,
                        hint: context.tr('manual_task_dialog_reason_hint'),
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
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('common_cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleSubmit(context),
                    icon: const Icon(Icons.add_task),
                    label: Text(context.tr('manual_task_dialog_create_task')),
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

  void _handleSubmit(BuildContext context) {
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
    } else if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('manual_task_dialog_please_select_due_date')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
