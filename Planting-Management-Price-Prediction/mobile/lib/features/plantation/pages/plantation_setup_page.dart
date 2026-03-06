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
import '../../agronomy/providers/language_provider.dart';
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
final soilsByDistrictProvider = FutureProvider.family<List<SoilType>, String>(
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
  final String districtId;
  final String soilTypeId;

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

  Future<void> _selectDate(BuildContext context, String lang) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        _selectedDistrict != null &&
        _selectedSoilType != null &&
        _selectedVariety != null &&
        _farmStartDate != null) {
      try {
        final areaHectares = double.tryParse(_areaHectaresController.text.trim());
        final totalVines = int.tryParse(_totalVinesController.text.trim());

        if (areaHectares == null || areaHectares <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang == 'en' ? 'Please enter a valid area in hectares' : 'කරුණාකර නිවැරදි භූමි ප්‍රමාණයක් (හෙක්ටයාර) ඇතුලත් කරන්න'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (totalVines == null || totalVines <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lang == 'en' ? 'Please enter a valid number of vines' : 'කරුණාකර නිවැරදි වැල් ගණනක් ඇතුලත් කරන්න'),
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
            SnackBar(
              content: Text(lang == 'en' ? 'Plantation started successfully! Schedule has been generated.' : 'වගාව සාර්ථකව ආරම්භ කරන ලදී! කාලසටහන සකස් කර ඇත.'),
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
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Start Plantation' : 'වගාව අරඹන්න'),
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
                hint: lang == 'en' ? 'Enter your farm name' : 'ඔබගේ ගොවිපළේ නම ඇතුලත් කරන්න',
                validator: (value) => Validators.required(value, fieldName: lang == 'en' ? 'Farm name' : 'ගොවිපළේ නම'),
              ),
              const SizedBox(height: 16),
              _buildDistrictDropdown(lang),
              if (_selectedDistrict != null) ...[
                const SizedBox(height: 16),
                _buildSoilTypeDropdown(lang),
              ],
              if (_selectedDistrict != null && _selectedSoilType != null) ...[
                const SizedBox(height: 16),
                _buildVarietyDropdown(lang),
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
                      labelText: lang == 'en' ? 'Farm Start Date' : 'ගොවිපළ ආරම්භ කළ දිනය',
                      hintText: lang == 'en' ? 'Select farm start date' : 'ගොවිපළ ආරම්භ කළ දිනය තෝරන්න',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (_farmStartDate == null) {
                        return lang == 'en' ? 'Please select a planting date' : 'කරුණාකර ආරම්භ කළ දිනයක් තෝරන්න';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: lang == 'en' ? 'Area in Hectares' : 'භූමි ප්‍රමාණය (හෙක්ටයාර)',
                controller: _areaHectaresController,
                hint: lang == 'en' ? 'e.g., 2.5' : 'උදා: 2.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang == 'en' ? 'Please enter area in hectares' : 'කරුණාකර භූමි ප්‍රමාණය ඇතුලත් කරන්න';
                  }
                  final area = double.tryParse(value);
                  if (area == null || area <= 0) {
                    return lang == 'en' ? 'Please enter a valid area' : 'කරුණාකර නිවැරදි භූමි ප්‍රමාණයක් ඇතුලත් කරන්න';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: lang == 'en' ? 'Total Vines' : 'සම්පූර්ණ වැල් ගණන',
                controller: _totalVinesController,
                hint: lang == 'en' ? 'e.g., 1000' : 'උදා: 1000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return lang == 'en' ? 'Please enter total number of vines' : 'කරුණාකර සම්පූර්ණ වැල් ගණන ඇතුලත් කරන්න';
                  }
                  final vines = int.tryParse(value);
                  if (vines == null || vines <= 0) {
                    return lang == 'en' ? 'Please enter a valid number of vines' : 'කරුණාකර නිවැරදි වැල් ගණනක් ඇතුලත් කරන්න';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              plantationState.isLoading
                  ? LoadingSpinner(message: lang == 'en' ? 'Starting plantation...' : 'වගාව ආරම්භ කරමින්...')
                  : PrimaryButton(
                      text: lang == 'en' ? 'Start Plantation' : 'වගාව ආරම්භ කරන්න',
                      onPressed: () => _handleSubmit(lang),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown(String lang) {
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
                    lang == 'en' ? 'No districts available' : 'දිස්ත්‍රික්ක නොමැත',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownField<District>(
          label: lang == 'en' ? 'District' : 'දිස්ත්‍රික්කය',
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
              return lang == 'en' ? 'Please select a district' : 'කරුණාකර දිස්ත්‍රික්කයක් තෝරන්න';
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
          lang == 'en' ? 'Error loading districts: ${error.toString()}' : 'දිස්ත්‍රික්ක පැටවීමේ දෝෂයකි: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildSoilTypeDropdown(String lang) {
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
                    lang == 'en' ? 'No soil types available for ${_selectedDistrict!.name.get(lang)}' : '${_selectedDistrict!.name.get(lang)} සඳහා පස වර්ග නොමැත',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          );
        }
        return DropdownField<SoilType>(
          label: lang == 'en' ? 'Soil Type' : 'පස වර්ගය',
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
              return lang == 'en' ? 'Please select a soil type' : 'කරුණාකර පස වර්ගයක් තෝරන්න';
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
          lang == 'en' ? 'Error loading soil types: ${error.toString()}' : 'පස වර්ග පැටවීමේ දෝෂයකි: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildVarietyDropdown(String lang) {
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
                    lang == 'en' ? 'No varieties available for ${_selectedDistrict!.name.get(lang)} - ${_selectedSoilType!.typeName.get(lang)}' : '${_selectedDistrict!.name.get(lang)} - ${_selectedSoilType!.typeName.get(lang)} සඳහා ප්‍රභේද නොමැත',
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
              label: lang == 'en' ? 'Chosen Variety' : 'තෝරාගත් වර්ගය',
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
                  return lang == 'en' ? 'Please select a variety' : 'කරුණාකර ප්‍රභේදයක් තෝරන්න';
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
                        lang == 'en' ? 'Variety Information' : 'වර්ගයේ තොරතුරු',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(lang == 'en' ? 'Specialities' : 'විශේෂතා', _selectedVariety!.specialities.get(lang), lang),
                      _buildInfoRow(lang == 'en' ? 'Soil' : 'පස', _selectedVariety!.soilTypeRecommendation.get(lang), lang),
                      _buildInfoRow(lang == 'en' ? 'Spacing' : 'පරතරය', _selectedVariety!.plantingSpecifications.spacingMeters, lang),
                      _buildInfoRow(lang == 'en' ? 'Vines/Ha' : 'හෙක්.කට වැල්', '${_selectedVariety!.plantingSpecifications.vinesPerHectare}', lang),
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
          lang == 'en' ? 'Error loading varieties: ${error.toString()}' : 'ප්‍රභේද පැටවීමේ දෝෂයකි: ${error.toString()}',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String lang) {
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
              value.isNotEmpty ? value : (lang == 'en' ? 'N/A' : 'අදාළ නොවේ'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
