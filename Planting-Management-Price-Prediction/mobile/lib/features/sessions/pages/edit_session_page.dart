import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/session_controller.dart';
import '../models/session_model.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/utils/validators.dart';

class EditSessionPage extends ConsumerStatefulWidget {
  final String sessionId;
  final String seasonId;

  const EditSessionPage({
    super.key,
    required this.sessionId,
    required this.seasonId,
  });

  @override
  ConsumerState<EditSessionPage> createState() => _EditSessionPageState();
}

class _EditSessionPageState extends ConsumerState<EditSessionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sessionNameController;
  late TextEditingController _yieldController;
  late TextEditingController _areaController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController();
    _yieldController = TextEditingController();
    _areaController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _yieldController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(sessionControllerProvider(widget.seasonId).notifier).deleteSession(widget.sessionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session deleted successfully'),
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

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(sessionControllerProvider(widget.seasonId).notifier).updateSession(
              sessionId: widget.sessionId,
              sessionName: _sessionNameController.text.trim().isNotEmpty
                  ? _sessionNameController.text.trim()
                  : null,
              date: _selectedDate,
              yieldKg: _yieldController.text.isNotEmpty
                  ? double.parse(_yieldController.text)
                  : null,
              areaHarvested: _areaController.text.isNotEmpty
                  ? double.parse(_areaController.text)
                  : null,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session updated successfully'),
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
    final sessionAsync = ref.watch(sessionProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSession,
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) {
          if (_sessionNameController.text.isEmpty) {
            _sessionNameController.text = session.sessionName;
          }
          if (_yieldController.text.isEmpty) {
            _yieldController.text = session.yieldKg.toString();
          }
          if (_areaController.text.isEmpty) {
            _areaController.text = session.areaHarvested.toString();
          }
          if (_notesController.text.isEmpty && session.notes != null) {
            _notesController.text = session.notes!;
          }
          if (_selectedDate == null) {
            _selectedDate = session.date;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InputField(
                    label: 'Session Name',
                    controller: _sessionNameController,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate!),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Yield (kg)',
                    controller: _yieldController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        return Validators.number(value, fieldName: 'Yield');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Area Harvested (hectares)',
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        return Validators.number(value, fieldName: 'Area harvested');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: 'Notes (optional)',
                    controller: _notesController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Update Session',
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }
}

