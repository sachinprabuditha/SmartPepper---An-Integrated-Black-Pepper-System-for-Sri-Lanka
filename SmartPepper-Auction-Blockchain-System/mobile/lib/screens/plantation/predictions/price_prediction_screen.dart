import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../localization/app_localizations.dart';
import 'models/prediction_input_model.dart';
import 'models/prediction_output_model.dart';
import 'services/prediction_service.dart';
import 'services/exchange_service.dart';

class PricePredictionScreen extends StatefulWidget {
  const PricePredictionScreen({super.key});

  @override
  State<PricePredictionScreen> createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _usdRateController = TextEditingController();
  final _tempController = TextEditingController();
  final _precipController = TextEditingController();
  final _dateController = TextEditingController();

  // State variables
  DateTime? _selectedDate;
  String? _location;
  String? _grade;
  bool _isLoading = false;
  PredictionOutput? _result;
  String? _errorMessage;
  bool _isFetchingRates = false;

  // Yield Valuation state
  bool _showValuation = false;
  final TextEditingController _amountController = TextEditingController();
  double? _calculatedBaseValue;

  // Weather fetching state
  bool _isFetchingWeather = false;

  late final PredictionService _predictionService;
  late final ExchangeService _exchangeService;

  // Constants
  final List<String> _locations = const [
    'Colombo',
    'Galle',
    'Hambantota',
    'Kandy',
    'Kegalle',
    'Kurunegala',
    'Matale',
    'Matara',
    'Monaragala',
  ];

  final List<String> _grades = const ['GR-1', 'GR-2', 'WHITE'];

  @override
  void initState() {
    super.initState();
    _predictionService = PredictionService();
    _exchangeService = ExchangeService();
  }

  Future<void> _fetchLatestWeather(String location) async {
    if (!mounted) return;
    setState(() {
      _isFetchingWeather = true;
    });

    try {
      final weatherInfo = await _predictionService.getLatestWeather(location);

      if (!mounted) return;

      if (weatherInfo.isNotEmpty) {
        setState(() {
          _tempController.text = weatherInfo['temperature']?.toString() ?? '';
          _precipController.text =
              weatherInfo['precipitation']?.toString() ?? '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weather data updated for $location'),
            backgroundColor: AppTheme.forestGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Do not clear the text fields on error to allow manual entry, just show error optionally
      print('Failed to fetch weather: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingWeather = false;
        });
      }
    }
  }

  Future<void> _fetchExchangeRates() async {
    if (!mounted) return;
    setState(() {
      _isFetchingRates = true;
      _errorMessage = null;
    });

    try {
      final rateData = await _exchangeService.getUSDToLKR();

      if (!mounted) return;
      setState(() {
        _usdRateController.text = rateData.rate.toStringAsFixed(2);
        _isFetchingRates = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('USD Rates updated from ${rateData.source}'),
          backgroundColor: AppTheme.forestGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingRates = false;
        _errorMessage = "Could not fetch exchange rates: $e";
      });
    }
  }

