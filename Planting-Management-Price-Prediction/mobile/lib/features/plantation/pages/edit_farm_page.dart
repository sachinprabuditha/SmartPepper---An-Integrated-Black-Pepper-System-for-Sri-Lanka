import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/plantation_controller.dart';
import '../models/farm_record_model.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/validators.dart';
import '../../agronomy/providers/language_provider.dart';

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

  Future<void> _selectDate(BuildContext context, String lang) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _farmStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: lang == 'en' ? 'Select Farm Start Date' : 'ගොවිපළ ආරම්භ කළ දිනය තෝරන්න',
    );
    if (picked != null) {
      setState(() {
        _farmStartDate = picked;
      });
    }
  }

  Future<void> _handleSubmit(String lang) async {
    if (_formKey.currentState!.validate() &&
        _farmStartDate != null) {
      try {
        final areaHectares = double.tryParse(_areaHectaresController.text.trim());
        final totalVines = int.tryParse(_totalVinesController.text.trim());

        if (areaHectares == null || areaHectares <= 0) {
          _showError(lang == 'en' ? 'Please enter a valid area in hectares' : 'කරුණාකර නිවැරදි භූමි ප්‍රමාණයක් (හෙක්ටයාර) ඇතුලත් කරන්න');
          return;
        }
        if (totalVines == null || totalVines <= 0) {
          _showError(lang == 'en' ? 'Please enter a valid number of vines' : 'කරුණාකර නිවැරදි වැල් ගණනක් ඇතුලත් කරන්න');
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
            SnackBar(
              content: Text(lang == 'en' ? 'Farm updated successfully' : 'ගොවිපළ සාර්ථකව යාවත්කාලීන කරන ලදී'),
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
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Edit Farm' : 'ගොවිපළ සංස්කරණය කරන්න'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputField(
                label: lang == 'en' ? 'Farm Name' : 'ගොවිපළේ නම',
                controller: _farmNameController,
                validator: (value) => Validators.required(value, fieldName: lang == 'en' ? 'Farm name' : 'ගොවිපළේ නම'),
              ),
              const SizedBox(height: 16),
              // Read Only District
              InputField(
                label: lang == 'en' ? 'District' : 'දිස්ත්‍රික්කය',
                controller: TextEditingController(text: widget.farm.district.get(lang)),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),
              
              // Read Only Soil Type
              InputField(
                label: lang == 'en' ? 'Soil Type' : 'පස වර්ගය',
                controller: TextEditingController(text: widget.farm.soilType.get(lang)),
                readOnly: true,
                validator: null,
              ),
              const SizedBox(height: 16),

              // Read Only Variety
              InputField(
                label: lang == 'en' ? 'Chosen Variety' : 'තෝරාගත් ප්‍රභේදය',
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
                      labelText: lang == 'en' ? 'Farm Start Date' : 'ගොවිපළ ආරම්භ කළ දිනය',
                      hintText: lang == 'en' ? 'Select planting date' : 'ගොවිපළ ආරම්භ කළ දිනය තෝරන්න',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_farmStartDate == null) return lang == 'en' ? 'Please select a farm start date' : 'කරුණාකර ආරම්භ කළ දිනයක් තෝරන්න';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: lang == 'en' ? 'Area in Hectares' : 'භූමි ප්‍රමාණය (හෙක්ටයාර)',
                controller: _areaHectaresController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return lang == 'en' ? 'Please enter area' : 'කරුණාකර භූමි ප්‍රමාණය ඇතුලත් කරන්න';
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) return lang == 'en' ? 'Please enter a valid area' : 'කරුණාකර නිවැරදි භූමි ප්‍රමාණයක් ඇතුලත් කරන්න';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: lang == 'en' ? 'Total Vines' : 'සම්පූර්ණ වැල් ගණන',
                controller: _totalVinesController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return lang == 'en' ? 'Please enter total vines' : 'කරුණාකර සම්පූර්ණ වැල් ගණන ඇතුලත් කරන්න';
                  final vines = int.tryParse(value);
                  if (vines == null || vines <= 0) return lang == 'en' ? 'Please enter a valid number' : 'කරුණාකර නිවැරදි වැල් ගණනක් ඇතුලත් කරන්න';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: lang == 'en' ? 'Save Changes' : 'වෙනස්කම් සුරකින්න',
                onPressed: () => _handleSubmit(lang),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
