import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AddProcessingStageScreen extends StatefulWidget {
  final String lotId;

  const AddProcessingStageScreen({super.key, required this.lotId});

  @override
  State<AddProcessingStageScreen> createState() =>
      _AddProcessingStageScreenState();
}

class _AddProcessingStageScreenState extends State<AddProcessingStageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  String? _selectedStageType;
  final _stageNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _operatorController = TextEditingController();
  final _notesController = TextEditingController();

  // Stage-specific fields
  // Harvest
  final _yieldKgController = TextEditingController();
  final _qualityScoreController = TextEditingController();
  final _harvestMethodController = TextEditingController();

  // Drying
  final _moistureController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _durationHoursController = TextEditingController();

  // Grading
  final _gradeController = TextEditingController();
  final _colorController = TextEditingController();
  final _uniformityController = TextEditingController();

  // Packaging
  final _packageMaterialController = TextEditingController();
  final _packSizeController = TextEditingController();
  final _packCountController = TextEditingController();

  // Storage
  final _storageTypeController = TextEditingController();
  final _storageTemperatureController = TextEditingController();
  final _storageHumidityController = TextEditingController();

  DateTime _stageDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, String>> _stageTypes = [
    {
      'value': 'harvest',
      'label': 'Harvest',
      'description': 'Initial pepper harvesting from farm'
    },
    {
      'value': 'drying',
      'label': 'Drying',
      'description': 'Drying process to reduce moisture'
    },
    {
      'value': 'grading',
      'label': 'Grading',
      'description': 'Quality grading and sorting'
    },
    {
      'value': 'packaging',
      'label': 'Packaging',
      'description': 'Packing for storage or export'
    },
    {
      'value': 'storage',
      'label': 'Storage',
      'description': 'Storage in controlled conditions'
    },
  ];

  @override
  void dispose() {
    _stageNameController.dispose();
    _locationController.dispose();
    _operatorController.dispose();
    _notesController.dispose();
    _yieldKgController.dispose();
    _qualityScoreController.dispose();
    _harvestMethodController.dispose();
    _moistureController.dispose();
    _temperatureController.dispose();
    _durationHoursController.dispose();
    _gradeController.dispose();
    _colorController.dispose();
    _uniformityController.dispose();
    _packageMaterialController.dispose();
    _packSizeController.dispose();
    _packCountController.dispose();
    _storageTypeController.dispose();
    _storageTemperatureController.dispose();
    _storageHumidityController.dispose();
    super.dispose();
  }

  void _updateStageName() {
    if (_selectedStageType != null) {
      final stageInfo = _stageTypes.firstWhere(
        (s) => s['value'] == _selectedStageType,
      );
      _stageNameController.text = '${stageInfo['label']} Process';
    }
  }

  Map<String, dynamic> _buildQualityMetrics() {
    switch (_selectedStageType) {
      case 'harvest':
        return {
          'yield_kg': double.tryParse(_yieldKgController.text) ?? 0,
          'quality_score': int.tryParse(_qualityScoreController.text) ?? 0,
          'harvest_method': _harvestMethodController.text,
        };
      case 'drying':
        return {
          'moisture': double.tryParse(_moistureController.text) ?? 0,
          'temperature': double.tryParse(_temperatureController.text) ?? 0,
          'duration_hours': int.tryParse(_durationHoursController.text) ?? 0,
        };
      case 'grading':
        return {
          'grade': _gradeController.text,
          'color': _colorController.text,
          'uniformity': _uniformityController.text,
        };
      case 'packaging':
        return {
          'package_material': _packageMaterialController.text,
          'pack_size': _packSizeController.text,
          'pack_count': int.tryParse(_packCountController.text) ?? 0,
        };
      case 'storage':
        return {
          'storage_type': _storageTypeController.text,
          'temperature':
              double.tryParse(_storageTemperatureController.text) ?? 0,
          'humidity': double.tryParse(_storageHumidityController.text) ?? 0,
        };
      default:
        return {};
    }
  }

  Future<void> _submitStage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stage type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.addProcessingStage(
        lotId: widget.lotId,
        stageType: _selectedStageType!,
        stageName: _stageNameController.text,
        location: _locationController.text,
        timestamp: _stageDate.toIso8601String(),
        operatorName: _operatorController.text,
        qualityMetrics: _buildQualityMetrics(),
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing stage added successfully!',
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _stageDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.forestGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _stageDate) {
      setState(() {
        _stageDate = picked;
      });
    }
  }

  Widget _buildStageSpecificFields() {
    switch (_selectedStageType) {
      case 'harvest':
        return _buildHarvestFields();
      case 'drying':
        return _buildDryingFields();
      case 'grading':
        return _buildGradingFields();
      case 'packaging':
        return _buildPackagingFields();
      case 'storage':
        return _buildStorageFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHarvestFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Harvest Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _yieldKgController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Yield (kg)',
            hintText: 'e.g., 52',
            prefixIcon: Icon(Icons.scale),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter yield in kg';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _qualityScoreController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quality Score (0-100)',
            hintText: 'e.g., 95',
            prefixIcon: Icon(Icons.star),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter quality score';
            }
            final score = int.tryParse(value);
            if (score == null || score < 0 || score > 100) {
              return 'Score must be between 0 and 100';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _harvestMethodController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            hintStyle: TextStyle(color: Colors.black87),
            labelText: 'Harvest Method',
            hintText: 'e.g., Manual, Mechanical',
            prefixIcon: Icon(Icons.agriculture),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter harvest method';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDryingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Drying Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _moistureController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Moisture Content (%)',
            hintText: 'e.g., 11.8 (Must be ≤12.5% for EU)',
            prefixIcon: Icon(Icons.water_drop),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter moisture content';
            }
            final moisture = double.tryParse(value);
            if (moisture == null) {
              return 'Please enter a valid number';
            }
            if (moisture > 12.5) {
              return 'Warning: EU limit is 12.5%';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _temperatureController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Temperature (°C)',
            hintText: 'e.g., 28',
            prefixIcon: Icon(Icons.thermostat),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter temperature';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _durationHoursController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Duration (hours)',
            hintText: 'e.g., 72',
            prefixIcon: Icon(Icons.timer),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter duration';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGradingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Grading Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _gradeController.text.isEmpty ? null : _gradeController.text,
          decoration: const InputDecoration(
            labelText: 'Quality Grade',
            prefixIcon: Icon(Icons.grade),
            border: OutlineInputBorder(),
          ),
          items: ['AAA', 'AA', 'A', 'B', 'C']
              .map((grade) => DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _gradeController.text = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select grade';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _colorController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Color',
            hintText: 'e.g., Black, White, Green',
            prefixIcon: Icon(Icons.color_lens),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter color';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _uniformityController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Uniformity (%)',
            hintText: 'e.g., 95',
            prefixIcon: Icon(Icons.percent),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter uniformity percentage';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPackagingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Packaging Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _packageMaterialController.text.isEmpty
              ? null
              : _packageMaterialController.text,
          decoration: const InputDecoration(
            labelText: 'Package Material',
            prefixIcon: Icon(Icons.inventory_2),
            border: OutlineInputBorder(),
          ),
          items: [
            'Food_grade_plastic',
            'HDPE',
            'PP',
            'PET',
            'Glass',
            'Jute_with_liner'
          ]
              .map((material) => DropdownMenuItem(
                    value: material,
                    child: Text(material.replaceAll('_', ' ')),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _packageMaterialController.text = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select package material';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _packSizeController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Pack Size',
            hintText: 'e.g., 500g, 1kg',
            prefixIcon: Icon(Icons.straighten),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter pack size';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _packCountController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of Packs',
            hintText: 'e.g., 100',
            prefixIcon: Icon(Icons.inventory),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of packs';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStorageFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Storage Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _storageTypeController,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Storage Type',
            hintText: 'e.g., Cold Storage, Warehouse',
            prefixIcon: Icon(Icons.warehouse),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter storage type';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _storageTemperatureController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Storage Temperature (°C)',
            hintText: 'e.g., 20',
            prefixIcon: Icon(Icons.thermostat),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter temperature';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _storageHumidityController,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Humidity (%)',
            hintText: 'e.g., 60',
            prefixIcon: Icon(Icons.water_drop),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter humidity';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Add Processing Stage',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.forestGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.forestGreen),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.forestGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Traceability Chain',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add all stages: Harvest → Drying → Grading → Packaging',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lot ID Display
            Text(
              'Lot ID: ${widget.lotId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.forestGreen,
              ),
            ),
            const SizedBox(height: 24),

            // Stage Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStageType,
              decoration: const InputDecoration(
                labelText: 'Stage Type *',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIconColor: AppTheme.forestGreen,
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                helperText: 'Select the processing stage type',
                helperStyle: TextStyle(color: Colors.black54),
              ),
              items: _stageTypes.map((stage) {
                return DropdownMenuItem(
                  value: stage['value'],
                  child: Text(
                    stage['label']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStageType = value;
                  _updateStageName();
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a stage type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Common Fields
            TextFormField(
              controller: _stageNameController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Stage Name *',
                hintText: 'e.g., Pepper Harvesting',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIconColor: AppTheme.forestGreen,
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stage name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Location *',
                hintText: 'e.g., Matara Processing Facility',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIconColor: AppTheme.forestGreen,
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _operatorController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Operator Name *',
                hintText: 'e.g., Processing Team A',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIconColor: AppTheme.forestGreen,
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter operator name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Stage Date *',
                  prefixIcon: Icon(Icons.calendar_today),
                  labelStyle: TextStyle(color: Colors.black87),
                  prefixIconColor: AppTheme.forestGreen,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_stageDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Stage-Specific Fields
            if (_selectedStageType != null) _buildStageSpecificFields(),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: Colors.black87),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g., Dried to EU export standards',
                labelStyle: TextStyle(color: Colors.black87),
                prefixIconColor: AppTheme.forestGreen,
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Processing Stage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
