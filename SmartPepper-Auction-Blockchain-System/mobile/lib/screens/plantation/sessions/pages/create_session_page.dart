import 'package:flutter/material.dart';
import '../controllers/session_controller.dart';
import '../services/session_service.dart';
import '../../services/plantation_api_client.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../localization/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../utils/validators.dart';

class CreateSessionPage extends StatefulWidget {
  final String seasonId;

  const CreateSessionPage({super.key, required this.seasonId});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  final _yieldController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController =
        SessionController(SessionService(PlantationApiClient()));
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
        await _sessionController.createSession(
          seasonId: widget.seasonId,
          sessionName: _sessionNameController.text.trim(),
          date: _selectedDate,
          yieldKg: double.parse(_yieldController.text),
          areaHarvested: double.parse(_areaController.text),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('session_created_success')),
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
        title: Text(context.tr('session_create')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputField(
                label: context.tr('session_name'),
                controller: _sessionNameController,
                validator: (value) => Validators.required(value,
                    fieldName: context.tr('session_name')),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.tr('session_date'),
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
                label: context.tr('session_yield_kg'),
                controller: _yieldController,
                keyboardType: TextInputType.number,
                validator: (value) => Validators.number(value,
                    fieldName: context.tr('session_yield_field')),
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('session_area_hectares'),
                controller: _areaController,
                keyboardType: TextInputType.number,
                validator: (value) => Validators.number(value,
                    fieldName: context.tr('session_area_field')),
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('session_notes_optional'),
                controller: _notesController,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: context.tr('session_create'),
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
