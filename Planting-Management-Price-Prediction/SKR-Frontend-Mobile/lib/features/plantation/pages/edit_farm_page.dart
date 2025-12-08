import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/plantation_controller.dart';
import '../models/farm_record_model.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/utils/validators.dart';
import '../../agronomy/services/agronomy_service.dart';
import '../../agronomy/models/district_model.dart';
import '../../agronomy/models/soil_type_model.dart';
import '../../agronomy/models/variety_model.dart';
import '../../../../core/network/api_client.dart';

// Provider for AgronomyService
final _editAgronomyServiceProvider = Provider<AgronomyService>((ref) {
  return AgronomyService(ApiClient());
});

// Provider for all districts
final _editAllDistrictsProvider = FutureProvider<List<District>>((ref) async {
  final service = ref.read(_editAgronomyServiceProvider);
  return await service.fetchAllDistricts();
});

// Provider for soil types by district
final _editSoilsByDistrictProvider = FutureProvider.family<List<SoilType>, int>(
  (ref, districtId) async {
    final service = ref.read(_editAgronomyServiceProvider);
    return await service.fetchSoilsByDistrict(districtId);
  },
);

// Provider for varieties by district and soil type
class _EditDistrictSoilKey {
  final int districtId;
  final int soilTypeId;

  const _EditDistrictSoilKey(this.districtId, this.soilTypeId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EditDistrictSoilKey &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          soilTypeId == other.soilTypeId;

  @override
  int get hashCode => districtId.hashCode ^ soilTypeId.hashCode;
}

final _editVarietiesByDistrictAndSoilProvider = FutureProvider.family<List<BlackPepperVariety>, _EditDistrictSoilKey>(
  (ref, key) async {
    final service = ref.read(_editAgronomyServiceProvider);
    return await service.fetchVarietiesByDistrictAndSoil(key.districtId, key.soilTypeId);
  },
);

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

  District? _selectedDistrict;
  SoilType? _selectedSoilType;
  BlackPepperVariety? _selectedVariety;
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
        _selectedDistrict != null &&
        _selectedSoilType != null &&
        _selectedVariety != null &&
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
              districtId: _selectedDistrict!.id,
              soilTypeId: _selectedSoilType!.id,
              chosenVarietyId: _selectedVariety!.id,
              farmStartDate: _farmStartDate,
              areaHectares: areaHectares,
              totalVines: totalVines,
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
    final districtsAsync = ref.watch(_editAllDistrictsProvider);
    
    // Initialize selected district from farm data when districts load (only once)
    districtsAsync.whenData((districts) {
      if (_selectedDistrict == null && widget.farm.district.isNotEmpty && districts.isNotEmpty) {
        // Find the district that matches by name
        final matchingDistrict = districts.firstWhere(
          (d) => d.name == widget.farm.district,
          orElse: () => districts.first,
        );
        // Use addPostFrameCallback to avoid setting state during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedDistrict == null) {
            setState(() {
              _selectedDistrict = matchingDistrict;
            });
          }
        });
      }
    });

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
              districtsAsync.when(
                data: (districts) {
                  // Find the matching district from the list by ID to ensure instance equality
                  District? validSelectedDistrict;
                  if (_selectedDistrict != null) {
                    try {
                      validSelectedDistrict = districts.firstWhere(
                        (d) => d.id == _selectedDistrict!.id,
                      );
                    } catch (e) {
                      // District not found in list, set to null
                      validSelectedDistrict = null;
                    }
                  }
                  
                  return DropdownField<District>(
                    label: 'District',
                    value: validSelectedDistrict,
                    items: districts
                        .map((district) => DropdownMenuItem(
                              value: district,
                              child: Text(district.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                        _selectedSoilType = null;
                        _selectedVariety = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Please select a district';
                      return null;
                    },
                  );
                },
                loading: () => const LoadingSpinner(message: 'Loading districts...'),
                error: (error, stack) => Text(
                  'Error loading districts: ${error.toString()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedDistrict != null) _buildSoilTypeSelector(),
              const SizedBox(height: 16),
              if (_selectedDistrict != null && _selectedSoilType != null) _buildVarietySelector(),
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

  Widget _buildSoilTypeSelector() {
    final soilsAsync = ref.watch(_editSoilsByDistrictProvider(_selectedDistrict!.id));

    return soilsAsync.when(
      data: (soils) {
        if (soils.isEmpty) {
          return const SizedBox.shrink();
        }

        // Initialize selected soil type from farm data
        if (_selectedSoilType == null && soils.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedSoilType = soils.first;
              });
            }
          });
        }

        return DropdownField<SoilType>(
          label: 'Soil Type',
          value: _selectedSoilType,
          items: soils
              .map((soil) => DropdownMenuItem(
                    value: soil,
                    child: Text(soil.typeName),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSoilType = value;
              _selectedVariety = null;
            });
          },
          validator: (value) {
            if (value == null) return 'Please select a soil type';
            return null;
          },
        );
      },
      loading: () => const LoadingSpinner(message: 'Loading soil types...'),
      error: (error, stack) => Text(
        'Error loading soil types: ${error.toString()}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
      ),
    );
  }

  Widget _buildVarietySelector() {
    final key = _EditDistrictSoilKey(_selectedDistrict!.id, _selectedSoilType!.id);
    final varietiesAsync = ref.watch(_editVarietiesByDistrictAndSoilProvider(key));

    return varietiesAsync.when(
      data: (varieties) {
        if (varieties.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'No varieties available for selected district and soil type',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
            ),
          );
        }

        // Initialize selected variety from farm data
        if (_selectedVariety == null && widget.farm.chosenVariety.isNotEmpty) {
          final matchingVariety = varieties.firstWhere(
            (v) => v.name == widget.farm.chosenVariety,
            orElse: () => varieties.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedVariety = matchingVariety;
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownField<BlackPepperVariety>(
              label: 'Chosen Variety',
              value: _selectedVariety,
              items: varieties
                  .map((variety) => DropdownMenuItem(
                        value: variety,
                        child: Text(variety.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVariety = value;
                });
              },
              validator: (value) {
                if (value == null) return 'Please select a variety';
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
                      _buildInfoRow('Specialities', _selectedVariety!.specialities ?? 'N/A'),
                      _buildInfoRow('Soil', _selectedVariety!.soilTypeRecommendation ?? 'N/A'),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const LoadingSpinner(message: 'Loading varieties...'),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          'Error loading varieties: ${error.toString()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
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