  @override
  void dispose() {
    _usdRateController.dispose();
    _tempController.dispose();
    _precipController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _fetchExchangeRates();
    }
  }

  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _location == null || _grade == null) {
      setState(() {
        _errorMessage = context.tr('plantation_required');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
      _showValuation = false;
      _amountController.clear();
      _calculatedBaseValue = null;
    });

    try {
      final input = PredictionInput(
        usdRate: double.parse(_usdRateController.text),
        temperature: double.parse(_tempController.text),
        precipitation: double.parse(_precipController.text),
        date: _selectedDate!,
        location: _location!,
        grade: _grade!,
      );

      final result = await _predictionService.predictPrice(input);

      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('price_prediction_title')),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
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
              _buildSectionTitle(context.tr('session_date')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: context.tr('session_date'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today,
                      color: AppTheme.pepperGold),
                ),
                style: const TextStyle(color: Colors.white),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('plantation_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(
                      context.tr('price_prediction_market_data')),
                  if (_isFetchingRates)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.pepperGold,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.pepperGold, size: 20),
                      onPressed: _fetchExchangeRates,
                      tooltip: 'Refresh Exchange Rates',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                context,
                _usdRateController,
                'USD Rate',
                context.tr('price_prediction_enter_rate'),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context.tr('price_prediction_location')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _location,
                decoration: InputDecoration(
                  labelText: context.tr('price_prediction_location'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppTheme.deepEmerald,
                validator: (value) =>
                    value == null ? context.tr('plantation_required') : null,
                items: _locations
                    .map(
                      (loc) => DropdownMenuItem<String>(
                        value: loc,
                        child: Text(loc),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null && value != _location) {
                    setState(() {
                      _location = value;
                      _result = null;
                      _showValuation = false;
                      _amountController.clear();
                      _calculatedBaseValue = null;
                    });
                    _fetchLatestWeather(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(context.tr('price_prediction_weather')),
                  if (_isFetchingWeather)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.pepperGold,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.pepperGold, size: 20),
                      onPressed: () {
                        if (_location != null) _fetchLatestWeather(_location!);
                      },
                      tooltip: 'Refresh Weather',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      context,
                      _tempController,
                      context.tr('price_prediction_temperature'),
                      context.tr('price_prediction_hint_eg'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      context,
                      _precipController,
                      context.tr('price_prediction_precipitation'),
                      context.tr('price_prediction_hint_eg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(context.tr('price_prediction_grade')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: InputDecoration(
                  labelText: context.tr('price_prediction_grade'),
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppTheme.deepEmerald,
                validator: (value) =>
                    value == null ? context.tr('plantation_required') : null,
                items: _grades
                    .map(
                      (g) => DropdownMenuItem<String>(
                        value: g,
                        child: Text(g),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _grade = value ?? _grade;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pepperGold,
                  foregroundColor: AppTheme.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.tr('price_prediction_predict'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              if (_result != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          context.tr('price_prediction_results'),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.pepperGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildResultRow(
                          context.tr('price_prediction_highest'),
                          _result!.highestPrice,
                        ),
                        const SizedBox(height: 12),
                        _buildResultRow(
                          context.tr('price_prediction_average'),
                          _result!.averagePrice,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${context.tr('common_currency')}: ${_result!.currency}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_result != null && !_isLoading) ...[
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showValuation = !_showValuation;
                      });
                    },
                    icon: const Icon(Icons.calculate),
                    label: Text(context.tr('price_prediction_valuate')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showValuation
                      ? Card(
                          margin: const EdgeInsets.only(top: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.blueGrey.shade100,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.tr('price_prediction_valuate_title'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: context
                                        .tr('price_prediction_amount_kg'),
                                    hintText: context
                                        .tr('price_prediction_hint_eg_50'),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return context.tr(
                                          'price_prediction_amount_required');
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null) {
                                      return context
                                          .tr('price_prediction_valid_number');
                                    }
                                    if (amount < 0) {
                                      return context.tr(
                                          'price_prediction_amount_non_negative');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      final amount = double.parse(
                                        _amountController.text,
                                      );
                                      setState(() {
                                        final roundedPrice = double.parse(
                                          _result!.averagePrice
                                              .toStringAsFixed(2),
                                        );
                                        _calculatedBaseValue =
                                            roundedPrice * amount;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.pepperGold,
                                    foregroundColor: AppTheme.forestGreen,
                                  ),
                                  child: Text(
                                      context.tr('price_prediction_calculate')),
                                ),
                                if (_calculatedBaseValue != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          context.tr(
                                              'price_prediction_estimated_value'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs. ${NumberFormat('#,##0.00').format(_calculatedBaseValue)}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNumberField(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.tr('plantation_required');
        }
        if (double.tryParse(value) == null) {
          return context.tr('price_prediction_valid_number');
        }
        return null;
      },
    );
  }

  Widget _buildResultRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }
}
