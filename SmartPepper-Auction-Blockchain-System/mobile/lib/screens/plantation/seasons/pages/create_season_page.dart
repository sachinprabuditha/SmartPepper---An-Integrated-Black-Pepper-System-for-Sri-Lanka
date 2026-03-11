import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/season_controller.dart';
import '../services/season_service.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../plantation/services/plantation_service.dart';
import '../../services/plantation_api_client.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/language_picker_button.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/dropdown_field.dart';
import '../../../../utils/validators.dart';

class CreateSeasonPage extends StatefulWidget {
  final String userId;

  const CreateSeasonPage({super.key, required this.userId});

  @override
  State<CreateSeasonPage> createState() => _CreateSeasonPageState();
}

class _CreateSeasonPageState extends State<CreateSeasonPage> {
  final _formKey = GlobalKey<FormState>();
  final _seasonNameController = TextEditingController();
  late Future<List<FarmRecord>> _farmsFuture;
  late PlantationService _plantationService;
  late SeasonController _seasonController;

  String? _selectedFarmId;
  int? _startMonth;
  int? _startYear;
  int? _endMonth;
  int? _endYear;

  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years =
      List.generate(10, (index) => DateTime.now().year - 5 + index);

  @override
  void initState() {
    super.initState();
    final apiClient = PlantationApiClient();
    _plantationService = PlantationService(apiClient);
    _seasonController = SeasonController(SeasonService(apiClient));
    _farmsFuture = _plantationService.getFarms();
  }

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
        await _seasonController.createSeason(
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
            SnackBar(
              content: Text(context.tr('plantation_season_created_success')),
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_create_season')),
        actions: const [
          LanguagePickerButton(),
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
              // Farm Selection
              FutureBuilder<List<FarmRecord>>(
                future: _farmsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '${context.tr('plantation_error_loading_farms')}: ${snapshot.error}',
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      color: Colors.orange,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.tr('plantation_no_farms_create_first'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final farms = snapshot.data!;
                  return DropdownField<String>(
                    label: context.tr('plantation_farm'),
                    value: _selectedFarmId,
                    items: farms
                        .map((farm) => DropdownMenuItem(
                              value: farm.id,
                              child: Text(
                                  '${farm.farmName} (${farm.district.get(lang)})'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFarmId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return context.tr('plantation_please_select_farm');
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              InputField(
                label: context.tr('plantation_season_name'),
                controller: _seasonNameController,
                validator: (value) => Validators.required(
                  value,
                  fieldName: context.tr('plantation_season_name'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownField<int>(
                      label: context.tr('plantation_start_month'),
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
                          return context.tr('plantation_required');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownField<int>(
                      label: context.tr('plantation_start_year'),
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
                          return context.tr('plantation_required');
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
                      label: context.tr('plantation_end_month'),
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
                          return context.tr('plantation_required');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownField<int>(
                      label: context.tr('plantation_end_year'),
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
                          return context.tr('plantation_required');
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: context.tr('plantation_create_season'),
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
