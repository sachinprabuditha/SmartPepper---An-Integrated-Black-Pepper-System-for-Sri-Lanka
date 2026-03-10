import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/lot_provider.dart';
// Removed blockchain_service import - minting now done via backend API
import '../../services/ipfs_service.dart';
import '../../services/qr_nfc_service.dart';
import '../../services/storage_service.dart';
import '../../services/quality_grading_service.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';

class CreateLotScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillData;

  const CreateLotScreen({super.key, this.prefillData});

  @override
  State<CreateLotScreen> createState() => _CreateLotScreenState();
}

class _CreateLotScreenState extends State<CreateLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _varietyController = TextEditingController();
  final _quantityController = TextEditingController();
  final _harvestDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _farmAddressController = TextEditingController();
  final _farmerNameController = TextEditingController();

  String _selectedQuality = 'AAA';
  DateTime? _selectedHarvestDate;
  List<File> _certificateImages = [];
  List<File> _lotPictures = [];
  bool _isLoading = false;

  // ML Quality Grading states
  QualityGradingRecord? _mlQualityGrading;
  bool _isLoadingQualityGrading = false;
  bool _useMLGrade = false;

  final List<String> _qualityGrades = ['AAA', 'AA', 'A', 'B'];

  // Pepper varieties fetched from Firebase
  List<Map<String, dynamic>> _pepperVarieties = [];
  bool _isLoadingVarieties = false;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadFarmerInfo();
    _fetchPepperVarieties();
    _applyPrefillData();
  }

  Future<void> _loadFarmerInfo() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      setState(() {
        _farmerNameController.text = authProvider.user!.name;
        // Get language preference if available
        _currentLanguage = authProvider.user!.language ?? 'en';
      });
    }
  }

  Future<void> _fetchPepperVarieties() async {
    setState(() {
      _isLoadingVarieties = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final varieties = await authProvider.apiService.getPepperVarietyNames(
        language: _currentLanguage,
      );

      setState(() {
        _pepperVarieties = varieties;
        _isLoadingVarieties = false;
      });
    } catch (e) {
      print('Error fetching pepper varieties: $e');
      setState(() {
        _isLoadingVarieties = false;
      });

      // Set fallback hardcoded varieties if API fails
      setState(() {
        _pepperVarieties = [
          {
            'id': 'black_premium',
            'name': 'Black Pepper Premium',
            'nameEn': 'Black Pepper Premium',
            'nameSi': 'කළු ගම්මිරිස් ප්‍රිමියම්'
          },
          {
            'id': 'black_standard',
            'name': 'Black Pepper Standard',
            'nameEn': 'Black Pepper Standard',
            'nameSi': 'කළු ගම්මිරිස් සාමාන්‍ය'
          },
          {
            'id': 'black_organic',
            'name': 'Black Pepper Organic',
            'nameEn': 'Black Pepper Organic',
            'nameSi': 'කළු ගම්මිරිස් කාබනික'
          },
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default varieties. ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _applyPrefillData() {
    if (widget.prefillData != null) {
      final data = widget.prefillData!;

      if (data['variety'] != null) {
        final variety = data['variety'] as String;
        // Check if variety exists in our list (by name or id)
        final varietyExists = _pepperVarieties.any((v) =>
            v['name'] == variety ||
            v['nameEn'] == variety ||
            v['id'] == variety);
        if (varietyExists) {
          _varietyController.text = variety;
        }
      }

      if (data['quantity'] != null) {
        _quantityController.text = data['quantity'].toString();
      }

      if (data['quality'] != null) {
        final quality = data['quality'] as String;
        if (_qualityGrades.contains(quality)) {
          setState(() {
            _selectedQuality = quality;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _quantityController.dispose();
    _harvestDateController.dispose();
    _descriptionController.dispose();
    _farmAddressController.dispose();
    _farmerNameController.dispose();
    super.dispose();
  }

  Future<void> _selectHarvestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.forestGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedHarvestDate = picked;
        _harvestDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickCertificateImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.tr('common_take_photo')),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _certificateImages.add(File(image.path));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.tr('common_choose_gallery')),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile> images = await picker.pickMultiImage(
                  imageQuality: 80,
                );
                if (images.isNotEmpty) {
                  setState(() {
                    _certificateImages.addAll(images.map((e) => File(e.path)));
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLotPictures() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.tr('common_take_photo')),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _lotPictures.add(File(image.path));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.tr('common_choose_gallery')),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile> images = await picker.pickMultiImage(
                  imageQuality: 80,
                );
                if (images.isNotEmpty) {
                  setState(() {
                    _lotPictures.addAll(images.map((e) => File(e.path)));
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeCertificateImage(int index) {
    setState(() {
      _certificateImages.removeAt(index);
    });
  }

  void _removeLotPicture(int index) {
    setState(() {
      _lotPictures.removeAt(index);
    });
  }

  Future<void> _fetchMLQualityGrading() async {
    setState(() {
      _isLoadingQualityGrading = true;
    });

    try {
      final qualityGradingService = QualityGradingService();
      final latestGrading =
          await qualityGradingService.getLatestQualityGrading();

      if (latestGrading != null) {
        setState(() {
          _mlQualityGrading = latestGrading;
          _useMLGrade = true;
          // Auto-select the ML grade
          _selectedQuality = latestGrading.getMappedGrade();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ML Quality Grade fetched: ${latestGrading.getGradeDisplay()}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No ML quality grading found. Please use the Quality Grading system first.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to fetch ML quality grading: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingQualityGrading = false;
      });
    }
  }

  Future<void> _submitLot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedHarvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('validation_harvest_date')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate lot pictures (mandatory)
    if (_lotPictures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('validation_lot_pictures')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate certificates (mandatory)
    if (_certificateImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('validation_certificates')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final lotProvider = context.read<LotProvider>();
      final ipfsService = context.read<IpfsService>();
      final qrNfcService = QrNfcService();
      final storageService = context.read<StorageService>();

      // Check if user has wallet
      final farmerAddress = authProvider.user?.walletAddress;
      if (farmerAddress == null || farmerAddress.isEmpty) {
        throw Exception('Wallet address not found. Please contact support.');
      }

      // We no longer need the private key since minting is done via backend API
      // Remove private key requirement
      /*
      String? privateKey = await storageService.getPrivateKey();
      if (privateKey == null) {
        if (mounted) {
          privateKey = await _showImportWalletDialog();
          if (privateKey == null || privateKey.isEmpty) {
            throw Exception(
                'Private key is required to create lots on blockchain');
          }
          await storageService.savePrivateKey(privateKey);
        } else {
          throw Exception('Private key not found');
        }
      }
      */

      // Generate unique lot ID
      final lotId = 'LOT-${DateTime.now().millisecondsSinceEpoch}';

      // Show progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Step 1/4: Uploading certificates to IPFS...'),
              ],
            ),
            duration: Duration(days: 1),
          ),
        );
      }

      // Step 1: Upload certificates and lot pictures to IPFS
      List<String> certificateIpfsHashes = [];
      List<String> lotPictureHashes = [];

      if (_certificateImages.isNotEmpty) {
        certificateIpfsHashes =
            await ipfsService.uploadMultipleFiles(_certificateImages);
      }

      if (_lotPictures.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading lot pictures to IPFS...'),
                ],
              ),
              duration: Duration(days: 1),
            ),
          );
        }
        lotPictureHashes = await ipfsService.uploadMultipleFiles(_lotPictures);
      }

      // Step 2: Create and upload metadata to IPFS
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Step 2/4: Creating metadata...'),
              ],
            ),
            duration: Duration(days: 1),
          ),
        );
      }

      final metadata = {
        'lotId': lotId,
        'farmerName': authProvider.user?.name ?? 'Unknown',
        'variety': _varietyController.text.trim(),
        'quantity': double.parse(_quantityController.text.trim()),
        'quality': _selectedQuality,
        'harvestDate': _selectedHarvestDate!.toIso8601String(),
        'origin': 'Sri Lanka',
        'farmLocation': _farmAddressController.text.trim().isNotEmpty
            ? _farmAddressController.text.trim()
            : authProvider.user?.name ?? 'Unknown Farm',
        'farmAddress': _farmAddressController.text.trim(),
        'certificates': certificateIpfsHashes,
        'lotPictures': lotPictureHashes,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final metadataUri = await ipfsService.uploadJson(metadata);

      // Step 3: Mint NFT passport via backend API
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Step 3/4: Minting NFT passport...'),
              ],
            ),
            duration: Duration(days: 1),
          ),
        );
      }

      // Call backend API to mint passport instead of direct blockchain call
      final apiService =
          Provider.of<AuthProvider>(context, listen: false).apiService;
      final mintResponse = await apiService.mintPassport({
        'lotId': lotId,
        'farmer': farmerAddress,
        'origin': 'Sri Lanka',
        'variety': _varietyController.text.trim(),
        'quantity': double.parse(_quantityController.text.trim()).toInt(),
        'harvestDate':
            (_selectedHarvestDate!.millisecondsSinceEpoch ~/ 1000).toString(),
        'certificateHash': certificateIpfsHashes.isNotEmpty
            ? certificateIpfsHashes.first
            : '0x0000000000000000000000000000000000000000000000000000000000000000',
        'metadataURI': 'ipfs://$metadataUri',
      });

      // Extract blockchain result from API response
      final blockchainResult = {
        'txHash': mintResponse['data']['txHash'] ??
            '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        'tokenId': mintResponse['data']['tokenId'] ?? 0,
        'blockNumber': mintResponse['data']['blockNumber'] ?? 0,
      };

      // Step 4: Generate QR code
      final qrData = qrNfcService.generateQrData(
        lotId: lotId,
        farmerId: authProvider.user!.id,
        farmerName: authProvider.user!.name,
        variety: _varietyController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        quality: _selectedQuality,
        harvestDate: _selectedHarvestDate!,
        blockchainHash: blockchainResult['txHash'] as String,
      );

      // Step 5: Save to backend
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Step 4/4: Saving to database...'),
              ],
            ),
            duration: Duration(days: 1),
          ),
        );
      }

      final lotData = {
        'lotId': lotId,
        'farmerAddress': farmerAddress,
        'farmerName': authProvider.user?.name ?? 'Unknown',
        'farmerEmail': authProvider.user?.email,
        'farmerPhone': authProvider.user?.phone,
        'variety': _varietyController.text.trim(),
        'quantity': double.parse(_quantityController.text.trim()),
        'quality': _selectedQuality,
        'harvestDate': _selectedHarvestDate!.toIso8601String(),
        'origin': 'Sri Lanka',
        'farmLocation': _farmAddressController.text.trim().isNotEmpty
            ? _farmAddressController.text.trim()
            : authProvider.user?.name ?? 'Unknown Farm',
        'farmAddress': _farmAddressController.text.trim(),
        'organicCertified': false,
        'metadataURI': 'ipfs://$metadataUri',
        'certificateHash':
            certificateIpfsHashes.isNotEmpty ? certificateIpfsHashes.first : '',
        'certificateIpfsUrl': certificateIpfsHashes.isNotEmpty
            ? ipfsService.getIpfsUrl(certificateIpfsHashes.first)
            : '',
        'lotPictures': lotPictureHashes,
        'certificateImages': certificateIpfsHashes,
        'txHash': blockchainResult['txHash'],
        'qrCode': qrData,
        'nfcTag': qrNfcService.generateNfcTag(
            lotId: lotId, farmerId: authProvider.user!.id),
        'tokenId': blockchainResult['tokenId'],
      };

      final success = await lotProvider.createLot(lotData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
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
                      Text(context.tr('success_lot_created')),
                      Text(
                        'Blockchain TX: ${blockchainResult['txHash'].toString().substring(0, 10)}...',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        throw Exception(context.tr('error_lot_creation'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('error_lot_creation'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(e.toString(), style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMLInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.forestGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppTheme.forestGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageChip(String label, double percentage, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: Text(
          context.tr('lot_register_new'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.forestGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.forestGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.forestGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('lot_register_info'),
                              style: TextStyle(
                                color: AppTheme.forestGreen,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Farmer Name (Auto-fetched, Read-only)
                    Text(
                      context.tr('auth_farmer_name'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _farmerNameController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.forestGreen,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Farm Address
                    Text(
                      context.tr('lot_farm_address'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _farmAddressController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: context.tr('lot_farm_address_hint'),
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.forestGreen,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('validation_farm_address');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Variety Selection
                    Text(
                      context.tr('lot_variety'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingVarieties
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.forestGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.forestGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.forestGreen),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Loading varieties...',
                                  style: TextStyle(
                                    color: AppTheme.forestGreen,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _varietyController.text.isEmpty
                                ? null
                                : _varietyController.text,
                            decoration: InputDecoration(
                              hintText: context.tr('lot_variety_hint'),
                              prefixIcon: const Icon(Icons.grass),
                              suffixIcon: _pepperVarieties.isNotEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: _fetchPepperVarieties,
                                      tooltip: 'Retry loading varieties',
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppTheme.forestGreen,
                            ),
                            items: _pepperVarieties.isEmpty
                                ? [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('No varieties available'),
                                    )
                                  ]
                                : _pepperVarieties.map((variety) {
                                    final String displayName =
                                        variety['name'] as String? ?? '';
                                    final String value =
                                        variety['nameEn'] as String? ??
                                            displayName;
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(displayName),
                                    );
                                  }).toList(),
                            onChanged: _pepperVarieties.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _varietyController.text = value ?? '';
                                    });
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr('validation_variety');
                              }
                              return null;
                            },
                          ),

                    const SizedBox(height: 20),

                    // Quantity Input
                    Text(
                      context.tr('lot_quantity'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: context.tr('lot_quantity_hint'),
                        prefixIcon: const Icon(Icons.scale),
                        suffixText: 'kg',
                        iconColor: AppTheme.forestGreen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.forestGreen,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('validation_quantity');
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return context.tr('validation_invalid_quantity');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ML Quality Grading Section
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade50,
                            Colors.green.shade100.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.science,
                                    color: AppTheme.forestGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ML Quality Grading',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.forestGreen,
                                    ),
                                  ),
                                ],
                              ),
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(10),
                                shadowColor:
                                    AppTheme.forestGreen.withOpacity(0.3),
                                child: ElevatedButton.icon(
                                  onPressed: _isLoadingQualityGrading
                                      ? null
                                      : _fetchMLQualityGrading,
                                  icon: _isLoadingQualityGrading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.cloud_download,
                                          size: 18),
                                  label: Text(
                                    _mlQualityGrading == null
                                        ? 'Fetch Grade'
                                        : 'Refresh',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.forestGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_mlQualityGrading != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Grade: ${_mlQualityGrading!.getMappedGrade()}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.forestGreen,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.pepperGold,
                                              AppTheme.pepperGold
                                                  .withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.pepperGold
                                                  .withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.verified,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _mlQualityGrading!.finalGrade
                                                  .split('(')
                                                  .first
                                                  .trim(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMLInfoTile(
                                          'Density',
                                          '${_mlQualityGrading!.density.toStringAsFixed(0)} g/L',
                                          Icons.opacity,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildMLInfoTile(
                                          'Weight',
                                          '${_mlQualityGrading!.weightGrams.toStringAsFixed(0)} g',
                                          Icons.scale,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Visual Analysis:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildPercentageChip(
                                        'Pure',
                                        _mlQualityGrading!
                                            .visualPercentages['pure']!,
                                        Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildPercentageChip(
                                        'Molded',
                                        _mlQualityGrading!
                                            .visualPercentages['molded']!,
                                        Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildPercentageChip(
                                        'Discolored',
                                        _mlQualityGrading!
                                            .visualPercentages['discolored']!,
                                        Colors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scanned: ${_formatDateTime(_mlQualityGrading!.timestamp)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade50,
                                    Colors.orange.shade100.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Click "Fetch Grade" to get quality data from your latest ML scan. ML grading is recommended for accurate quality assessment.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quality Grade
                    Text(
                      context.tr('lot_quality'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    if (_mlQualityGrading != null && _useMLGrade)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Grade locked from ML scan (cannot be changed)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Show locked quality grade when ML grade is active
                    if (_mlQualityGrading != null && _useMLGrade)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.pepperGold.withOpacity(0.15),
                              AppTheme.pepperGold.withOpacity(0.25),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.pepperGold,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.pepperGold.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.pepperGold.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.pepperGold,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.verified,
                                color: AppTheme.pepperGold,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.science,
                                        size: 14,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ML-Detected Quality Grade',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedQuality,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.forestGreen,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _mlQualityGrading!.finalGrade,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    // Show manual selection chips only when no ML grade is active
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 14,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Manual selection mode (ML grade not fetched)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _qualityGrades.map((grade) {
                              final isSelected = _selectedQuality == grade;
                              return ChoiceChip(
                                label: Text(grade),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedQuality = grade;
                                  });
                                },
                                selectedColor: AppTheme.pepperGold,
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Harvest Date
                    Text(
                      context.tr('lot_harvest_date'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _harvestDateController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: context.tr('lot_harvest_date_hint'),
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.forestGreen,
                      ),
                      onTap: _selectHarvestDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('validation_harvest_date');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      context.tr('common_description_optional'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: context.tr('lot_description_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lot Pictures Upload Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('lot_pictures'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickLotPictures,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(context.tr('common_add')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_lotPictures.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('empty_no_pictures'),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('lot_required_quality'),
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _lotPictures.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(_lotPictures[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => _removeLotPicture(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Certification Upload Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('lot_certificates'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickCertificateImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(context.tr('common_add')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_certificateImages.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('empty_no_certificates'),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('lot_required_quality'),
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _certificateImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image:
                                          FileImage(_certificateImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => _removeCertificateImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitLot,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.tr('lot_register_button'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Future<String?> _showImportWalletDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.wallet, color: Colors.orange),
              const SizedBox(width: 8),
              Text(context.tr('wallet_import')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('wallet_import_info'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('wallet_enter_key'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '0x...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.key),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('wallet_lost_key_info'),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(context.tr('common_cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  Navigator.of(context).pop(key);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: Text(context.tr('wallet_import')),
            ),
          ],
        );
      },
    );
  }
}
