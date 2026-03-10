import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartpepper_mobile/config/theme.dart';
import '../../localization/app_localizations.dart';
import '../../services/disease_api_service.dart';
import 'analysis_result_screen.dart';
import 'disease_map_screen.dart';
import 'roi_selector_screen.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isPickingImage = false;
  final ImagePicker _picker = ImagePicker();
  final DiseaseApiService _apiService = DiseaseApiService();
  Position? _currentPosition;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      // Capture GPS location ONLY for camera (not gallery)
      // Gallery images are from the past, so current location is not relevant
      if (source == ImageSource.camera) {
        await _getCurrentLocation();
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Maximum quality - no reduction
        // No maxWidth or maxHeight to preserve original resolution
      );

      if (image != null) {
        final imageFile = File(image.path);

        // Verify GPS location was captured (only required for camera images)
        if (source == ImageSource.camera && _currentPosition == null) {
          if (mounted) {
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Icon(Icons.warning_amber,
                    color: Colors.orange, size: 48),
                content: Text(
                  context.tr('disease_location_required'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.tr('common_cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.tr('disease_retry_location')),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) {
              setState(() {
                _isPickingImage = false;
              });
              return;
            }

            // Retry getting location
            await _getCurrentLocation();
            if (_currentPosition == null) {
              _showErrorDialog(context.tr('disease_location_required_error'));
              setState(() {
                _isPickingImage = false;
              });
              return;
            }
          }
        }

        // Navigate to ROI selector screen (keep loading state active)
        if (!mounted) return;
        final File? selectedROI = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (context) => ROISelectorScreen(imageFile: imageFile),
          ),
        );

        // Update selected images with cropped version or original
        if (selectedROI != null) {
          setState(() {
            _isPickingImage = false;
            if (_selectedImages.length < 4) {
              _selectedImages.add(selectedROI);
            } else {
              _showErrorDialog(context.tr('disease_max_images'));
            }
          });
        } else {
          setState(() {
            _isPickingImage = false;
          });
        }
      } else {
        setState(() {
          _isPickingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPickingImage = false;
      });
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('disease_location_disabled'),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('disease_location_denied'),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('disease_location_denied_forever'),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr('disease_location_captured')}: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImages.isEmpty) {
      _showErrorDialog(context.tr('disease_select_image_first'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use centralized API service
      final jsonResponse = await _apiService.predictDisease(_selectedImages);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            analysisResult: jsonResponse,
            originalImage: _selectedImages.first,
            currentPosition: _currentPosition,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMsg = 'Connection error: $e\n\n';
      errorMsg += '🔧 Troubleshooting Steps:\n';
      errorMsg += '1. Make sure Node.js backend is running (node app.js)\n';
      errorMsg += '2. Current URL: ${DiseaseApiService.predictUrl}\n';
      errorMsg += '3. Check your device is on the same WiFi\n';
      errorMsg +=
          '4. Verify backend server IP address (${DiseaseApiService.diseaseApiBaseUrl})\n';
      _showErrorDialog(errorMsg);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('common_error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common_ok')),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('disease_select_image_source')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.tr('disease_camera')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.tr('disease_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageDisplayHeight = screenHeight * 0.35; // 35% of screen height

    return Scaffold(
      backgroundColor: AppTheme.forestGreen,
      appBar: AppBar(
        title: Text(context.tr('disease_leaf_analyzer_title')),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: AppTheme.pepperGold,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashboard Header
              Text(
                context.tr('disease_upload_analyze'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('disease_upload_subtitle'),
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Image Display Area - 70% of screen
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      height: imageDisplayHeight,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: _selectedImages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 100,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.tr('disease_no_image_selected'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('disease_tap_button_info'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 8.0,
                                    ),
                                    child: Stack(
                                      children: [
                                        Image.file(
                                          _selectedImages[index],
                                          height: imageDisplayHeight,
                                          width: MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.8,
                                          fit: BoxFit.contain,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedImages.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    // Info Card inside the image card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          context.tr('disease_best_results_tip'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (_selectedImages.isEmpty) ...[
                // Upload Button (when no image)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.upload_file, size: 28),
                    label: Text(
                      context.tr('disease_upload_image'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // View Map Button (when no image)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiseaseMapScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, size: 28),
                    label: Text(
                      context.tr('disease_view_disease_map'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else
                // Analyze & Change buttons (when image selected)
                Column(
                  children: [
                    // Loading message for image picking
                    if (_isPickingImage)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E7D32)),
                        ),
                        child: Row(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('disease_loading_image'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('disease_preparing_image'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Loading message for analysis
                    if (_isLoading)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E7D32)),
                        ),
                        child: Row(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('disease_analyzing'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('disease_analysis_time_info'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Analyze Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _isPickingImage)
                            ? null
                            : _analyzeImage,
                        icon: const Icon(Icons.analytics, size: 28),
                        label: Text(
                          context.tr('disease_analyze_images'),
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Change Image Button
                    if (_selectedImages.length < 4)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isLoading || _isPickingImage)
                              ? null
                              : _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            '${context.tr('disease_add_another_image')} (${_selectedImages.length}/4)',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Color(0xFF2E7D32),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
