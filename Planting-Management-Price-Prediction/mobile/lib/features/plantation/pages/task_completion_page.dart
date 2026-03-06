import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/plantation_controller.dart';
import '../models/farm_task_model.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/utils/validators.dart';
import '../../agronomy/providers/language_provider.dart';

class TaskCompletionPage extends ConsumerStatefulWidget {
  final FarmTask task;

  const TaskCompletionPage({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskCompletionPage> createState() => _TaskCompletionPageState();
}

class _TaskCompletionPageState extends ConsumerState<TaskCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _laborHoursController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<InputItemFormData> _items = [];

  // Store task in state so we can update it after edits
  late FarmTask _currentTask;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _isCompleted = _currentTask.status == 'Completed';
    
    // Load existing data if task is completed
    // Note: Based on DB structure, InputDetails should always exist for completed tasks
    // (even if items array is empty)
    if (_isCompleted) {
      if (_currentTask.inputDetails != null) {
        final inputDetails = _currentTask.inputDetails!;
        _laborHoursController.text = inputDetails.laborHours.toString();
        _notesController.text = inputDetails.notes ?? '';
        
        // Load items (can be empty array)
        for (var item in inputDetails.items) {
          _items.add(InputItemFormData()
            ..itemNameController.text = item.itemName
            ..quantityController.text = item.quantity.toString()
            ..unitCostController.text = item.unitCostLKR?.toString() ?? ''
            ..unit = item.unit);
        }
      } else {
        // Fallback: Task is completed but InputDetails is null (shouldn't happen, but handle it)
        _laborHoursController.text = '0';
        _notesController.text = '';
      }
    }
  }

  void _updateTaskData(FarmTask updatedTask) {
    setState(() {
      _currentTask = updatedTask;
      _isCompleted = _currentTask.status == 'Completed';
      
      // Update controllers with new data
      if (_isCompleted && _currentTask.inputDetails != null) {
        final inputDetails = _currentTask.inputDetails!;
        _laborHoursController.text = inputDetails.laborHours.toString();
        _notesController.text = inputDetails.notes ?? '';
        
        // Clear and reload items
        for (var item in _items) {
          item.itemNameController.dispose();
          item.quantityController.dispose();
          item.unitCostController.dispose();
        }
        _items.clear();
        
        for (var item in inputDetails.items) {
          _items.add(InputItemFormData()
            ..itemNameController.text = item.itemName
            ..quantityController.text = item.quantity.toString()
            ..unitCostController.text = item.unitCostLKR?.toString() ?? ''
            ..unit = item.unit);
        }
      }
    });
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.itemNameController.dispose();
      item.quantityController.dispose();
      item.unitCostController.dispose();
    }
    _laborHoursController.dispose();
    _notesController.dispose();
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

