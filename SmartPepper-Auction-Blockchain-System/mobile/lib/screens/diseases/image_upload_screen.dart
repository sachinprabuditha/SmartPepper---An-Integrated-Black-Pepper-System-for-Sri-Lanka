import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:smartpepper_mobile/config/app_config.dart';
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
  Position? _currentPosition;

  // Backend URL from centralized config
  String get apiUrl => AppConfig.predictUrl;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Maximum quality - no reduction
        // No maxWidth or maxHeight to preserve original resolution
      );

      if (image != null) {
        final imageFile = File(image.path);

        // Get GPS location only when image is captured from camera
        if (source == ImageSource.camera) {
          await _getCurrentLocation();
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
              _showErrorDialog('Maximum 4 images allowed');
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
            const SnackBar(
              content: Text(
                'Location services are disabled. Enable to track disease locations.',
              ),
              duration: Duration(seconds: 3),
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
              const SnackBar(
                content: Text(
                  'Location permission denied. Disease location won\'t be saved.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable in settings.',
              ),
              duration: Duration(seconds: 3),
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
              'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
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
      _showErrorDialog('Please select at least one image first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create client with larger timeout for reading response body
      final client = http.Client();

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add all image files
      for (var file in _selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath('images', file.path),
        );
      }

      // Add headers to accept compressed response
      request.headers['Accept-Encoding'] = 'gzip, deflate';

      // Send request with extended timeout for large images
      // Processing 300 leaves can take 3-4 minutes
      var streamedResponse = await client
          .send(request)
          .timeout(
            const Duration(seconds: 300), // 5 minutes
            onTimeout: () {
              throw Exception(
                'Request timeout - Server took too long to respond',
              );
            },
          );

      // Read response with even longer timeout for large data transfer
      print(
        '📥 Reading response (${streamedResponse.contentLength ?? "unknown"} bytes)...',
      );
      var response = await http.Response.fromStream(streamedResponse).timeout(
        const Duration(seconds: 600), // 10 minutes for reading large response
        onTimeout: () {
          throw Exception('Response timeout - Failed to receive complete data');
        },
      );

      client.close(); // Close client after receiving response

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        print('✅ Response received successfully');
        print('📊 Total leaves: ${jsonResponse['total_detected']}');
        print('🌡 Severity: ${jsonResponse['severity']}%');

        setState(() {
          _isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AnalysisResultScreen(
                  analysisResult: jsonResponse,
                  originalImage: _selectedImages.first,
                  currentPosition: _currentPosition,
                ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        // Show the actual server error message
        String errorMsg = 'Server error: ${response.statusCode}\n\n';
        try {
          var errorJson = json.decode(response.body);
          errorMsg +=
              errorJson['message'] ?? errorJson['error'] ?? response.body;
        } catch (_) {
          errorMsg += response.body;
        }
        _showErrorDialog(errorMsg);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      String errorMsg = 'Connection error: $e\n\n';
      errorMsg += '🔧 Troubleshooting Steps:\n';
      errorMsg += '1. Make sure Node.js backend is running (node app.js)\n';
      errorMsg += '2. Current URL: $apiUrl\n';
      errorMsg += '3. Tap Settings ⚙️ to change backend URL\n';
      errorMsg += '4. Check your device is on the same WiFi\n';
      errorMsg += '5. Try different URL options in settings\n';
      _showErrorDialog(errorMsg);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
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
    final imageDisplayHeight = screenHeight * 0.5; // 70% of screen height

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pepper Leaf Health Analyzer'),
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
              const Text(
                'Upload & Analyze Pepper Leaves',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo or select from gallery to detect diseases',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                        child:
                            _selectedImages.isEmpty
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
                                        'No image selected',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap the button below to select up to 4 images',
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
                                            width:
                                                MediaQuery.of(
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
                          'For best results, capture clear images with good lighting',
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
                    label: const Text(
                      'Upload Image',
                      style: TextStyle(
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
                    label: const Text(
                      'View Disease Map',
                      style: TextStyle(
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
                                  const Text(
                                    'Loading image...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Preparing image and fetching location',
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
                                  const Text(
                                    'Analyzing image...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This may take 2-4 minutes for images with many leaves',
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
                        onPressed:
                            (_isLoading || _isPickingImage)
                                ? null
                                : _analyzeImage,
                        icon: const Icon(Icons.analytics, size: 28),
                        label: const Text(
                          'Analyze Image',
                          style: TextStyle(fontSize: 18),
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
                          onPressed:
                              (_isLoading || _isPickingImage)
                                  ? null
                                  : _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            'Add Another Image (${_selectedImages.length}/4)',
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
