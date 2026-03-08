import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import 'dart:developer' as developer;
import '../controllers/plantation_controller.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/dropdown_field.dart';
import '../../../../widgets/loading_spinner.dart';
import '../../../../utils/validators.dart';
import '../../agronomy/models/district_model.dart';
import '../../agronomy/models/soil_type_model.dart';
import '../../agronomy/models/variety_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class PlantationSetupPage extends ConsumerStatefulWidget {
  const PlantationSetupPage({super.key});

  @override
  ConsumerState<PlantationSetupPage> createState() =>
      _PlantationSetupPageState();
}

class _PlantationSetupPageState extends ConsumerState<PlantationSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _farmNameController = TextEditingController();
  final _areaHectaresController = TextEditingController();
  final _totalVinesController = TextEditingController();

  District? _selectedDistrict;
  SoilType? _selectedSoilType;
  BlackPepperVariety? _selectedVariety;
  DateTime? _farmStartDate;
  DistrictSoilKey? _cachedVarietiesKey;

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
      initialDate: DateTime.now(),
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

  Future<void> _handleSubmit(String lang) async {
    if (_formKey.currentState!.validate() &&
        _selectedDistrict != null &&
        _selectedSoilType != null &&
        _selectedVariety != null &&
        _farmStartDate != null) {
      try {
        final areaHectares =
            double.tryParse(_areaHectaresController.text.trim());
        final totalVines = int.tryParse(_totalVinesController.text.trim());

        if (areaHectares == null || areaHectares <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_validation_valid_area')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (totalVines == null || totalVines <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_validation_valid_vines')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        developer.log(
            'Submitting plantation: DistrictId=${_selectedDistrict!.id}, SoilTypeId=${_selectedSoilType!.id}, VarietyId=${_selectedVariety!.id}');

        final farmRecord = await ref
            .read(plantationControllerProvider.notifier)
            .startPlantation(
              farmName: _farmNameController.text.trim(),
              districtId: _selectedDistrict!.id,
              soilTypeId: _selectedSoilType!.id,
              chosenVarietyId: _selectedVariety!.id,
              farmStartDate: _farmStartDate!,
              areaHectares: areaHectares,
              totalVines: totalVines,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_started_success')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, farmRecord);
        }
      } catch (e) {
        developer.log('Error starting plantation: $e', error: e);
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
    final plantationState = ref.watch(plantationControllerProvider);
    final languageProvider =
        vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_start_plantation_title')),
        actions: const [
          SizedBox(width: 8),
        ],
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
                hint: context.tr('plantation_enter_farm_name'),
                validator: (value) => Validators.required(value,
                    fieldName: context.tr('plantation_farm_name')),
              ),
              const SizedBox(height: 16),
              _buildDistrictDropdown(context, lang),
              if (_selectedDistrict != null) ...[
                const SizedBox(height: 16),
                _buildSoilTypeDropdown(context, lang),
              ],
              if (_selectedDistrict != null && _selectedSoilType != null) ...[
                const SizedBox(height: 16),
                _buildVarietyDropdown(context, lang),
              ],
              const SizedBox(height: 16),
              // Farm Start Date Picker
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
                      hintText:
                          context.tr('plantation_select_planting_date_short'),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (_farmStartDate == null) {
                        return context.tr('plantation_select_planting_date');
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('plantation_area_in_hectares'),
                controller: _areaHectaresController,
                hint: context.tr('plantation_hint_eg_25'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('plantation_validation_enter_area');
                  }
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) {
                    return context.tr('plantation_validation_enter_valid_area');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('plantation_total_vines'),
                controller: _totalVinesController,
                hint: context.tr('plantation_hint_eg_1000'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('plantation_validation_enter_vines');
                  }
                  final vines = int.tryParse(value);
                  if (vines == null || vines <= 0) {
                    return context
                        .tr('plantation_validation_valid_number_vines');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              plantationState.isLoading
                  ? LoadingSpinner(message: context.tr('plantation_starting'))
                  : PrimaryButton(
                      text: context.tr('plantation_start_plantation'),
                      onPressed: () => _handleSubmit(lang),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown(BuildContext context, String lang) {
    final districtsAsync = ref.watch(allDistrictsProvider);

    return districtsAsync.when(
      data: (districts) {
        if (districts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('plantation_no_districts'),
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownField<District>(
          label: context.tr('plantation_district'),
          value: _selectedDistrict,
          items: districts.map((district) {
            return DropdownMenuItem(
              value: district,
              child: Text(district.name.get(lang)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDistrict = value;
              _selectedSoilType = null; // Reset soil type when district changes
              _selectedVariety = null; // Reset variety when district changes
              _cachedVarietiesKey = null; // Reset cached key
            });
            if (value != null) {
              ref.invalidate(soilsByDistrictProvider(value.id));
            }
          },
          validator: (value) {
            if (value == null) {
              return context.tr('plantation_please_select_district');
            }
            return null;
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${context.tr('plantation_error_loading_districts')}: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildSoilTypeDropdown(BuildContext context, String lang) {
    if (_selectedDistrict == null) return const SizedBox.shrink();

    final soilsAsync =
        ref.watch(soilsByDistrictProvider(_selectedDistrict!.id));

    return soilsAsync.when(
      data: (soils) {
        if (soils.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('plantation_no_soil_types_for').replaceAll(
                        '{name}', _selectedDistrict!.name.get(lang)),
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownField<SoilType>(
          label: context.tr('plantation_soil_type'),
          value: _selectedSoilType,
          items: soils.map((soil) {
            return DropdownMenuItem(
              value: soil,
              child: Text(soil.typeName.get(lang)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSoilType = value;
              _selectedVariety = null; // Reset variety when soil type changes
              _cachedVarietiesKey = null; // Reset cached key
            });
          },
          validator: (value) {
            if (value == null) {
              return context.tr('plantation_please_select_soil');
            }
            return null;
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${context.tr('plantation_error_loading_soils')}: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildVarietyDropdown(BuildContext context, String lang) {
    if (_selectedDistrict == null || _selectedSoilType == null) {
      return const SizedBox.shrink();
    }

    final currentKey =
        DistrictSoilKey(_selectedDistrict!.id, _selectedSoilType!.id);
    if (_cachedVarietiesKey == null || _cachedVarietiesKey != currentKey) {
      _cachedVarietiesKey = currentKey;
    }

    final varietiesAsync =
        ref.watch(varietiesByDistrictAndSoilProvider(_cachedVarietiesKey!));

    return varietiesAsync.when(
      data: (varieties) {
        if (varieties.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('plantation_no_varieties_for').replaceAll(
                        '{name}',
                        '${_selectedDistrict!.name.get(lang)} - ${_selectedSoilType!.typeName.get(lang)}'),
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }

        // Reset selected variety if not in list
        if (_selectedVariety != null &&
            !varieties.any((v) => v.id == _selectedVariety!.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedVariety = null;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownField<BlackPepperVariety>(
              label: context.tr('plantation_chosen_variety'),
              value: _selectedVariety,
              items: varieties.map((variety) {
                return DropdownMenuItem(
                  value: variety,
                  child: Text(variety.name.get(lang)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVariety = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return context.tr('plantation_please_select_variety');
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (_selectedVariety != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('plantation_variety_info'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          context,
                          context.tr('plantation_specialities'),
                          _selectedVariety!.specialities.get(lang),
                          lang),
                      _buildInfoRow(
                          context,
                          context.tr('plantation_soil'),
                          _selectedVariety!.soilTypeRecommendation.get(lang),
                          lang),
                      _buildInfoRow(
                          context,
                          context.tr('plantation_spacing'),
                          _selectedVariety!
                              .plantingSpecifications.spacingMeters,
                          lang),
                      _buildInfoRow(
                          context,
                          context.tr('plantation_vines_ha'),
                          '${_selectedVariety!.plantingSpecifications.vinesPerHectare}',
                          lang),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${context.tr('plantation_error_loading_varieties')}: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty
                  ? value
                  : context.tr('plantation_not_applicable'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
