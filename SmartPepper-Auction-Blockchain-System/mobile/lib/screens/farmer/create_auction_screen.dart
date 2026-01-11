import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lot_provider.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';

class CreateAuctionScreen extends StatefulWidget {
  final Lot? preselectedLot;

  const CreateAuctionScreen({
    super.key,
    this.preselectedLot,
  });

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Form Controllers
  final _reservePriceController = TextEditingController();
  final _quantityController = TextEditingController();

  // Form State
  Lot? _selectedLot;
  int _durationDays = 7;
  List<String> _selectedDestinations = [];
  bool _loading = false;
  bool _checkingEligibility = false;

  // Eligibility Check Results
  Map<String, dynamic>? _eligibilityResult;
  bool _isEligible = false;

  // Available Destinations
  final List<Map<String, String>> _availableDestinations = [
    {'code': 'EU', 'name': 'European Union', 'flag': '🇪🇺'},
    {'code': 'USA', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'UAE', 'name': 'Middle East', 'flag': '🇦🇪'},
    {'code': 'UK', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
  ];

  // Governance Settings (from admin)
  List<Map<String, dynamic>> _durationOptions = [];
  List<Map<String, dynamic>> _templates = [];
  String? _selectedTemplateId;
  double _minReservePrice = 100; // LKR
  double _maxReservePrice = 1000000; // LKR
  double _defaultBidIncrement = 5.0; // percentage
  bool _requiresAdminApproval = false;
  bool _loadingGovernance = true;

  // Exchange rate (LKR to ETH) - fetched from backend
  double _lkrToEthRate =
      0.0000031; // Default: 1 LKR ≈ 0.0000031 ETH (~320 LKR per USD, ~3100 USD per ETH)

  @override
  void initState() {
    super.initState();
    _fetchGovernanceSettings();
    if (widget.preselectedLot != null) {
      _selectedLot = widget.preselectedLot;
      _quantityController.text = widget.preselectedLot!.quantity.toString();
      _checkAuctionEligibility();
    }
  }

  /// Fetch governance settings and templates from admin
  Future<void> _fetchGovernanceSettings() async {
    setState(() => _loadingGovernance = true);

    try {
      final settingsResponse = await _apiService.get('/governance/settings');
      final templatesResponse = await _apiService.get('/governance/templates');

      setState(() {
        // Parse allowed durations
        final allowedDurations = List<int>.from(
            settingsResponse['allowedDurations'] ?? [24, 48, 72, 96, 168]);
        _durationOptions = allowedDurations.map((hours) {
          final days = hours ~/ 24;
          return {
            'hours': hours,
            'days': days,
            'label': _formatDuration(hours),
            'subtitle': _getDurationSubtitle(days),
          };
        }).toList();

        // Set default duration to first option
        if (_durationOptions.isNotEmpty) {
          _durationDays = _durationOptions.first['days'];
        }

        // Parse settings
        _minReservePrice =
            (settingsResponse['minReservePrice'] ?? 100).toDouble();
        _maxReservePrice =
            (settingsResponse['maxReservePrice'] ?? 1000000).toDouble();

        // Get exchange rate
        _lkrToEthRate =
            (settingsResponse['lkrToEthRate'] ?? 0.0000031).toDouble();
        _defaultBidIncrement =
            (settingsResponse['defaultBidIncrement'] ?? 5.0).toDouble();
        _requiresAdminApproval =
            settingsResponse['requiresAdminApproval'] ?? false;

        // Parse templates
        _templates = List<Map<String, dynamic>>.from(
            templatesResponse['templates'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load governance settings: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // Set fallback defaults
      setState(() {
        _durationOptions = [
          {'days': 1, 'label': '1 Day', 'subtitle': 'Quick sale', 'hours': 24},
          {
            'days': 3,
            'label': '3 Days',
            'subtitle': 'Short auction',
            'hours': 72
          },
          {'days': 7, 'label': '7 Days', 'subtitle': 'Standard', 'hours': 168},
        ];
        _durationDays = 7;
      });
    } finally {
      setState(() => _loadingGovernance = false);
    }
  }

  String _formatDuration(int hours) {
    if (hours < 24) return '$hours Hours';
    final days = hours ~/ 24;
    return '$days Day${days > 1 ? 's' : ''}';
  }

  String _getDurationSubtitle(int days) {
    if (days <= 1) return 'Quick sale';
    if (days <= 3) return 'Short auction';
    if (days <= 7) return 'Standard duration';
    if (days <= 14) return 'Extended bidding';
    return 'Maximum duration';
  }

  @override
  void dispose() {
    _reservePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Check if the lot is eligible for auction creation
  /// Validates all preconditions before allowing auction creation
  Future<void> _checkAuctionEligibility() async {
    if (_selectedLot == null) return;

    setState(() {
      _checkingEligibility = true;
      _eligibilityResult = null;
      _isEligible = false;
    });

    try {
      final response = await _apiService.get(
        '/auctions/check-eligibility/${_selectedLot!.lotId}',
      );

      setState(() {
        _eligibilityResult = response;
        _isEligible = response['eligible'] == true;
      });

      if (!_isEligible && mounted) {
        _showEligibilityDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking eligibility: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingEligibility = false);
      }
    }
  }

  void _showEligibilityDialog() {
    final reasons = _eligibilityResult?['reasons'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Auction Eligibility Check'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This lot cannot be auctioned yet. Please complete the following requirements:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAuctionEligibility(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
            ),
            child: const Text('Retry Check'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAuction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a lot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This lot is not eligible for auction. Please check requirements.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Auction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to create this auction?'),
            const SizedBox(height: 16),
            const Text('Summary:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Lot: ${_selectedLot!.lotId}'),
            Text('Reserve Price: ${_reservePriceController.text} LKR'),
            Text(
              '(≈ ${(double.parse(_reservePriceController.text) * _lkrToEthRate).toStringAsFixed(4)} ETH)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text('Duration: $_durationDays days'),
            Text('Quantity: ${_quantityController.text} kg'),
            if (_selectedDestinations.isNotEmpty)
              Text('Export to: ${_selectedDestinations.join(", ")}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[700]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once created, auction terms cannot be changed.',
                      style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestGreen,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Calculate start and end times
      // Start auction in 1 minute (allows time for blockchain transaction)
      final startTime = DateTime.now().add(const Duration(minutes: 5));
      final endTime = startTime.add(Duration(days: _durationDays));

      final auctionData = {
        'lotId': _selectedLot!.lotId,
        'farmerAddress': authProvider.user?.walletAddress ?? '',
        'reservePrice': double.parse(_reservePriceController.text),
        'currency': 'LKR', // Farmer inputs in LKR
        'reservePriceEth': double.parse(_reservePriceController.text) *
            _lkrToEthRate, // Converted for blockchain
        'quantity': double.parse(_quantityController.text),
        'duration': _durationDays,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'preferredDestinations': _selectedDestinations,
        'templateId': _selectedTemplateId, // Governance template
      };

      final response = await _apiService.post('/auctions', auctionData);

      if (mounted) {
        Navigator.pop(context);

        // Check if auction requires approval
        final auctionStatus = response['auction']?['status'];
        if (auctionStatus == 'pending_approval') {
          _showApprovalPendingDialog();
        } else {
          _showSuccessDialog(response);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating auction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Pending Admin Approval'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your auction has been submitted and is pending admin approval.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(height: 8),
                  const Text(
                    'This auction requires admin review due to:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('• Premium lot value'),
                  const Text('• Extended duration'),
                  const Text('• System governance rules'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You will be notified when the admin approves or rejects your auction.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Auction Created Successfully! 🎉',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Status: ${response['auction']?['status'] ?? 'Scheduled'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lotProvider = context.watch<LotProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Auction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.forestGreen),
                  SizedBox(height: 16),
                  Text('Creating auction on blockchain...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // Lot Selection
                    _buildSectionTitle('1. Select Your Lot'),
                    const SizedBox(height: 12),
                    if (_selectedLot != null)
                      _buildSelectedLotCard()
                    else
                      _buildLotSelector(lotProvider),

                    if (_selectedLot != null && _checkingEligibility)
                      _buildEligibilityCheckingCard(),

                    if (_selectedLot != null &&
                        !_isEligible &&
                        _eligibilityResult != null)
                      _buildEligibilityFailedCard(),

                    if (_selectedLot != null && _isEligible) ...[
                      const SizedBox(height: 24),
                      _buildEligibilityPassedCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('2. Set Reserve Price'),
                      const SizedBox(height: 12),
                      _buildReservePriceField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('3. Select Auction Duration'),
                      const SizedBox(height: 12),
                      _buildDurationSelector(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('4. Quantity to Auction'),
                      const SizedBox(height: 12),
                      _buildQuantityField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('5. Export Destinations (Optional)'),
                      const SizedBox(height: 12),
                      _buildDestinationSelector(),
                      const SizedBox(height: 32),
                      _buildCreateButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.forestGreen.withOpacity(0.1),
            Colors.blue.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.forestGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.forestGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gavel, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blockchain-Secured Auction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Transparent, immutable, and fair bidding',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(Icons.lock, 'Secure'),
              _buildInfoItem(Icons.verified, 'Verified'),
              _buildInfoItem(Icons.trending_up, 'Competitive'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.forestGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.forestGreen,
      ),
    );
  }

  Widget _buildLotSelector(LotProvider lotProvider) {
    final eligibleLots = lotProvider.lots
        .where((lot) => lot.status == 'approved' || lot.status == 'available')
        .toList();

    if (eligibleLots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                color: Colors.orange[700], size: 48),
            const SizedBox(height: 12),
            Text(
              'No Eligible Lots',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need approved lots to create an auction. Please create and get approval for your lots first.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.orange[800]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: eligibleLots.map((lot) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.forestGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: AppTheme.forestGreen),
            ),
            title: Text(
              lot.lotId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                Text('${lot.variety} • ${lot.quantity} kg • ${lot.quality}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() => _selectedLot = lot);
              _quantityController.text = lot.quantity.toString();
              _checkAuctionEligibility();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedLotCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppTheme.forestGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLot!.lotId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedLot!.variety,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedLot = null;
                      _isEligible = false;
                      _eligibilityResult = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildLotDetailRow('Quality', _selectedLot!.quality ?? 'N/A'),
            _buildLotDetailRow('Quantity', '${_selectedLot!.quantity} kg'),
            _buildLotDetailRow('Origin', _selectedLot!.origin ?? 'N/A'),
            _buildLotDetailRow('Status', _selectedLot!.status.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildLotDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityCheckingCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checking Auction Eligibility...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verifying compliance, certificates, and lot status',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityFailedCard() {
    final reasons = _eligibilityResult?['reasons'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Not Eligible for Auction',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ...reasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkAuctionEligibility,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Check'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityPassedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 32),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lot Eligible for Auction ✓',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'All preconditions met. You can proceed with auction creation.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservePriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _reservePriceController,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            setState(() {}); // Refresh to show ETH conversion
          },
          decoration: InputDecoration(
            labelText: 'Reserve Price (LKR) *',
            labelStyle: const TextStyle(color: Colors.black87),
            hintText: 'Min: $_minReservePrice, Max: $_maxReservePrice LKR',
            prefixIcon:
                const Icon(Icons.attach_money, color: AppTheme.forestGreen),
            suffixText: 'LKR',
            helperText:
                'Price range: $_minReservePrice - $_maxReservePrice LKR (per lot)',
            helperMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.forestGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter reserve price';
            }
            final price = double.tryParse(value);
            if (price == null || price <= 0) {
              return 'Please enter a valid price';
            }
            // Governance validation
            if (price < _minReservePrice) {
              return 'Price must be at least $_minReservePrice LKR';
            }
            if (price > _maxReservePrice) {
              return 'Price cannot exceed $_maxReservePrice LKR';
            }
            return null;
          },
        ),
        // Show ETH conversion
        if (_reservePriceController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  'Equivalent: ${((double.tryParse(_reservePriceController.text) ?? 0) * _lkrToEthRate).toStringAsFixed(4)} ETH',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      children: _durationOptions.map((option) {
        final isSelected = _durationDays == option['days'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color:
              isSelected ? AppTheme.forestGreen.withOpacity(0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppTheme.forestGreen : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.schedule,
              color: isSelected ? AppTheme.forestGreen : Colors.grey,
            ),
            title: Text(
              option['label'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              option['subtitle'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.forestGreen)
                : null,
            onTap: () {
              setState(() => _durationDays = option['days']);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Quantity to Auction *',
        labelStyle: const TextStyle(color: Colors.black87),
        hintText: 'Enter quantity in kg',
        prefixIcon: const Icon(Icons.scale, color: AppTheme.forestGreen),
        suffixText: 'kg',
        helperText: 'Total available: ${_selectedLot?.quantity ?? 0} kg',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.forestGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter quantity';
        }
        final quantity = double.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'Please enter a valid quantity';
        }
        if (_selectedLot != null && quantity > _selectedLot!.quantity) {
          return 'Cannot exceed available quantity';
        }
        return null;
      },
    );
  }

  Widget _buildDestinationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select preferred export markets (helps target the right buyers)',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableDestinations.map((dest) {
            final isSelected = _selectedDestinations.contains(dest['code']);
            return FilterChip(
              label: Text('${dest['flag']} ${dest['name']}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDestinations.add(dest['code']!);
                  } else {
                    _selectedDestinations.remove(dest['code']);
                  }
                });
              },
              selectedColor: AppTheme.forestGreen.withOpacity(0.2),
              checkmarkColor: AppTheme.forestGreen,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isEligible ? _createAuction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.forestGreen,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Create Auction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
