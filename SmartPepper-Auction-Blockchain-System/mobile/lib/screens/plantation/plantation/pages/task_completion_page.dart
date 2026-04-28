import 'package:flutter/material.dart';
import '../../services/plantation_api_client.dart';
import '../services/plantation_service.dart';
import 'package:provider/provider.dart';
import '../controllers/plantation_controller.dart';
import '../models/farm_task_model.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/dropdown_field.dart';
import '../../../../utils/validators.dart';
import '../../../../providers/language_provider.dart';

class TaskCompletionPage extends StatefulWidget {
  final FarmTask task;

  const TaskCompletionPage({super.key, required this.task});

  @override
  State<TaskCompletionPage> createState() => _TaskCompletionPageState();
}

class _TaskCompletionPageState extends State<TaskCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _laborHoursController = TextEditingController();
  final _notesController = TextEditingController();
  final List<InputItemFormData> _items = [];

  late FarmTask _currentTask;
  late PlantationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        PlantationController(PlantationService(PlantationApiClient()));
    _currentTask = widget.task;

    if (_currentTask.status == 'Completed' &&
        _currentTask.inputDetails != null) {
      _laborHoursController.text =
          _currentTask.inputDetails!.laborHours.toString();
      _notesController.text = _currentTask.inputDetails!.notes ?? '';

      for (var item in _currentTask.inputDetails!.items) {
        final formData = InputItemFormData();
        formData.itemNameController.text = item.itemName;
        formData.quantityController.text = item.quantity.toString();
        formData.unitCostController.text = item.unitCostLKR?.toString() ?? '';
        formData.unit = item.unit;
        _items.add(formData);
      }
    } else {
      _laborHoursController.text = '0';
      _items.add(InputItemFormData());
    }
  }

  @override
  void dispose() {
    _laborHoursController.dispose();
    _notesController.dispose();
    for (var item in _items) {
      item.itemNameController.dispose();
      item.quantityController.dispose();
      item.unitCostController.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(InputItemFormData());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].itemNameController.dispose();
      _items[index].quantityController.dispose();
      _items[index].unitCostController.dispose();
      _items.removeAt(index);
    });
  }

  void _updateTaskData(FarmTask updatedTask) {
    setState(() {
      _currentTask = updatedTask;
    });
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        final items = <InputItem>[];
        for (var item in _items) {
          final itemName = item.itemNameController.text.trim();
          final quantityStr = item.quantityController.text.trim();
          final unitCostStr = item.unitCostController.text.trim();

          if (itemName.isNotEmpty && quantityStr.isNotEmpty) {
            final quantity = double.tryParse(quantityStr);
            if (quantity != null) {
              double? unitCost;
              if (unitCostStr.isNotEmpty) {
                unitCost = double.tryParse(unitCostStr);
              }

              items.add(InputItem(
                itemName: itemName,
                quantity: quantity,
                unitCostLKR: unitCost,
                unit: item.unit,
              ));
            }
          }
        }

        final laborHours =
            double.tryParse(_laborHoursController.text.trim()) ?? 0;

        final updatedTask = await _controller.completeTask(
          taskId: _currentTask.id,
          items: items,
          laborHours: laborHours,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        if (mounted) {
          _updateTaskData(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(context.tr('task_completion_task_marked_completed')),
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    final isCompleted = _currentTask.status == 'Completed';

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTask.taskName.get(lang)),
        actions: [
          if (_currentTask.isManual)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: context.tr('task_completion_edit_task'),
              onPressed: () => _showEditTaskDialog(context, lang),
            ),
          if (isCompleted)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: context.tr('task_completion_edit_completion_details'),
              onPressed: () => _showEditCompletionDialog(context, lang),
            ),
          if (_currentTask.isManual)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: context.tr('task_completion_delete_task'),
              onPressed: () => _showDeleteConfirmation(context, lang),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Info Card
              _buildTaskInfoCard(context, lang),
              const SizedBox(height: 24),

              if (!isCompleted) ...[
                Text(
                  context.tr('task_completion_completion_details'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('task_completion_items_used'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('task_completion_add_item')),
                    ),
                  ],
                ),
                ..._items.asMap().entries.map(
                    (entry) => _buildItemRow(context, entry.key, entry.value)),

                const SizedBox(height: 16),
                InputField(
                  label: context.tr('task_completion_labor_hours'),
                  controller: _laborHoursController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => Validators.required(value,
                      fieldName: context.tr('task_completion_labor_hours')),
                ),
                const SizedBox(height: 16),
                InputField(
                  label: context.tr('task_completion_notes_1'),
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _handleSubmit(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    context.tr('task_completion_mark_completed'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                _buildCompletionSummaryCard(context, lang),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoCard(BuildContext context, String lang) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getStatusIcon(_currentTask.status),
                const SizedBox(width: 8),
                Text(
                  _currentTask.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_currentTask.status),
                  ),
                ),
                const Spacer(),
                if (_currentTask.isManual)
                  Chip(
                    label: Text(
                      context.tr('task_completion_manual'),
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                    backgroundColor: Colors.orange[100],
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(),
            _buildDetailRow(
                context.tr('task_completion_phase'), _currentTask.phase),
            _buildDetailRow(
                context.tr('task_completion_priority'), _currentTask.priority),
            _buildDetailRow(context.tr('task_completion_due_date'),
                '${_currentTask.dueDate.day}/${_currentTask.dueDate.month}/${_currentTask.dueDate.year}'),
            if (_currentTask.reasonWhy != null &&
                _currentTask.reasonWhy!.get(lang).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('task_completion_problem_reason'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _currentTask.reasonWhy!.get(lang),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_currentTask.detailedSteps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('task_completion_detailed_instructions'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ..._currentTask.detailedSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            step.get(lang),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemRow(
      BuildContext context, int index, InputItemFormData item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InputField(
                    label: context.tr('task_completion_item_name'),
                    controller: item.itemNameController,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;

                final qtyField = InputField(
                  label: context.tr('task_completion_qty'),
                  controller: item.quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                );

                final unitField = DropdownField<String>(
                  label: context.tr('task_completion_unit'),
                  value: item.unit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'liters', child: Text('L')),
                    DropdownMenuItem(value: 'bags', child: Text('bags')),
                    DropdownMenuItem(value: 'pieces', child: Text('pieces')),
                  ],
                  onChanged: (val) => setState(() => item.unit = val!),
                );

                final costField = InputField(
                  label: context.tr('task_completion_cost_lkr'),
                  controller: item.unitCostController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: qtyField),
                          const SizedBox(width: 8),
                          Expanded(child: unitField),
                        ],
                      ),
                      const SizedBox(height: 8),
                      costField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 2, child: qtyField),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: unitField),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: costField),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSummaryCard(BuildContext context, String lang) {
    final details = _currentTask.inputDetails!;
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('task_completion_completion_summary'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const Divider(),
            if (_currentTask.dateCompleted != null)
              _buildSummaryRow(context.tr('task_completion_completed_on'),
                  '${_currentTask.dateCompleted!.day}/${_currentTask.dateCompleted!.month}/${_currentTask.dateCompleted!.year}'),
            _buildSummaryRow(context.tr('task_completion_labor_hours'),
                '${details.laborHours}'),
            if (details.notes != null)
              _buildSummaryRow(
                  context.tr('task_completion_notes'), details.notes!),
            const SizedBox(height: 16),
            Text(
              context.tr('task_completion_items_used_label'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            if (details.items.isEmpty)
              Text(
                context.tr('task_completion_no_items_recorded'),
                style: const TextStyle(color: Colors.black54),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    children: [
                      Text(context.tr('task_completion_item'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Text(context.tr('task_completion_qty'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Text(context.tr('task_completion_cost'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ],
                  ),
                  ...details.items.map((item) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(item.itemName,
                                style: const TextStyle(color: Colors.black87)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('${item.quantity} ${item.unit}',
                                style: const TextStyle(color: Colors.black87)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              item.unitCostLKR != null
                                  ? 'Rs. ${item.unitCostLKR}'
                                  : '-',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Overdue':
        return const Icon(Icons.error, color: Colors.red);
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

  void _showEditTaskDialog(BuildContext context, String lang) {
    final taskNameController =
        TextEditingController(text: _currentTask.taskName.get(lang));
    final phaseController = TextEditingController(text: _currentTask.phase);
    final reasonController =
        TextEditingController(text: _currentTask.reasonWhy?.get(lang) ?? '');
    final stepsController = TextEditingController(
      text: _currentTask.detailedSteps.map((s) => s.get(lang)).join('\n'),
    );
    String selectedPriority = _currentTask.priority;
    DateTime? selectedDate = _currentTask.dueDate;

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
                dialogContext.tr('task_completion_edit_task_dialog_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputField(
                      label: dialogContext.tr('manual_task_dialog_task_name'),
                      controller: taskNameController),
                  const SizedBox(height: 12),
                  InputField(
                      label: dialogContext.tr('task_completion_phase'),
                      controller: phaseController),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: dialogContext.tr('task_completion_priority'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Low', 'Medium', 'High', 'Emergency']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedPriority = val!),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null)
                        setDialogState(() => selectedDate = picked);
                    },
                    child: AbsorbPointer(
                      child: InputField(
                        label: dialogContext.tr('task_completion_due_date'),
                        controller: TextEditingController(
                            text: selectedDate != null
                                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                : ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputField(
                      label: dialogContext
                          .tr('task_completion_steps_one_per_line'),
                      controller: stepsController,
                      maxLines: 3),
                  const SizedBox(height: 12),
                  InputField(
                      label: dialogContext.tr('task_completion_reason'),
                      controller: reasonController,
                      maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                },
                child: Text(dialogContext.tr('common_cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (taskNameController.text.trim().isEmpty ||
                      selectedDate == null) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                            content: Text(dialogContext
                                .tr('task_completion_please_fill_required'))),
                      );
                    }
                    return;
                  }

                  try {
                    final detailedSteps = stepsController.text.trim().isEmpty
                        ? null
                        : stepsController.text
                            .trim()
                            .split('\n')
                            .where((s) => s.trim().isNotEmpty)
                            .toList();

                    final updatedTask = await _controller.updateTaskDetails(
                      taskId: _currentTask.id,
                      taskName: taskNameController.text.trim(),
                      phase: phaseController.text.trim(),
                      priority: selectedPriority,
                      dueDate: selectedDate!,
                      detailedSteps: detailedSteps,
                      reasonWhy: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    );

                    if (mounted && context.mounted) {
                      _updateTaskData(updatedTask);
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content:
                              Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(dialogContext.tr('common_save')),
              ),
            ],
          );
        },
      ),
    ).then((result) async {
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        taskNameController.dispose();
        phaseController.dispose();
        reasonController.dispose();
        stepsController.dispose();
      }

      if (result == true && mounted && context.mounted) {
        Future.microtask(() {
          if (mounted && context.mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    });
  }

  void _showEditCompletionDialog(BuildContext context, String lang) {
    if (!context.mounted) return;

    final currentInputDetails = _currentTask.inputDetails;

    final editItems = <InputItemFormData>[];
    if (currentInputDetails != null && currentInputDetails.items.isNotEmpty) {
      editItems.addAll(currentInputDetails.items.map((item) {
        return InputItemFormData()
          ..itemNameController.text = item.itemName
          ..quantityController.text = item.quantity.toString()
          ..unitCostController.text = item.unitCostLKR?.toString() ?? ''
          ..unit = item.unit;
      }));
    }

    final editLaborHoursController = TextEditingController(
      text: currentInputDetails?.laborHours.toString() ?? '0',
    );
    final editNotesController = TextEditingController(
      text: currentInputDetails?.notes ?? '',
    );

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
                dialogContext.tr('task_completion_edit_completion_details')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dialogContext.tr('task_completion_items_used'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        tooltip: dialogContext.tr('task_completion_add_item'),
                        onPressed: () {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              editItems.add(InputItemFormData());
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  ...editItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${dialogContext.tr('task_completion_item')} ${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  tooltip: dialogContext
                                      .tr('task_completion_remove_item'),
                                  onPressed: () {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        editItems.removeAt(index);
                                      });
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InputField(
                              label:
                                  dialogContext.tr('task_completion_item_name'),
                              controller: item.itemNameController,
                            ),
                            const SizedBox(height: 8),
                            // NOTE: AlertDialog uses IntrinsicWidth internally.
                            // LayoutBuilder cannot be used in that context.
                            // Use a stacked layout to avoid overflows on small screens.
                            InputField(
                              label:
                                  dialogContext.tr('task_completion_quantity'),
                              controller: item.quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownField<String>(
                              label: dialogContext.tr('task_completion_unit'),
                              value: item.unit,
                              items: const [
                                DropdownMenuItem(
                                    value: 'kg', child: Text('kg')),
                                DropdownMenuItem(
                                    value: 'liters', child: Text('L')),
                                DropdownMenuItem(
                                    value: 'bags', child: Text('bags')),
                                DropdownMenuItem(
                                    value: 'pieces', child: Text('pieces')),
                              ],
                              onChanged: (value) {
                                if (value != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    item.unit = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            InputField(
                              label: context
                                  .tr('task_completion_unit_cost_optional'),
                              controller: item.unitCostController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  InputField(
                    label: dialogContext.tr('task_completion_labor_hours'),
                    controller: editLaborHoursController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('task_completion_required');
                      }
                      final hours = double.tryParse(value);
                      if (hours == null || hours < 0) {
                        return context.tr('task_completion_invalid');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: context.tr('task_completion_notes_optional'),
                    controller: editNotesController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                },
                child: Text(dialogContext.tr('common_cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final laborHours =
                      double.tryParse(editLaborHoursController.text.trim());
                  if (laborHours == null || laborHours < 0) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                            content: Text(dialogContext.tr(
                                'task_completion_please_valid_labor_hours'))),
                      );
                    }
                    return;
                  }

                  final items = <InputItem>[];
                  for (var item in editItems) {
                    final itemName = item.itemNameController.text.trim();
                    final quantityStr = item.quantityController.text.trim();
                    final unitCostStr = item.unitCostController.text.trim();

                    if (itemName.isNotEmpty && quantityStr.isNotEmpty) {
                      final quantity = double.tryParse(quantityStr);

                      if (quantity != null && quantity >= 0) {
                        double? unitCost;
                        if (unitCostStr.isNotEmpty) {
                          final parsedCost = double.tryParse(unitCostStr);
                          if (parsedCost != null && parsedCost >= 0) {
                            unitCost = parsedCost;
                          }
                        }

                        items.add(InputItem(
                          itemName: itemName,
                          quantity: quantity,
                          unitCostLKR: unitCost,
                          unit: item.unit,
                        ));
                      }
                    }
                  }

                  try {
                    final updatedTask =
                        await _controller.updateCompletionDetails(
                      taskId: _currentTask.id,
                      items: items,
                      laborHours: laborHours,
                      notes: editNotesController.text.trim().isEmpty
                          ? null
                          : editNotesController.text.trim(),
                    );

                    if (mounted && context.mounted) {
                      _updateTaskData(updatedTask);
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content:
                              Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(dialogContext.tr('common_save')),
              ),
            ],
          );
        },
      ),
    ).then((result) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          for (var item in editItems) {
            item.itemNameController.dispose();
            item.quantityController.dispose();
            item.unitCostController.dispose();
          }
          editLaborHoursController.dispose();
          editNotesController.dispose();
        }
      });
    });
  }

  void _showDeleteConfirmation(BuildContext context, String lang) {
    if (!context.mounted) return;

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('task_completion_delete_task')),
        content: Text(
          '"${_currentTask.taskName.get(lang)}". ${dialogContext.tr('task_completion_are_you_sure_delete')}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(false);
              }
            },
            child: Text(dialogContext.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () async {
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(true);

              await Future.delayed(const Duration(milliseconds: 100));

              if (!mounted || !context.mounted) return;

              try {
                await Provider.of<PlantationController>(context, listen: false)
                    .deleteTask(_currentTask.id);

                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          context.tr('task_completion_task_deleted_success')),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dialogContext.tr('common_delete')),
          ),
        ],
      ),
    );
  }
}

class InputItemFormData {
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController unitCostController;
  String unit;

  InputItemFormData({
    TextEditingController? itemNameController,
    TextEditingController? quantityController,
    TextEditingController? unitCostController,
    this.unit = 'kg',
  })  : itemNameController = itemNameController ?? TextEditingController(),
        quantityController = quantityController ?? TextEditingController(),
        unitCostController = unitCostController ?? TextEditingController();
}
