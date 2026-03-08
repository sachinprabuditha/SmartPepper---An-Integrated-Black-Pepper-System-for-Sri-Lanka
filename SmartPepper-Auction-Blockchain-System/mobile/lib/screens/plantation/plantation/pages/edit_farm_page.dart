import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../controllers/plantation_controller.dart';
import '../models/farm_record_model.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../utils/validators.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class EditFarmPage extends ConsumerStatefulWidget {
  final FarmRecord farm;

  const EditFarmPage({super.key, required this.farm});

  @override
  ConsumerState<EditFarmPage> createState() => _EditFarmPageState();
}

class _EditFarmPageState extends ConsumerState<EditFarmPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _farmNameController;
  late TextEditingController _areaHectaresController;
  late TextEditingController _totalVinesController;

  DateTime? _farmStartDate;

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController(text: widget.farm.farmName);
    _areaHectaresController =
        TextEditingController(text: widget.farm.areaHectares.toString());
    _totalVinesController =
        TextEditingController(text: widget.farm.totalVines.toString());
    _farmStartDate = widget.farm.farmStartDate;
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _areaHectaresController.dispose();
    _totalVinesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String lang) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _farmStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: context.tr('plantation_select_farm_start_date'),
    );
    if (picked != null) {
      setState(() {
        _farmStartDate = picked;
      });
    }
  }

  Future<void> _handleSubmit(BuildContext context, String lang) async {
    if (_formKey.currentState!.validate() &&
        _farmStartDate != null) {
      try {
        final areaHectares = double.tryParse(_areaHectaresController.text.trim());
        final totalVines = int.tryParse(_totalVinesController.text.trim());

        if (areaHectares == null || areaHectares <= 0) {
          _showError(context.tr('plantation_validation_valid_area'));
          return;
        }
        if (totalVines == null || totalVines <= 0) {
          _showError(context.tr('plantation_validation_valid_vines'));
          return;
        }

        await ref.read(plantationControllerProvider.notifier).updateFarm(
              farmId: widget.farm.id,
              farmName: _farmNameController.text.trim(),
              farmStartDate: _farmStartDate,
              areaHectares: areaHectares,
              totalVines: totalVines,
            );

        if (mounted) {
          // Invalidate all related providers to refresh data
          ref.invalidate(farmProvider(widget.farm.id));
          ref.invalidate(farmsProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_farm_updated')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_edit_farm')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputField(
                label: context.tr('plantation_farm_name'),
                controller: _farmNameController,
                validator: (value) => Validators.required(value, fieldName: context.tr('plantation_farm_name')),
              ),
              const SizedBox(height: 16),
              // Read Only District
              InputField(
                label: context.tr('plantation_district'),
                controller: TextEditingController(text: widget.farm.district.get(lang)),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),
              
              // Read Only Soil Type
              InputField(
                label: context.tr('plantation_soil_type'),
                controller: TextEditingController(text: widget.farm.soilType.get(lang)),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),

              // Read Only Variety
              InputField(
                label: context.tr('plantation_chosen_variety'),
                controller: TextEditingController(text: widget.farm.chosenVariety.get(lang)),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),
              // Planting Date
              GestureDetector(
                onTap: () => _selectDate(context, lang),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _farmStartDate != null
                          ? '${_farmStartDate!.day}/${_farmStartDate!.month}/${_farmStartDate!.year}'
                          : '',
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('plantation_farm_start_date'),
                      hintText: context.tr('plantation_select_planting_date_short'),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (_farmStartDate == null) return context.tr('plantation_select_farm_start');
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('plantation_area_in_hectares'),
                controller: _areaHectaresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return context.tr('plantation_please_enter_area');
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) return context.tr('plantation_validation_enter_valid_area');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('plantation_total_vines'),
                controller: _totalVinesController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return context.tr('plantation_please_enter_vines');
                  final vines = int.tryParse(value);
                  if (vines == null || vines <= 0) return context.tr('plantation_please_enter_valid_number');
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: context.tr('plantation_save_changes'),
                onPressed: () => _handleSubmit(context, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
