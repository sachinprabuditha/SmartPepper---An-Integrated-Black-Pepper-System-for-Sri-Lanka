import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/session_controller.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/utils/validators.dart';

class CreateSessionPage extends ConsumerStatefulWidget {
  final String seasonId;

  const CreateSessionPage({super.key, required this.seasonId});

  @override
  ConsumerState<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends ConsumerState<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  final _yieldController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(sessionControllerProvider(widget.seasonId).notifier).createSession(
              sessionName: _sessionNameController.text.trim(),
              date: _selectedDate,
              yieldKg: double.parse(_yieldController.text),
              areaHarvested: double.parse(_areaController.text),
              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session created successfully'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputField(
                label: 'Session Name',
                controller: _sessionNameController,
                validator: (value) => Validators.required(value, fieldName: 'Session name'),
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
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Yield (kg)',
                controller: _yieldController,
                keyboardType: TextInputType.number,
                validator: (value) => Validators.number(value, fieldName: 'Yield'),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Area Harvested (hectares)',
                controller: _areaController,
                keyboardType: TextInputType.number,
                validator: (value) => Validators.number(value, fieldName: 'Area harvested'),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Notes (optional)',
                controller: _notesController,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create Session',
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

