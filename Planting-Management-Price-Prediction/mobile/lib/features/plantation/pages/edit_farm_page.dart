import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/plantation_controller.dart';
import '../models/farm_record_model.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/network/api_client.dart';



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
    // District and variety will be set after districts load
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _areaHectaresController.dispose();
    _totalVinesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _farmStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Farm Start Date',
    );
    if (picked != null) {
      setState(() {
        _farmStartDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() &&
        _farmStartDate != null) {
      try {
        final areaHectares = double.tryParse(_areaHectaresController.text.trim());
        final totalVines = int.tryParse(_totalVinesController.text.trim());

        if (areaHectares == null || areaHectares <= 0) {
          _showError('Please enter a valid area in hectares');
          return;
        }
        if (totalVines == null || totalVines <= 0) {
          _showError('Please enter a valid number of vines');
          return;
        }

        await ref.read(plantationControllerProvider.notifier).updateFarm(
              farmId: widget.farm.id,
              farmName: _farmNameController.text.trim(),
              farmStartDate: _farmStartDate,
              areaHectares: areaHectares,
              totalVines: totalVines,
              // District, Soil, Variety are read-only and not updated
            );

        if (mounted) {
          // Invalidate all related providers to refresh data
          ref.invalidate(farmProvider(widget.farm.id));
          ref.invalidate(farmsProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Farm updated successfully'),
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


    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Farm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputField(
                label: 'Farm Name',
                controller: _farmNameController,
                validator: (value) => Validators.required(value, fieldName: 'Farm name'),
              ),
              const SizedBox(height: 16),
              // Read Only District
              InputField(
                label: 'District',
                controller: TextEditingController(text: widget.farm.district),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),
              
              // Read Only Soil Type
              InputField(
                label: 'Soil Type',
                controller: TextEditingController(text: widget.farm.soilType),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),

              // Read Only Variety
              InputField(
                label: 'Chosen Variety',
                controller: TextEditingController(text: widget.farm.chosenVariety),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),
              // Planting Date
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _farmStartDate != null
                          ? '${_farmStartDate!.day}/${_farmStartDate!.month}/${_farmStartDate!.year}'
                          : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Farm Start Date',
                      hintText: 'Select planting date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_farmStartDate == null) return 'Please select a farm start date';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Area in Hectares',
                controller: _areaHectaresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter area';
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) return 'Please enter a valid area';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Total Vines',
                controller: _totalVinesController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter total vines';
                  final vines = int.tryParse(value);
                  if (vines == null || vines <= 0) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }


}
