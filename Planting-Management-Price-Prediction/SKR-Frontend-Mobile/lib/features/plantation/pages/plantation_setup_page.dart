import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../controllers/plantation_controller.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/utils/validators.dart';
import '../../agronomy/services/agronomy_service.dart';
import '../../agronomy/models/district_model.dart';
import '../../agronomy/models/soil_type_model.dart';
import '../../agronomy/models/variety_model.dart';
import '../../../../core/network/api_client.dart';
// Provider for AgronomyService
final agronomyServiceProvider = Provider<AgronomyService>((ref) {
  return AgronomyService(ApiClient());
});

// Provider for all districts
final allDistrictsProvider = FutureProvider<List<District>>((ref) async {
  final service = ref.read(agronomyServiceProvider);
  return await service.fetchAllDistricts();
});

// Provider for soil types by district
final soilsByDistrictProvider = FutureProvider.family<List<SoilType>, int>(
  (ref, districtId) async {
    final service = ref.read(agronomyServiceProvider);
    return await service.fetchSoilsByDistrict(districtId);
  },
);

// Provider for varieties by district and soil type
final varietiesByDistrictAndSoilProvider = FutureProvider.family<List<BlackPepperVariety>, DistrictSoilKey>(
  (ref, key) async {
    final service = ref.read(agronomyServiceProvider);
    return await service.fetchVarietiesByDistrictAndSoil(key.districtId, key.soilTypeId);
  },
);

// Custom key class for District and Soil Type combination
class DistrictSoilKey {
  final int districtId;
  final int soilTypeId;

  const DistrictSoilKey(this.districtId, this.soilTypeId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictSoilKey &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          soilTypeId == other.soilTypeId;

  @override
  int get hashCode => districtId.hashCode ^ soilTypeId.hashCode;
}

class PlantationSetupPage extends ConsumerStatefulWidget {
  const PlantationSetupPage({super.key});

  @override
  ConsumerState<PlantationSetupPage> createState() => _PlantationSetupPageState();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        _selectedDistrict != null &&
        _selectedSoilType != null &&
        _selectedVariety != null &&
        _farmStartDate != null) {
      try {
        final areaHectares = double.tryParse(_areaHectaresController.text.trim());
        final totalVines = int.tryParse(_totalVinesController.text.trim());

        if (areaHectares == null || areaHectares <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid area in hectares'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (totalVines == null || totalVines <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid number of vines'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        developer.log('Submitting plantation: DistrictId=${_selectedDistrict!.id}, SoilTypeId=${_selectedSoilType!.id}, VarietyId=${_selectedVariety!.id}');

        final farmRecord = await ref.read(plantationControllerProvider.notifier).startPlantation(
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
            const SnackBar(
              content: Text('Plantation started successfully! Schedule has been generated.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Plantation'),
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
                hint: 'Enter your farm name',
                validator: (value) => Validators.required(value, fieldName: 'Farm name'),
              ),
              const SizedBox(height: 16),
              _buildDistrictDropdown(),
              if (_selectedDistrict != null) ...[
                const SizedBox(height: 16),
                _buildSoilTypeDropdown(),
              ],
              if (_selectedDistrict != null && _selectedSoilType != null) ...[
                const SizedBox(height: 16),
                _buildVarietyDropdown(),
              ],
              const SizedBox(height: 16),
              // Farm Start Date Picker
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
                      hintText: 'Select farm start date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_farmStartDate == null) {
                        return 'Please select a planting date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Area in Hectares',
                controller: _areaHectaresController,
                hint: 'e.g., 2.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter area in hectares';
                  }
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) {
                    return 'Please enter a valid area';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Total Vines',
                controller: _totalVinesController,
                hint: 'e.g., 1000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total number of vines';
                  }
                  final vines = int.tryParse(value);
                  if (vines == null || vines <= 0) {
                    return 'Please enter a valid number of vines';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              plantationState.isLoading
                  ? const LoadingSpinner(message: 'Starting plantation...')
                  : PrimaryButton(
                      text: 'Start Plantation',
                      onPressed: _handleSubmit,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
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
                    'No districts available',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownField<District>(
          label: 'District',
          value: _selectedDistrict,
          items: districts.map((district) {
            return DropdownMenuItem(
              value: district,
              child: Text(district.name),
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
              return 'Please select a district';
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
          'Error loading districts: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildSoilTypeDropdown() {
    if (_selectedDistrict == null) return const SizedBox.shrink();

    final soilsAsync = ref.watch(soilsByDistrictProvider(_selectedDistrict!.id));

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
                    'No soil types available for ${_selectedDistrict!.name}',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownField<SoilType>(
          label: 'Soil Type',
          value: _selectedSoilType,
          items: soils.map((soil) {
            return DropdownMenuItem(
              value: soil,
              child: Text(soil.typeName),
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
              return 'Please select a soil type';
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
          'Error loading soil types: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildVarietyDropdown() {
    if (_selectedDistrict == null || _selectedSoilType == null) {
      return const SizedBox.shrink();
    }

    final currentKey = DistrictSoilKey(_selectedDistrict!.id, _selectedSoilType!.id);
    if (_cachedVarietiesKey == null || _cachedVarietiesKey != currentKey) {
      _cachedVarietiesKey = currentKey;
    }

    final varietiesAsync = ref.watch(varietiesByDistrictAndSoilProvider(_cachedVarietiesKey!));

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
                    'No varieties available for ${_selectedDistrict!.name} - ${_selectedSoilType!.typeName}',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }

        // Reset selected variety if not in list
        if (_selectedVariety != null && !varieties.any((v) => v.id == _selectedVariety!.id)) {
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
              label: 'Chosen Variety',
              value: _selectedVariety,
              items: varieties.map((variety) {
                return DropdownMenuItem(
                  value: variety,
                  child: Text(variety.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVariety = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a variety';
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
                        'Variety Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Specialities', _selectedVariety!.specialities),
                      _buildInfoRow('Soil', _selectedVariety!.soilTypeRecommendation),
                      _buildInfoRow('Spacing', _selectedVariety!.plantingSpecifications.spacingMeters),
                      _buildInfoRow('Vines/Ha', '${_selectedVariety!.plantingSpecifications.vinesPerHectare}'),
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
          'Error loading varieties: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
