import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as vanilla_provider;
import '../controllers/season_controller.dart';
import '../../plantation/controllers/plantation_controller.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/language_picker_button.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/dropdown_field.dart';
import '../../../../utils/validators.dart';

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
    final languageProvider = vanilla_provider.Provider.of<LanguageProvider>(context);
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
              Consumer(
                builder: (context, ref, child) {
                  final farmsAsync = ref.watch(farmsProvider);
                  return farmsAsync.when(
                    data: (farms) {
                      if (farms.isEmpty) {
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
                      return DropdownField<String>(
                        label: context.tr('plantation_farm'),
                        value: _selectedFarmId,
                        items: farms.map((farm) => DropdownMenuItem(
                          value: farm.id,
                          child: Text('${farm.farmName} (${farm.district.get(lang)})'),
                        )).toList(),
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
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '${context.tr('plantation_error_loading_farms')}: $error',
                        ),
                      ),
                    ),
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

