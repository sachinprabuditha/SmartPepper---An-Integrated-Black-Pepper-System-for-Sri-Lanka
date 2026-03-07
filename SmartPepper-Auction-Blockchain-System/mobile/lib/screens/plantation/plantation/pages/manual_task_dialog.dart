import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
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

  Future<void> _selectDate(BuildContext context, String lang) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: lang == 'en' ? 'Select Due Date' : 'අවසන් දිනය තෝරන්න',
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

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
                      lang == 'en' ? 'Add Manual Task' : 'කාර්යයක් එක් කරන්න',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: lang == 'en' ? 'Close' : 'වසන්න',
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
                        lang == 'en' ? 'Task Details' : 'කාර්ය විස්තර',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: lang == 'en' ? 'Task Name' : 'කාර්යයේ නම',
                        controller: _taskNameController,
                        validator: (value) => Validators.required(value, fieldName: lang == 'en' ? 'Task name' : 'කාර්යයේ නම'),
                      ),
                      const SizedBox(height: 16),
                      // Priority Dropdown
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: lang == 'en' ? 'Priority' : 'ප්‍රමුඛතාවය',
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
                                Flexible(child: Text(lang == 'en' ? 'Low' : 'අඩු')),
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
                                Flexible(child: Text(lang == 'en' ? 'Medium' : 'මධ්‍යම')),
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
                                Flexible(child: Text(lang == 'en' ? 'High' : 'ඉහළ')),
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
                                Flexible(child: Text(lang == 'en' ? 'Emergency' : 'හදිසි')),
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
                          labelText: lang == 'en' ? 'Phase (Optional)' : 'අදියර (අත්‍යවශ්‍ය නොවේ)',
                          hintText: lang == 'en' ? 'Default: Maintenance' : 'පෙරනිමිය: නඩත්තුව',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(lang == 'en' ? 'None (Default)' : 'නැත (පෙරනිමිය)'),
                          ),
                          DropdownMenuItem(value: 'Landscaping', child: Text(lang == 'en' ? 'Landscaping' : 'භූමි අලංකරණය')),
                          DropdownMenuItem(value: 'Planting', child: Text(lang == 'en' ? 'Planting' : 'සිටුවීම')),
                          DropdownMenuItem(value: 'Maintenance', child: Text(lang == 'en' ? 'Maintenance' : 'නඩත්තුව')),
                          DropdownMenuItem(value: 'Harvesting', child: Text(lang == 'en' ? 'Harvesting' : 'අස්වනු නෙලීම')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPhase = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectDate(context, lang),
                        child: AbsorbPointer(
                          child: InputField(
                            label: lang == 'en' ? 'Due Date' : 'අවසන් දිනය',
                            controller: TextEditingController(
                              text: _dueDate != null
                                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                  : '',
                            ),
                            validator: (value) {
                              if (_dueDate == null) {
                                return lang == 'en' ? 'Please select a due date' : 'කරුණාකර අවසන් දිනයක් තෝරන්න';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: lang == 'en' ? 'Instructions/Steps (Optional)' : 'උපදෙස්/අදියර (අත්‍යවශ්‍ය නොවේ)',
                        controller: _instructionsController,
                        hint: lang == 'en' ? 'Detailed instructions for this task...' : 'මෙම කාර්යය සඳහා සවිස්තරාත්මක උපදෙස්...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: lang == 'en' ? 'Reason (Optional)' : 'හේතුව (අත්‍යවශ්‍ය නොවේ)',
                        controller: _reasonController,
                        hint: lang == 'en' ? 'Why is this task needed?' : 'මෙම කාර්යය අවශ්‍ය වන්නේ ඇයි?',
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
                    child: Text(lang == 'en' ? 'Cancel' : 'අවලංගු කරන්න'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleSubmit(lang),
                    icon: const Icon(Icons.add_task),
                    label: Text(lang == 'en' ? 'Create Task' : 'කාර්යය නිර්මාණය කරන්න'),
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

  void _handleSubmit(String lang) {
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
          content: Text(lang == 'en' ? 'Please select a due date' : 'කරුණාකර අවසන් දිනයක් තෝරන්න'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