  Future<void> _handleSubmit(String lang) async {
    if (_formKey.currentState!.validate()) {
      // Validate labor hours (required)
      final laborHours = double.tryParse(_laborHoursController.text.trim());
      if (laborHours == null || laborHours < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'en' ? 'Please enter valid labor hours' : 'කරුණාකර නිවැරදි වැඩ කරන පැය ගණන ඇතුලත් කරන්න'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // Include items - unit cost is optional
        final items = <InputItem>[];
        for (var item in _items) {
          final itemName = item.itemNameController.text.trim();
          final quantityStr = item.quantityController.text.trim();
          final unitCostStr = item.unitCostController.text.trim();
          
          // Item name and quantity are required, unit cost is optional
          if (itemName.isNotEmpty && quantityStr.isNotEmpty) {
            final quantity = double.tryParse(quantityStr);
            
            if (quantity != null && quantity >= 0) {
              // Parse unit cost if provided, otherwise null
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
                unitCostLKR: unitCost, // Can be null
                unit: item.unit,
              ));
            }
          }
        }

        final updatedTask = await ref.read(plantationControllerProvider.notifier).completeTask(
              taskId: _currentTask.id,
              items: items, // Can be empty list
              laborHours: laborHours,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

        // Update the task data to show completion details immediately
        if (mounted) {
          _updateTaskData(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang == 'en' ? 'Task completed successfully!' : 'කාර්යය සාර්ථකව සම්පූර්ණ කරන ලදී!'),
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

  // Determine which actions are allowed
  bool get _canEditTaskDetails => widget.task.isManual && !_isCompleted;
  bool get _canEditCompletion => _isCompleted;
  bool get _canDelete => widget.task.isManual && !_isCompleted;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCompleted 
            ? (lang == 'en' ? 'Task Details' : 'කාර්ය විස්තර') 
            : (lang == 'en' ? 'Complete Task' : 'කාර්යය සම්පූර්ණ කරන්න')),
        actions: [
          // Edit task details button (manual tasks only, before completion)
          if (_canEditTaskDetails)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: lang == 'en' ? 'Edit Task Details' : 'කාර්ය විස්තර සංස්කරණය කරන්න',
              onPressed: () => _showEditTaskDialog(context, lang),
            ),
          // Edit completion details button (both types, after completion)
          if (_canEditCompletion)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: lang == 'en' ? 'Edit Completion Details' : 'සම්පූර්ණ කිරීම් විස්තර සංස්කරණය කරන්න',
              onPressed: () => _showEditCompletionDialog(context, lang),
            ),
          // Delete button (manual tasks only, before completion)
          if (_canDelete)
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: _isCompleted ? Colors.green[50] : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentTask.taskName.get(lang),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (_isCompleted)
                        Chip(
                          label: Text(lang == 'en' ? 'Completed' : 'සම්පූර්ණයි'),
                          backgroundColor: Colors.green,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              // Display completion date if completed
              if (_isCompleted && _currentTask.dateCompleted != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          lang == 'en' 
                            ? 'Completed on: ${_currentTask.dateCompleted!.day}/${_currentTask.dateCompleted!.month}/${_currentTask.dateCompleted!.year}'
                            : 'සම්පූර්ණ කරන ලද්දේ: ${_currentTask.dateCompleted!.day}/${_currentTask.dateCompleted!.month}/${_currentTask.dateCompleted!.year}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Display instructional details if available
              if (_currentTask.detailedSteps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.green[50],
                  child: ExpansionTile(
                    leading: const Icon(Icons.info_outline, color: Colors.green),
                    title: Text(
                      lang == 'en' ? 'Task Instructions' : 'කාර්යය උපදෙස්',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _currentTask.detailedSteps.map((step) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                    Expanded(
                                      child: Text(
                                        step.get(lang),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_currentTask.reasonWhy != null && _currentTask.reasonWhy!.get(lang).isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == 'en' ? 'Why this task?' : 'මෙම කාර්යය කුමකටද?',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentTask.reasonWhy!.get(lang),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Display completion details if task is already completed
              if (_isCompleted) ...[
                const SizedBox(height: 24),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  lang == 'en' ? 'Completion Details' : 'සම්පූර්ණ කිරීම් විස්තර',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Items Used
                if (_currentTask.inputDetails != null && _currentTask.inputDetails!.items.isNotEmpty) ...[
                  Text(
                    lang == 'en' ? 'Items Used' : 'භාවිතා කරන ලද අයිතම',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ..._currentTask.inputDetails!.items.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Text('${lang == 'en' ? 'Quantity' : 'ප්‍රමාණය'}: ${item.quantity} ${item.unit}'),
                                Text(item.unitCostLKR != null 
                                  ? '${lang == 'en' ? 'Unit Cost' : 'ඒකක පිරිවැය'}: LKR ${item.unitCostLKR!.toStringAsFixed(2)}'
                                  : (lang == 'en' ? 'Unit Cost: Not specified' : 'ඒකක පිරිවැය: සඳහන් කර නොමැත')),
                              ],
                            ),
                            if (item.unitCostLKR != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                lang == 'en' 
                                  ? 'Total: LKR ${(item.quantity * item.unitCostLKR!).toStringAsFixed(2)}'
                                  : 'එකතුව: රුපියල් ${(item.quantity * item.unitCostLKR!).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ] else if (_currentTask.inputDetails == null || _currentTask.inputDetails!.items.isEmpty) ...[
                  // Show message if no items
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang == 'en' 
                                ? 'No items recorded yet. Use "Edit Completion Details" to add items.'
                                : 'තවමත් අයිතම කිසිවක් වාර්තා කර නොමැත. "සම්පූර්ණ කිරීම් විස්තර සංස්කරණය කරන්න" භාවිතා කර අයිතම එකතු කරන්න.',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Labor Hours
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lang == 'en' ? 'Labor Hours:' : 'වැඩ කරන පැය ගණන:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _currentTask.inputDetails?.laborHours.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notes
                if (_currentTask.inputDetails != null && _currentTask.inputDetails!.notes != null && _currentTask.inputDetails!.notes!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'en' ? 'Notes:' : 'සටහන්:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_currentTask.inputDetails!.notes!),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else ...[
              // Show form if not completed
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lang == 'en' ? 'Items Used (Optional)' : 'භාවිතා කරන ලද අයිතම (අත්‍යවශ්‍ය නොවේ)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _addItem,
                    tooltip: lang == 'en' ? 'Add Item' : 'අයිතමයක් එක් කරන්න',
                  ),
                ],
              ),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    lang == 'en' 
                      ? 'No items added. You can add items to track costs, or skip this section.'
                      : 'අයිතම කිසිවක් එක් කර නොමැත. පිරිවැය නිරීක්ෂණය කිරීමට ඔබට අයිතම එකතු කළ හැකිය, නැතහොත් මෙම කොටස මඟ හැරිය හැකිය.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              const SizedBox(height: 8),
              ...List.generate(_items.length, (index) {
                return _buildItemCard(index, lang);
              }),
              const SizedBox(height: 16),
              InputField(
                label: lang == 'en' ? 'Labor Hours' : 'වැඩ කරන පැය ගණන',
                controller: _laborHoursController,
                hint: lang == 'en' ? 'e.g., 8.5' : 'උදා: 8.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang == 'en' ? 'Please enter labor hours' : 'කරුණාකර වැඩ කරන පැය ගණන ඇතුලත් කරන්න';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours < 0) {
                    return lang == 'en' ? 'Please enter valid labor hours' : 'කරුණාකර නිවැරදි වැඩ කරන පැය ගණන ඇතුලත් කරන්න';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: lang == 'en' ? 'Notes (Optional)' : 'සටහන් (අත්‍යවශ්‍ය නොවේ)',
                controller: _notesController,
                hint: lang == 'en' ? 'Additional notes about this task...' : 'මෙම කාර්යය පිළිබඳ අමතර සටහන්...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: lang == 'en' ? 'Mark as Completed' : 'සම්පූර්ණ ලෙස සලකුණු කරන්න',
                onPressed: () => _handleSubmit(lang),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, String lang) {
    final item = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang == 'en' ? 'Item ${index + 1}' : 'අයිතමය ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                  tooltip: lang == 'en' ? 'Remove Item' : 'අයිතමය ඉවත් කරන්න',
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputField(
              label: lang == 'en' ? 'Item Name (Optional)' : 'අයිතමයේ නම (අත්‍යවශ්‍ය නොවේ)',
              controller: item.itemNameController,
              hint: lang == 'en' ? 'e.g., NPK 15:15:15, Pesticide X' : 'උදා: NPK 15:15:15, පළිබෝධනාශක X',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InputField(
                    label: lang == 'en' ? 'Quantity (Optional)' : 'ප්‍රමාණය (අත්‍යවශ්‍ය නොවේ)',
                    controller: item.quantityController,
                    hint: lang == 'en' ? 'e.g., 50.5' : 'උදා: 50.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      // Only validate if value is provided
                      if (value != null && value.isNotEmpty) {
                        final qty = double.tryParse(value);
                        if (qty == null || qty < 0) {
                          return lang == 'en' ? 'Invalid' : 'අවලංගුයි';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.unit,
                    decoration: InputDecoration(
                      labelText: lang == 'en' ? 'Unit' : 'ඒකකය',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'liters', child: Text('L')),
                      DropdownMenuItem(value: 'bags', child: Text('bags')),
                      DropdownMenuItem(value: 'pieces', child: Text('pieces')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        item.unit = value ?? 'kg';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputField(
              label: lang == 'en' ? 'Unit Cost (LKR) (Optional)' : 'ඒකක පිරිවැය (රුපියල්) (අත්‍යවශ්‍ය නොවේ)',
              controller: item.unitCostController,
              hint: lang == 'en' ? 'e.g., 500.00' : 'උදා: 500.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                // Only validate if value is provided
                if (value != null && value.isNotEmpty) {
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) {
                    return lang == 'en' ? 'Invalid' : 'අවලංගුයි';
                  }
                }
                return null;
              },
            ),
            if (item.quantityController.text.isNotEmpty &&
                item.unitCostController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  lang == 'en' ? 'Total: LKR ${_calculateTotal(item)}' : 'එකතුව: රුපියල් ${_calculateTotal(item)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _calculateTotal(InputItemFormData item) {
    final quantity = double.tryParse(item.quantityController.text);
    final cost = double.tryParse(item.unitCostController.text);
    if (quantity != null && cost != null) {
      return (quantity * cost).toStringAsFixed(2);
    }
    return '0.00';
  }

  void _showEditTaskDialog(BuildContext context, String lang) {
    if (!context.mounted) return;
    
    final taskNameController = TextEditingController(text: _currentTask.taskName.get(lang));
    final phaseController = TextEditingController(text: _currentTask.phase);
    String selectedPriority = _currentTask.priority;
    DateTime? selectedDate = _currentTask.dueDate;
    final reasonController = TextEditingController(text: _currentTask.reasonWhy?.get(lang) ?? '');
    final stepsController = TextEditingController(text: _currentTask.detailedSteps.map((s) => s.get(lang)).join('\n'));

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(lang == 'en' ? 'Edit Task Details' : 'කාර්ය විස්තර සංස්කරණය කරන්න'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputField(
                    label: lang == 'en' ? 'Task Name' : 'කාර්යයේ නම',
                    controller: taskNameController,
                    validator: (value) => Validators.required(value, fieldName: lang == 'en' ? 'Task name' : 'කාර්යයේ නම'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: widget.task.phase,
                    decoration: InputDecoration(
                      labelText: lang == 'en' ? 'Phase' : 'අදියර',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Landscaping', child: Text(lang == 'en' ? 'Landscaping' : 'භූමි අලංකරණය')),
                      DropdownMenuItem(value: 'Planting', child: Text(lang == 'en' ? 'Planting' : 'සිටුවීම')),
                      DropdownMenuItem(value: 'Maintenance', child: Text(lang == 'en' ? 'Maintenance' : 'නඩත්තුව')),
                      DropdownMenuItem(value: 'Harvesting', child: Text(lang == 'en' ? 'Harvesting' : 'අස්වනු නෙලීම')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          phaseController.text = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: lang == 'en' ? 'Priority' : 'ප්‍රමුඛතාවය',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Low', child: Text(lang == 'en' ? 'Low' : 'අඩු')),
                      DropdownMenuItem(value: 'Medium', child: Text(lang == 'en' ? 'Medium' : 'මධ්‍යම')),
                      DropdownMenuItem(value: 'High', child: Text(lang == 'en' ? 'High' : 'ඉහළ')),
                      DropdownMenuItem(value: 'Emergency', child: Text(lang == 'en' ? 'Emergency' : 'හදිසි')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedPriority = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null && dialogContext.mounted) {
                        setDialogState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: InputField(
                        label: lang == 'en' ? 'Due Date' : 'අවසන් දිනය',
                        controller: TextEditingController(
                          text: selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : '',
                        ),
                        validator: (value) {
                          if (selectedDate == null) {
                            return lang == 'en' ? 'Please select a due date' : 'කරුණාකර අවසන් දිනයක් තෝරන්න';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: lang == 'en' ? 'Reason (Optional)' : 'හේතුව (අත්‍යවශ්‍ය නොවේ)',
                    controller: reasonController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: lang == 'en' ? 'Detailed Steps (Optional, one per line)' : 'සවිස්තරාත්මක පියවර (අත්‍යවශ්‍ය නොවේ, පේළියකට එක බැගින්)',
                    controller: stepsController,
                    maxLines: 4,
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

                    // selectedDate is guaranteed to be non-null due to validation above
                    final updatedTask = await ref.read(plantationControllerProvider.notifier).updateTaskDetails(
                          taskId: _currentTask.id,
                          taskName: taskNameController.text.trim(),
                          phase: phaseController.text.trim(),
                          priority: selectedPriority,
                          dueDate: selectedDate!, // Non-null assertion safe due to validation
                          detailedSteps: detailedSteps,
                          reasonWhy: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                        );

                    // Update the task data in the parent widget
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
      // Wait for dialog to fully close and widget tree to settle
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Cleanup controllers - only if widget is still mounted
      if (mounted) {
        try {
          taskNameController.dispose();
          phaseController.dispose();
          reasonController.dispose();
          stepsController.dispose();
        } catch (e) {
          // Controllers may already be disposed, ignore
        }
      }

      // Use microtask to ensure navigation happens after current frame
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
    
    // Get current input details or use defaults
    final currentInputDetails = _currentTask.inputDetails;
    
    // Create a copy of current items for editing (handle null or empty items)
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
    // If no items exist, start with empty list (user can add items)

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
                                        // Don't dispose here - controllers are still attached to widgets
                                        // They will be disposed when dialog closes
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
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: InputField(
                                    label: lang == 'en' ? 'Quantity' : 'ප්‍රමාණය',
                                    controller: item.quantityController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: item.unit,
                                    decoration: InputDecoration(
                                      labelText: lang == 'en' ? 'Unit' : 'ඒකකය',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                      isDense: true,
                                    ),
                                    isExpanded: true,
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
                                ),
                              ],
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

                  // Include items - unit cost is optional
                  final items = <InputItem>[];
                  for (var item in editItems) {
                    final itemName = item.itemNameController.text.trim();
                    final quantityStr = item.quantityController.text.trim();
                    final unitCostStr = item.unitCostController.text.trim();

                    // Item name and quantity are required, unit cost is optional
                    if (itemName.isNotEmpty && quantityStr.isNotEmpty) {
                      final quantity = double.tryParse(quantityStr);

                      if (quantity != null && quantity >= 0) {
                        // Parse unit cost if provided, otherwise null
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
                          unitCostLKR: unitCost, // Can be null
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

                    // Update the task data in the parent widget
                    if (mounted && context.mounted) {
                      _updateTaskData(updatedTask);
                    }

                    // Close dialog
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
      // Cleanup controllers after dialog is closed
      // Use a delayed future to ensure dialog is fully closed
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          try {
            for (var item in editItems) {
              item.itemNameController.dispose();
              item.quantityController.dispose();
              item.unitCostController.dispose();
            }
            editLaborHoursController.dispose();
            editNotesController.dispose();
          } catch (e) {
            // Ignore disposal errors - controllers may already be disposed
          }
        }
      });

      // Don't pop navigation here - let the parent handle it
      // The parent's .then() callback will handle refresh when result is true
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
              
              // Wait for dialog to close
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
