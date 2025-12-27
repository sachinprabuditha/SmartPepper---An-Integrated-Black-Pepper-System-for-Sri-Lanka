import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/lot_provider.dart';
import '../../services/blockchain_service.dart';
import '../../services/ipfs_service.dart';
import '../../services/qr_nfc_service.dart';
import '../../services/storage_service.dart';
import '../../config/theme.dart';

class CreateLotScreen extends StatefulWidget {
  const CreateLotScreen({super.key});

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

  final List<String> _qualityGrades = ['AAA', 'AA', 'A', 'B'];
  final List<String> _pepperVarieties = [
    'Black Pepper Premium',
    'Black Pepper Standard',
    'Black Pepper Organic',
    'White Pepper',
    'Green Pepper',
  ];

  @override
  void initState() {
    super.initState();
    _loadFarmerInfo();
  }

  Future<void> _loadFarmerInfo() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      setState(() {
        _farmerNameController.text = authProvider.user!.name;
      });
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
              title: const Text('Take Photo'),
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
              title: const Text('Choose from Gallery'),
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
              title: const Text('Take Photo'),
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
              title: const Text('Choose from Gallery'),
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

  Future<void> _submitLot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedHarvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select harvest date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate lot pictures (mandatory)
    if (_lotPictures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please add at least one lot picture for quality matching'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate certificates (mandatory)
    if (_certificateImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please add at least one certificate for quality matching'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
      final blockchainService = context.read<BlockchainService>();
      final ipfsService = context.read<IpfsService>();
      final qrNfcService = QrNfcService();
      final storageService = context.read<StorageService>();

      // Check if user has wallet
      final farmerAddress = authProvider.user?.walletAddress;
      if (farmerAddress == null || farmerAddress.isEmpty) {
        throw Exception('Wallet address not found. Please contact support.');
      }

      // Get private key or prompt user to import
      String? privateKey = await storageService.getPrivateKey();
      if (privateKey == null) {
        // Show dialog to import private key
        if (mounted) {
          privateKey = await _showImportWalletDialog();
          if (privateKey == null || privateKey.isEmpty) {
            throw Exception(
                'Private key is required to create lots on blockchain');
          }
          // Save for future use
          await storageService.savePrivateKey(privateKey);
        } else {
          throw Exception('Private key not found');
        }
      }

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

      // Step 3: Write to blockchain
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
                Text('Step 3/4: Writing to blockchain...'),
              ],
            ),
            duration: Duration(days: 1),
          ),
        );
      }

      final blockchainResult = await blockchainService.mintLotPassport(
        privateKey: privateKey,
        farmerAddress: farmerAddress,
        lotId: lotId,
        variety: _varietyController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()).toInt(),
        harvestDate: _selectedHarvestDate!.toIso8601String(),
        origin: 'Sri Lanka',
        certificateHash: certificateIpfsHashes.isNotEmpty
            ? certificateIpfsHashes.first
            : '0x0000000000000000000000000000000000000000000000000000000000000000',
        metadataURI: 'ipfs://$metadataUri',
      );

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
                      const Text('Lot created successfully!'),
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
        throw Exception('Failed to create lot');
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
                const Text('Error creating lot',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: const Text(
          'Register New Lot',
          style: TextStyle(
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
                              'Register your pepper lot with complete details for blockchain traceability',
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
                    const Text(
                      'Farmer Name',
                      style: TextStyle(
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
                    const Text(
                      'Farm/Harvest Location Address *',
                      style: TextStyle(
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
                        hintText: 'Enter farm or harvest location address',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.forestGreen,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter farm address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Variety Selection
                    const Text(
                      'Pepper Variety *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _varietyController.text.isEmpty
                          ? null
                          : _varietyController.text,
                      decoration: InputDecoration(
                        hintText: 'Select variety',
                        prefixIcon: const Icon(Icons.grass),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.forestGreen,
                      ),
                      items: _pepperVarieties.map((variety) {
                        return DropdownMenuItem(
                          value: variety,
                          child: Text(variety),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _varietyController.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a variety';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Quantity Input
                    const Text(
                      'Quantity (kg) *',
                      style: TextStyle(
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
                        hintText: 'Enter quantity in kg',
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
                          return 'Please enter quantity';
                        }
                        final quantity = double.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Please enter a valid quantity';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Quality Grade
                    const Text(
                      'Quality Grade *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
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
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Harvest Date
                    const Text(
                      'Harvest Date *',
                      style: TextStyle(
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
                        hintText: 'Select harvest date',
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
                          return 'Please select harvest date';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
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
                        hintText: 'Add additional notes about this lot',
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
                        const Text(
                          'Lot Pictures *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickLotPictures,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add'),
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
                                'No lot pictures added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Required for quality matching',
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
                        const Text(
                          'Certificates *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickCertificateImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add'),
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
                                'No certificates added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Required for quality matching',
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
                            : const Text(
                                'Register Lot',
                                style: TextStyle(
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
          title: const Row(
            children: [
              Icon(Icons.wallet, color: Colors.orange),
              SizedBox(width: 8),
              Text('Import Wallet'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your wallet private key is required to create lots on the blockchain.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your private key:',
                style: TextStyle(
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
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This was provided when you registered. If you lost it, contact support.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
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
              child: const Text('Cancel'),
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
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}
