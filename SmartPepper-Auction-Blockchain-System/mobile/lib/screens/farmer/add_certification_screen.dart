import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AddCertificationScreen extends StatefulWidget {
  final String lotId;

  const AddCertificationScreen({super.key, required this.lotId});

  @override
  State<AddCertificationScreen> createState() => _AddCertificationScreenState();
}

class _AddCertificationScreenState extends State<AddCertificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _certNumberController = TextEditingController();
  final _issuerController = TextEditingController();

  String _selectedCertType = 'organic';
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  final List<Map<String, String>> _certTypes = [
    {'value': 'organic', 'label': 'Organic Certification'},
    {'value': 'fumigation', 'label': 'Fumigation Certificate'},
    {'value': 'quality', 'label': 'Quality Certificate'},
    {'value': 'export', 'label': 'Export License'},
    {'value': 'phytosanitary', 'label': 'Phytosanitary Certificate'},
    {'value': 'pesticide_test', 'label': 'Pesticide Test Report'},
    {'value': 'halal', 'label': 'Halal Certification'},
    {'value': 'origin', 'label': 'Certificate of Origin'},
  ];

  @override
  void dispose() {
    _certNumberController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          // Auto-adjust expiry to 1 year after issue
          if (_expiryDate.isBefore(picked)) {
            _expiryDate = picked.add(const Duration(days: 365));
          }
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submitCertification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_expiryDate.isBefore(_issueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date must be after issue date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.post('/certifications', {
        'lotId': widget.lotId,
        'certType': _selectedCertType,
        'certNumber': _certNumberController.text.trim(),
        'issuer': _issuerController.text.trim(),
        'issueDate': _issueDate.toIso8601String().split('T')[0],
        'expiryDate': _expiryDate.toIso8601String().split('T')[0],
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Certification added successfully',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.forestGreen,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to add certification');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Certification'),
        backgroundColor: AppTheme.forestGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add certifications to improve compliance and traceability',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Certificate Type
              const Text(
                'Certificate Type *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCertType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                items: _certTypes.map((cert) {
                  return DropdownMenuItem(
                    value: cert['value'],
                    child: Text(cert['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCertType = value!);
                },
              ),
              const SizedBox(height: 20),

              // Certificate Number
              const Text(
                'Certificate Number *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _certNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g., ORG-2025-001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Certificate number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Issuer
              const Text(
                'Issuing Authority *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _issuerController,
                decoration: InputDecoration(
                  hintText: 'e.g., Sri Lanka Organic Certification',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Issuing authority is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Issue Date
              const Text(
                'Issue Date *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        '${_issueDate.year}-${_issueDate.month.toString().padLeft(2, '0')}-${_issueDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Expiry Date
              const Text(
                'Expiry Date *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Text(
                        '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCertification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Certification',
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
      ),
    );
  }
}
