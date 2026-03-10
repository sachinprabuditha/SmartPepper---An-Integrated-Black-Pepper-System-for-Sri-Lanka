import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season_model.dart';
import '../services/season_service.dart';
import '../controllers/season_controller.dart';
import '../../plantation/models/farm_record_model.dart';
import '../../plantation/services/plantation_service.dart';
import '../../services/plantation_api_client.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../widgets/input_field.dart';
import '../../../../widgets/dropdown_field.dart';

class EditSeasonPage extends StatefulWidget {
  final String seasonId;

  const EditSeasonPage({super.key, required this.seasonId});

  @override
  State<EditSeasonPage> createState() => _EditSeasonPageState();
}

class _EditSeasonPageState extends State<EditSeasonPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _seasonNameController;
  late Future<SeasonModel> _seasonFuture;
  late Future<List<FarmRecord>> _farmsFuture;
  late SeasonService _seasonService;
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
    _seasonNameController = TextEditingController();
    final apiClient = PlantationApiClient();
    _seasonService = SeasonService(apiClient);
    _plantationService = PlantationService(apiClient);
    _seasonController = SeasonController(_seasonService);

    _seasonFuture = _seasonService.getSeasonById(widget.seasonId);
    _farmsFuture = _plantationService.getFarms();
  }

  @override
  void dispose() {
    _seasonNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _seasonController.updateSeason(
          seasonId: widget.seasonId,
          seasonName: _seasonNameController.text.trim().isNotEmpty
              ? _seasonNameController.text.trim()
              : null,
          startMonth: _startMonth,
          startYear: _startYear,
          endMonth: _endMonth,
          endYear: _endYear,
          farmId: _selectedFarmId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('plantation_season_updated_success')),
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
        title: Text(context.tr('plantation_edit_season')),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<SeasonModel>(
        future: _seasonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                  '${context.tr('common_error')}: ${snapshot.error.toString()}'),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No Data'));
          }

          final season = snapshot.data!;
          // Initialize controllers only once when data is loaded
          if (_seasonNameController.text.isEmpty &&
              season.seasonName.isNotEmpty) {
            _seasonNameController.text = season.seasonName;
          }
          _selectedFarmId ??= season.farmId;
          _startMonth ??= season.startMonth;
          _startYear ??= season.startYear;
          _endMonth ??= season.endMonth;
          _endYear ??= season.endYear;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Farm Selection
                  FutureBuilder<List<FarmRecord>>(
                    future: _farmsFuture,
                    builder: (context, farmsSnapshot) {
                      if (farmsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      } else if (farmsSnapshot.hasError) {
                        return Card(
                          color: Colors.red[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '${context.tr('plantation_error_loading_farms')}: ${farmsSnapshot.error}',
                            ),
                          ),
                        );
                      } else if (!farmsSnapshot.hasData ||
                          farmsSnapshot.data!.isEmpty) {
                        return Card(
                          color: Colors.orange,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              context.tr('plantation_no_farms_available'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }

                      final farms = farmsSnapshot.data!;
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
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InputField(
                    label: context.tr('plantation_season_name'),
                    controller: _seasonNameController,
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: context.tr('plantation_update_season'),
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ),
          );
        },
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
