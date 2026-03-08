import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as vanilla_provider;

import '../../../config/theme.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/language_picker_button.dart';
import 'models/prediction_input_model.dart';
import 'models/prediction_output_model.dart';
import 'services/prediction_service.dart';

class PricePredictionScreen extends ConsumerStatefulWidget {
  const PricePredictionScreen({super.key});

  @override
  ConsumerState<PricePredictionScreen> createState() =>
      _PricePredictionScreenState();
}

class _PricePredictionScreenState
    extends ConsumerState<PricePredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _usdBuyController = TextEditingController();
  final _usdSellController = TextEditingController();
  final _tempController = TextEditingController();
  final _precipController = TextEditingController();
  final _dateController = TextEditingController();

  // State variables
  DateTime _selectedDate = DateTime.now();
  String _location = 'Colombo';
  String _grade = 'GR-2';
  bool _isLoading = false;
  PredictionOutput? _result;
  String? _errorMessage;

  // Yield Valuation state
  bool _showValuation = false;
  final TextEditingController _amountController = TextEditingController();
  double? _calculatedBaseValue;

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
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _usdBuyController.dispose();
    _usdSellController.dispose();
    _tempController.dispose();
    _precipController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) return;

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
        usdBuyRate: double.parse(_usdBuyController.text),
        usdSellRate: double.parse(_usdSellController.text),
        temperature: double.parse(_tempController.text),
        precipitation: double.parse(_precipController.text),
        date: _selectedDate,
        location: _location,
        grade: _grade,
      );

      final service = ref.read(predictionServiceProvider);
      final result = await service.predictPrice(input);

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
    final languageProvider =
        vanilla_provider.Provider.of<LanguageProvider>(context);
    final lang = languageProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Price Prediction' : 'මිල අනාවැකි'),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
        actions: const [
          LanguagePickerButton(iconColor: AppTheme.pepperGold),
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
              _buildSectionTitle(lang == 'en' ? 'Market Data' : 'වෙළඳ දත්ත'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      _usdBuyController,
                      lang == 'en' ? 'USD Buy Rate' : 'USD මිලදී ගැනීමේ අනුපාතය',
                      lang == 'en' ? 'Enter rate' : 'අනුපාතය ඇතුළත් කරන්න',
                      lang: lang,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      _usdSellController,
                      lang == 'en' ? 'USD Sell Rate' : 'USD විකිණීමේ අනුපාතය',
                      lang == 'en' ? 'Enter rate' : 'අනුපාතය ඇතුළත් කරන්න',
                      lang: lang,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(
                lang == 'en' ? 'Weather Conditions' : 'කාලගුණ තත්ත්වය',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      _tempController,
                      lang == 'en' ? 'Temperature (°C)' : 'උෂ්ණත්වය (°C)',
                      lang == 'en' ? 'e.g. 28.5' : 'උදා: 28.5',
                      lang: lang,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      _precipController,
                      lang == 'en' ? 'Precipitation' : 'වර්ෂාපතනය',
                      lang == 'en' ? 'e.g. 0.0' : 'උදා: 0.0',
                      lang: lang,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionTitle(lang == 'en' ? 'Details' : 'විස්තර'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: lang == 'en' ? 'Date' : 'දිනය',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _location,
                decoration: InputDecoration(
                  labelText: lang == 'en' ? 'Location' : 'ස්ථානය',
                  border: const OutlineInputBorder(),
                ),
                items: _locations
                    .map(
                      (loc) => DropdownMenuItem<String>(
                        value: loc,
                        child: Text(loc),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _location = value ?? _location;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _grade,
                decoration: InputDecoration(
                  labelText: lang == 'en' ? 'Grade' : 'ශ්‍රේණිය',
                  border: const OutlineInputBorder(),
                ),
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
                        lang == 'en' ? 'PREDICT PRICE' : 'මිල අනාවැකි කරන්න',
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
                          lang == 'en' ? 'Prediction Results' : 'අනාවැකි ප්‍රතිඵල',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppTheme.pepperGold,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildResultRow(
                          lang == 'en' ? 'Highest Price' : 'ඉහළම මිල',
                          _result!.highestPrice,
                        ),
                        const SizedBox(height: 12),
                        _buildResultRow(
                          lang == 'en' ? 'Average Price' : 'සාමාන්‍ය මිල',
                          _result!.averagePrice,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${lang == 'en' ? 'Currency' : 'මුදල් ඒකකය'}: ${_result!.currency}',
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
                    label: Text(lang == 'en' ? 'Valuate Yield' : 'අස්වැන්න අගය ගණනය කරන්න'),
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  lang == 'en' ? 'Valuate Your Yield' : 'ඔබේ අස්වැන්න අගය ගණනය කරන්න',
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
                                    labelText: lang == 'en' ? 'Amount (kg)' : 'ප්‍රමාණය (කි.ග්‍රෑ.)',
                                    hintText: lang == 'en' ? 'e.g. 50.5' : 'උදා: 50.5',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return lang == 'en'
                                          ? 'Amount is required'
                                          : 'ප්‍රමාණය අත්‍යවශ්‍යයි';
                                    }
                                    final amount =
                                        double.tryParse(value);
                                    if (amount == null) {
                                      return lang == 'en'
                                          ? 'Please enter a valid number'
                                          : 'කරුණාකර වලංගු අංකයක් ඇතුළත් කරන්න';
                                    }
                                    if (amount < 0) {
                                      return lang == 'en'
                                          ? 'Amount cannot be negative'
                                          : 'ප්‍රමාණය ඍණ විය නොහැක';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!
                                        .validate()) {
                                      final amount = double.parse(
                                        _amountController.text,
                                      );
                                      setState(() {
                                        final roundedPrice =
                                            double.parse(
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
                                  child: Text(lang == 'en' ? 'Calculate' : 'ගණනය කරන්න'),
                                ),
                                if (_calculatedBaseValue != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          lang == 'en'
                                              ? 'Estimated Total Value'
                                              : 'ඇස්තමේන්තු මුළු වටිනාකම',
                                          style: TextStyle(
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
                                            color:
                                                Colors.green.shade700,
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
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    String hint, {
    required String lang,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return lang == 'en' ? 'Required' : 'අත්‍යවශ්‍යයි';
        }
        if (double.tryParse(value) == null) {
          return lang == 'en' ? 'Invalid number' : 'වලංගු නොවන අංකයක්';
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

