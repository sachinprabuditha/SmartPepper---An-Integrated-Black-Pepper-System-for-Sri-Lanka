import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/season_controller.dart';
import '../../plantation/controllers/plantation_controller.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/input_field.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/utils/validators.dart';

class CreateSeasonPage extends ConsumerStatefulWidget {
  final String userId;

  const CreateSeasonPage({super.key, required this.userId});

  @override
  ConsumerState<CreateSeasonPage> createState() => _CreateSeasonPageState();
}

class _CreateSeasonPageState extends ConsumerState<CreateSeasonPage> {
  final _formKey = GlobalKey<FormState>();
  final _seasonNameController = TextEditingController();
  String? _selectedFarmId;
  int? _startMonth;
  int? _startYear;
  int? _endMonth;
  int? _endYear;

  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years = List.generate(10, (index) => DateTime.now().year - 5 + index);

  @override
  void dispose() {
    _seasonNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() &&
        _selectedFarmId != null &&
        _startMonth != null &&
        _startYear != null &&
        _endMonth != null &&
        _endYear != null) {
      try {
        await ref.read(seasonControllerProvider.notifier).createSeason(
              seasonName: _seasonNameController.text.trim(),
              startMonth: _startMonth!,
              startYear: _startYear!,
              endMonth: _endMonth!,
              endYear: _endYear!,
              farmId: _selectedFarmId!,
              createdBy: widget.userId,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Season created successfully'),
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
        title: const Text('Create Season'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Farm Selection
              Consumer(
                builder: (context, ref, child) {
                  final farmsAsync = ref.watch(farmsProvider);
                  return farmsAsync.when(
                    data: (farms) {
                      if (farms.isEmpty) {
                        return const Card(
                          color: Colors.orange,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No farms available. Please create a farm first.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }
                      return DropdownField<String>(
                        label: 'Farm',
                        value: _selectedFarmId,
                        items: farms.map((farm) => DropdownMenuItem(
                          value: farm.id,
                          child: Text('${farm.farmName} (${farm.district})'),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFarmId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a farm';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error loading farms: $error'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Season Name',
                controller: _seasonNameController,
                validator: (value) => Validators.required(value, fieldName: 'Season name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownField<int>(
                      label: 'Start Month',
                      value: _startMonth,
                      items: _months
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(_getMonthName(month)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _startMonth = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownField<int>(
                      label: 'Start Year',
                      value: _startYear,
                      items: _years
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _startYear = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownField<int>(
                      label: 'End Month',
                      value: _endMonth,
                      items: _months
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(_getMonthName(month)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _endMonth = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownField<int>(
                      label: 'End Year',
                      value: _endYear,
                      items: _years
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _endYear = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create Season',
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

