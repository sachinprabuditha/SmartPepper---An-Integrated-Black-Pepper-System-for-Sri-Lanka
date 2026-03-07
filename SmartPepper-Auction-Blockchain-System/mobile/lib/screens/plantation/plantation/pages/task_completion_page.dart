import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../controllers/plantation_controller.dart';
import '../models/farm_task_model.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/dropdown_field.dart';
import '../../../../utils/validators.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/language_picker_button.dart';

class TaskCompletionPage extends ConsumerStatefulWidget {
  final FarmTask task;

  const TaskCompletionPage({super.key, required this.task});

  @override
  ConsumerState<TaskCompletionPage> createState() => _TaskCompletionPageState();
}

class _TaskCompletionPageState extends ConsumerState<TaskCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _laborHoursController = TextEditingController();
  final _notesController = TextEditingController();
  final List<InputItemFormData> _items = [];

  late FarmTask _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    
    if (_currentTask.status == 'Completed' && _currentTask.inputDetails != null) {
      _laborHoursController.text = _currentTask.inputDetails!.laborHours.toString();
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

  Future<void> _handleSubmit(String lang) async {
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

        final laborHours = double.tryParse(_laborHoursController.text.trim()) ?? 0;

        final updatedTask = await ref.read(plantationControllerProvider.notifier).completeTask(
              taskId: _currentTask.id,
              items: items,
              laborHours: laborHours,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );

        if (mounted) {
          _updateTaskData(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang == 'en' ? 'Task marked as completed!' : 'කාර්යය සාර්ථකව නිම කරන ලදී!'),
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
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;
    final isCompleted = _currentTask.status == 'Completed';

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTask.taskName.get(lang)),
        actions: [
          const LanguagePickerButton(),
          if (_currentTask.isManual)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: lang == 'en' ? 'Edit Task' : 'කාර්යය සංස්කරණය කරන්න',
              onPressed: () => _showEditTaskDialog(context, lang),
            ),
          if (isCompleted)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: lang == 'en' ? 'Edit Completion Details' : 'විස්තර සංස්කරණය කරන්න',
              onPressed: () => _showEditCompletionDialog(context, lang),
            ),
          if (_currentTask.isManual)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: lang == 'en' ? 'Delete Task' : 'කාර්යය මකන්න',
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
                  lang == 'en' ? 'Completion Details' : 'සම්පූර්ණ කිරීමේ විස්තර',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Items Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang == 'en' ? 'Items Used' : 'භාවිතා කළ අයිතම',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: Text(lang == 'en' ? 'Add Item' : 'අයිතමයක් එක් කරන්න'),
                    ),
                  ],
                ),
                ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value, lang)),
                
                const SizedBox(height: 16),
                InputField(
                  label: lang == 'en' ? 'Labor Hours' : 'වැඩ කරන පැය ගණන',
                  controller: _laborHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => Validators.required(value, fieldName: lang == 'en' ? 'Labor hours' : 'පැය ගණන'),
                ),
                const SizedBox(height: 16),
                InputField(
                  label: lang == 'en' ? 'Notes (Optional)' : 'සටහන් (අත්‍යවශ්‍ය නොවේ)',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _handleSubmit(lang),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    lang == 'en' ? 'Mark as Completed' : 'සම්පූර්ණයි ලෙස සලකුණු කරන්න',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      lang == 'en' ? 'Manual' : 'අතින් සැකසූ',
                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                    backgroundColor: Colors.orange[100],
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(),
            _buildDetailRow(lang == 'en' ? 'Phase' : 'අදියර', _currentTask.phase),
            _buildDetailRow(lang == 'en' ? 'Priority' : 'ප්‍රමුඛතාවය', _currentTask.priority),
            _buildDetailRow(lang == 'en' ? 'Due Date' : 'අවසන් දිනය', '${_currentTask.dueDate.day}/${_currentTask.dueDate.month}/${_currentTask.dueDate.year}'),
            
            if (_currentTask.reasonWhy != null && _currentTask.reasonWhy!.get(lang).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                lang == 'en' ? 'Problem/Reason:' : 'ගැටළුව/හේතුව:',
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
                lang == 'en' ? 'Detailed Instructions:' : 'සවිස්තරාත්මක උපදෙස්:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ..._currentTask.detailedSteps.map((step) => Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
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
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, InputItemFormData item, String lang) {
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
                    label: lang == 'en' ? 'Item Name' : 'අයිතමයේ නම',
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
                  label: lang == 'en' ? 'Qty' : 'ප්‍රමාණය',
                  controller: item.quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                );

                final unitField = DropdownField<String>(
                  label: lang == 'en' ? 'Unit' : 'ඒකකය',
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
                  label: lang == 'en' ? 'Cost (LKR)' : 'පිරිවැය (රු.)',
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
              lang == 'en' ? 'Completion Summary' : 'සම්පූර්ණ කිරීමේ සාරාංශය',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
            const Divider(),
            if (_currentTask.dateCompleted != null)
              _buildSummaryRow(lang == 'en' ? 'Completed On' : 'සම්පූර්ණ කළ දිනය', 
                  '${_currentTask.dateCompleted!.day}/${_currentTask.dateCompleted!.month}/${_currentTask.dateCompleted!.year}'),
            _buildSummaryRow(lang == 'en' ? 'Labor Hours' : 'වැඩ කළ පැය ගණන', '${details.laborHours}'),
            if (details.notes != null)
              _buildSummaryRow(lang == 'en' ? 'Notes' : 'සටහන්', details.notes!),
            
            const SizedBox(height: 16),
            Text(
              lang == 'en' ? 'Items Used:' : 'භාවිතා කළ අයිතම:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            if (details.items.isEmpty)
              Text(
                lang == 'en' ? 'No items recorded' : 'අයිතම වාර්තා වී නොමැත',
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
                      Text(lang == 'en' ? 'Item' : 'අයිතමය', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(lang == 'en' ? 'Qty' : 'ප්‍රමාණය', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(lang == 'en' ? 'Cost' : 'පිරිවැය', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  ...details.items.map((item) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(item.itemName, style: const TextStyle(color: Colors.black87)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${item.quantity} ${item.unit}', style: const TextStyle(color: Colors.black87)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          item.unitCostLKR != null ? 'Rs. ${item.unitCostLKR}' : '-',
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Completed': return const Icon(Icons.check_circle, color: Colors.green);
      case 'Overdue': return const Icon(Icons.error, color: Colors.red);
      default: return const Icon(Icons.schedule, color: Colors.blue);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'Overdue': return Colors.red;
      default: return Colors.blue;
    }
  }

  void _showEditTaskDialog(BuildContext context, String lang) {
    final taskNameController = TextEditingController(text: _currentTask.taskName.get(lang));
    final phaseController = TextEditingController(text: _currentTask.phase);
    final reasonController = TextEditingController(text: _currentTask.reasonWhy?.get(lang) ?? '');
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
            title: Text(lang == 'en' ? 'Edit Task' : 'කාර්ය සංස්කරණය'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputField(label: lang == 'en' ? 'Task Name' : 'කාර්යයේ නම', controller: taskNameController),
                  const SizedBox(height: 12),
                  InputField(label: lang == 'en' ? 'Phase' : 'අදියර', controller: phaseController),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: lang == 'en' ? 'Priority' : 'ප්‍රමුඛතාවය',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Low', 'Medium', 'High', 'Emergency'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setDialogState(() => selectedPriority = val!),
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
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                    child: AbsorbPointer(
                      child: InputField(
                        label: lang == 'en' ? 'Due Date' : 'අවසන් දිනය',
                        controller: TextEditingController(text: selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputField(label: lang == 'en' ? 'Steps (One per line)' : 'පියවර (පේළියකට එකක්)', controller: stepsController, maxLines: 3),
                  const SizedBox(height: 12),
                  InputField(label: lang == 'en' ? 'Reason' : 'හේතුව', controller: reasonController, maxLines: 2),
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
                child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (taskNameController.text.trim().isEmpty || selectedDate == null) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(lang == 'en' ? 'Please fill all required fields' : 'කරුණාකර අවශ්‍ය සියලුම ක්ෂේත්‍ර පුරවන්න')),
                      );
                    }
                    return;
                  }

                  try {
                    final detailedSteps = stepsController.text.trim().isEmpty
                        ? null
                        : stepsController.text.trim().split('\n').where((s) => s.trim().isNotEmpty).toList();

                    final updatedTask = await ref.read(plantationControllerProvider.notifier).updateTaskDetails(
                          taskId: _currentTask.id,
                          taskName: taskNameController.text.trim(),
                          phase: phaseController.text.trim(),
                          priority: selectedPriority,
                          dueDate: selectedDate!,
                          detailedSteps: detailedSteps,
                          reasonWhy: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
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
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(lang == 'en' ? 'Save' : 'සුරකින්න'),
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
            title: Text(lang == 'en' ? 'Edit Completion Details' : 'සම්පූර්ණ කිරීම් විස්තර සංස්කරණය කරන්න'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lang == 'en' ? 'Items Used' : 'භාවිතා කරන ලද අයිතම',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        tooltip: lang == 'en' ? 'Add Item' : 'අයිතමයක් එක් කරන්න',
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
                                    lang == 'en' ? 'Item ${index + 1}' : 'අයිතමය ${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  tooltip: lang == 'en' ? 'Remove Item' : 'අයිතමය ඉවත් කරන්න',
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
                              label: lang == 'en' ? 'Item Name' : 'අයිතමයේ නම',
                              controller: item.itemNameController,
                            ),
                            const SizedBox(height: 8),
                            // NOTE: AlertDialog uses IntrinsicWidth internally.
                            // LayoutBuilder cannot be used in that context.
                            // Use a stacked layout to avoid overflows on small screens.
                            InputField(
                              label: lang == 'en' ? 'Quantity' : 'ප්‍රමාණය',
                              controller: item.quantityController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownField<String>(
                              label: lang == 'en' ? 'Unit' : 'ඒකකය',
                              value: item.unit,
                              items: const [
                                DropdownMenuItem(value: 'kg', child: Text('kg')),
                                DropdownMenuItem(value: 'liters', child: Text('L')),
                                DropdownMenuItem(value: 'bags', child: Text('bags')),
                                DropdownMenuItem(value: 'pieces', child: Text('pieces')),
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
                              label: lang == 'en' ? 'Unit Cost (LKR) (Optional)' : 'ඒකක පිරිවැය (රුපියල්) (අත්‍යවශ්‍ය නොවේ)',
                              controller: item.unitCostController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  InputField(
                    label: lang == 'en' ? 'Labor Hours' : 'වැඩ කරන පැය ගණන',
                    controller: editLaborHoursController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return lang == 'en' ? 'Required' : 'අත්‍යවශ්‍යයි';
                      }
                      final hours = double.tryParse(value);
                      if (hours == null || hours < 0) {
                        return lang == 'en' ? 'Invalid' : 'අවලංගුයි';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: lang == 'en' ? 'Notes (Optional)' : 'සටහන් (අත්‍යවශ්‍ය නොවේ)',
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
                child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final laborHours = double.tryParse(editLaborHoursController.text.trim());
                  if (laborHours == null || laborHours < 0) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(lang == 'en' ? 'Please enter valid labor hours' : 'කරුණාකර නිවැරදි වැඩ කරන පැය ගණන ඇතුලත් කරන්න')),
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
                    final updatedTask = await ref.read(plantationControllerProvider.notifier).updateCompletionDetails(
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
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(lang == 'en' ? 'Save' : 'සුරකින්න'),
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
        title: Text(lang == 'en' ? 'Delete Task' : 'කාර්යය මකන්න'),
        content: Text(
          lang == 'en' 
            ? 'Are you sure you want to delete "${_currentTask.taskName.get(lang)}"? This action cannot be undone.'
            : '"${_currentTask.taskName.get(lang)}" කාර්යය මකා දැමීමට ඔබට විශ්වාසද? මෙම ක්‍රියාව ආපසු හැරවිය නොහැක.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(false);
              }
            },
            child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
          ),
          TextButton(
            onPressed: () async {
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(true);
              
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (!mounted || !context.mounted) return;
              
              try {
                await ref.read(plantationControllerProvider.notifier).deleteTask(_currentTask.id);
                
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang == 'en' ? 'Task deleted successfully' : 'කාර්යය සාර්ථකව මකා දමන ලදී'),
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
            child: Text(lang == 'en' ? 'Delete' : 'මකන්න'),
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
