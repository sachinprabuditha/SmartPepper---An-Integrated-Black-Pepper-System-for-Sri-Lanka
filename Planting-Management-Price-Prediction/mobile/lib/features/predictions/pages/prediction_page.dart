import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/prediction_input_model.dart';
import '../models/prediction_output_model.dart';
import '../services/prediction_service.dart';

class PredictionPage extends ConsumerStatefulWidget {
  const PredictionPage({super.key});

  @override
  ConsumerState<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends ConsumerState<PredictionPage> {
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
  final List<String> _locations = [
    'Colombo', 'Galle', 'Hambantota', 'Kandy', 'Kegalle', 
    'Kurunegala', 'Matale', 'Matara', 'Monaragala'
  ];
  
  final List<String> _grades = ['GR-1', 'GR-2', 'WHITE'];

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
      // Reset valuation state
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

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Prediction'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Market Data'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(_usdBuyController, 'USD Buy Rate', 'Enter rate'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(_usdSellController, 'USD Sell Rate', 'Enter rate'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildSectionTitle('Weather Conditions'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(_tempController, 'Temperature (°C)', 'e.g. 28.5'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(_precipController, 'Precipitation', 'e.g. 0.0'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _location,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                items: _locations.map((String loc) {
                  return DropdownMenuItem<String>(
                    value: loc,
                    child: Text(loc),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _location = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
                items: _grades.map((String g) {
                  return DropdownMenuItem<String>(
                    value: g,
                    child: Text(g),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _grade = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('PREDICT PRICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Prediction Results',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildResultRow('Highest Price', _result!.highestPrice),
                        const SizedBox(height: 12),
                        _buildResultRow('Average Price', _result!.averagePrice),
                        const SizedBox(height: 16),
                        Text(
                          'Currency: ${_result!.currency}',
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
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
                    label: const Text('Valuate Yield'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            side: BorderSide(color: Colors.blueGrey.shade100),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Valuate Your Yield',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Amount (kg)',
                                    hintText: 'e.g. 50.5',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.inventory_2_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Amount is required';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null) {
                                      return 'Please enter a valid number';
                                    }
                                    if (amount < 0) {
                                      return 'Amount cannot be negative';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        final amount = double.parse(_amountController.text);
                                        setState(() {
                                          // Round price to 2 decimal places to match UI display before calculation
                                          final roundedPrice = double.parse(_result!.averagePrice.toStringAsFixed(2));
                                          _calculatedBaseValue = roundedPrice * amount;
                                        });
                                      }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Calculate'),
                                ),
                                if (_calculatedBaseValue != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Estimated Total Value',
                                          style: TextStyle(fontSize: 14, color: Colors.black54),
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
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Invalid number';
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
