import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import '../controllers/session_controller.dart';
import '../../services/plantation_api_client.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../widgets/input_field.dart';
import '../../../../utils/validators.dart';

class EditSessionPage extends StatefulWidget {
  final String sessionId;
  final String seasonId;

  const EditSessionPage({
    super.key,
    required this.sessionId,
    required this.seasonId,
  });

  @override
  State<EditSessionPage> createState() => _EditSessionPageState();
}

class _EditSessionPageState extends State<EditSessionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sessionNameController;
  late TextEditingController _yieldController;
  late TextEditingController _areaController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;

  late Future<SessionModel> _sessionFuture;
  late SessionService _sessionService;
  late SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController();
    _yieldController = TextEditingController();
    _areaController = TextEditingController();
    _notesController = TextEditingController();

    final apiClient = PlantationApiClient();
    _sessionService = SessionService(apiClient);
    _sessionController = SessionController(_sessionService);
    _sessionFuture = _sessionService.getSessionById(widget.sessionId);
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
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('session_delete')),
        content: Text(dialogContext.tr('session_confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(dialogContext.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(dialogContext.tr('common_delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _sessionController.deleteSession(widget.sessionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('session_deleted_success')),
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
        await _sessionController.updateSession(
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
            SnackBar(
              content: Text(context.tr('session_updated_success')),
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
    return ChangeNotifierProvider.value(
      value: _sessionController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('session_edit')),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSession,
            ),
          ],
        ),
        body: FutureBuilder<SessionModel>(
          future: _sessionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                    '${context.tr('common_error')}: ${snapshot.error.toString()}'),
              );
            } else if (!snapshot.hasData) {
              return Center(child: Text(context.tr('common_no_data')));
            }

            final session = snapshot.data!;

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
            _selectedDate ??= session.date;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputField(
                      label: context.tr('session_name'),
                      controller: _sessionNameController,
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
                          DateFormat('MMM dd, yyyy').format(_selectedDate!),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: context.tr('session_yield_kg'),
                      controller: _yieldController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return Validators.number(value,
                              fieldName: context.tr('session_yield_field'));
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: context.tr('session_area_hectares'),
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return Validators.number(value,
                              fieldName: context.tr('session_area_field'));
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: context.tr('session_notes_optional'),
                      controller: _notesController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: context.tr('session_update'),
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
