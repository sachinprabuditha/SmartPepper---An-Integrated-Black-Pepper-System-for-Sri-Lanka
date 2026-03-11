import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import '../../services/api_service.dart';
import '../../config/theme.dart';
import '../../localization/app_localizations.dart';

class QualityGradingScreen extends StatefulWidget {
  const QualityGradingScreen({super.key});

  @override
  State<QualityGradingScreen> createState() => _QualityGradingScreenState();
}

class _QualityGradingScreenState extends State<QualityGradingScreen> {
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isTaring = false;
  bool _isConnected = false;
  bool _isLightOn = false;
  bool _isTogglingLight = false;
  bool _isMotorOn = false;
  bool _isTogglingMotor = false;
  double _motorSpeed = 50.0; // 1 to 100 scale for speed (maps to delays)
  double _liveWeight = 0.0;
  Timer? _pollingTimer;

  final TextEditingController _ipController = TextEditingController(text: "192.168.1.100");

  // Simulation Metrics
  double? _density;
  double? _weight;
  double? _capturedWeight;
  Map<String, double>? _visuals;
  String? _finalGrade;

  CameraController? _cameraController;
  Timer? _captureTimer;
  bool _isAutoGrading = false;
  int _preCaptureDelay = 5;
  int _countdown = 5;
  
  int _totalPure = 0;
  int _totalMolded = 0;
  int _totalDiscolored = 0;
  int _totalSeedsParsed = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectToScale() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the scale IP address.')),
        );
      }
      return;
    }

    setState(() => _isTaring = true); // Using tare state as generic loading

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      final res = await dio.get('http://$ip/weight');
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isConnected = true;
          });
          _startPolling();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to scale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaring = false);
    }
  }

  void _disconnectFromScale() {
    _pollingTimer?.cancel();
    setState(() {
      _isConnected = false;
      _liveWeight = 0.0;
      _isLightOn = false;
      _isMotorOn = false;
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isConnected || !mounted) {
        timer.cancel();
        return;
      }
      final ip = _ipController.text.trim();
      try {
        final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 2)));
        final res = await dio.get('http://$ip/weight');
        if (res.data != null && res.data is Map) {
          if (mounted) {
            setState(() {
              _liveWeight = double.tryParse(res.data['weight'].toString()) ?? 0.0;
            });
          }
        }
      } catch (e) {
        // Optionally handle polling error (e.g. disconnect)
      }
    });
  }

  void _captureCurrentWeight() {
    setState(() {
      _capturedWeight = _liveWeight;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Weight locked: ${_liveWeight.toStringAsFixed(1)}g', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _calibrateScale() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect to scale first!')));
      return;
    }
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the scale IP address.')),
        );
      }
      return;
    }

    // Ask user for known weight
    final TextEditingController weightController = TextEditingController();
    final double? knownWeight = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Calibrate Scale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Place a known weight on the scale, then enter its weight in grams:'),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Known Weight (g)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(weightController.text);
                Navigator.pop(context, val);
              },
              child: const Text('Calibrate'),
            ),
          ],
        );
      },
    );

    if (knownWeight == null || knownWeight <= 0) return;

    setState(() => _isTaring = true); // Using same loading state for simplicity

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
      await dio.get('http://$ip/calibrate', queryParameters: {'weight': knownWeight});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scale calibrated to ${knownWeight}g successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to calibrate scale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaring = false);
    }
  }

  Future<void> _toggleMotor() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect to scale first!')));
      return;
    }
    
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _isTogglingMotor = true);

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));
      int stepDelay = 3000 - ((_motorSpeed - 1) * (2500 / 99)).toInt();
      final endpoint = _isMotorOn ? '/motor/off' : '/motor/on';
      
      final res = await dio.get('http://$ip$endpoint', queryParameters: {'speed': stepDelay});
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isMotorOn = !_isMotorOn;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle motor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingMotor = false);
    }
  }

  Future<void> _updateMotorSpeed() async {
    if (!_isConnected || !_isMotorOn) return;
    
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      int stepDelay = 3000 - ((_motorSpeed - 1) * (2500 / 99)).toInt();
      // Send speed update if motor is currently on
      await dio.get('http://$ip/motor/speed', queryParameters: {'speed': stepDelay});
    } catch (e) {
      // Ignore background speed update errors
    }
  }

  Future<void> _toggleLight() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect to scale first!')));
      return;
    }
    
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() => _isTogglingLight = true);

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      final endpoint = _isLightOn ? '/light/off' : '/light/on';
      final res = await dio.get('http://$ip$endpoint');
      
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isLightOn = !_isLightOn;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle light: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingLight = false);
    }
  }

  Future<void> _tareScale() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect to scale first!')));
      return;
    }
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the scale IP address.')),
        );
      }
      return;
    }

    setState(() => _isTaring = true);

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      await dio.get('http://$ip/tare');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scale tared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to scale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaring = false);
    }
  }

  void _startAutomatedGrading() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to the scale first.')),
      );
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready. Please grant permissions.')),
      );
      return;
    }

    setState(() {
      _isAutoGrading = true;
      _isAnalyzing = true;
      _totalPure = 0;
      _totalMolded = 0;
      _totalDiscolored = 0;
      _totalSeedsParsed = 0;
      _countdown = _preCaptureDelay;
      _density = null;
      _visuals = null;
      _finalGrade = null;
    });

    // 1. Turn on Light
    if (!_isLightOn) await _toggleLight();
    // 2. Turn on Motor
    if (!_isMotorOn) await _toggleMotor();

    // Ensure phone flash is OFF
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint("Could not set flash mode: $e");
    }

    // 3. Pre-Capture Countdown
    for (int i = _preCaptureDelay; i > 0; i--) {
      if (!mounted || !_isAutoGrading) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    // 4. Start Capture Timer — skip tick if previous capture still running
    _captureTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
       if (!mounted || !_isAutoGrading) {
         timer.cancel();
         return;
       }
       // Guard: skip this tick if previous processing is still running
       if (_isProcessingFrame) return;
       await _processCameraFrame();
    });
  }

  bool _isProcessingFrame = false;

  Future<void> _processCameraFrame() async {
    if (_isProcessingFrame) return;  // extra safety guard
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _isProcessingFrame = true;
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final apiService = context.read<ApiService>();
      final result = await apiService.analyzeGradingImage(imageFile.path);
      
      if (mounted && result['success'] == true) {
        final data = result['data'];
        final total = (data['totalSeeds'] ?? 0) as int;
        // Ignore suspiciously huge counts (sanity check: > 900 = probably empty belt noise)
        if (total > 0 && total <= 900) {
          final breakdown = data['breakdown'] as Map<String, dynamic>? ?? {};
          setState(() {
            _totalSeedsParsed += total;
            _totalPure += (breakdown['pure'] as num? ?? 0).toInt();
            _totalMolded += (breakdown['molded'] as num? ?? 0).toInt();
            _totalDiscolored += (breakdown['discolored'] as num? ?? 0).toInt();
            
            _visuals = {
              'pure': double.parse((_totalPure / _totalSeedsParsed * 100).toStringAsFixed(1)),
              'molded': double.parse((_totalMolded / _totalSeedsParsed * 100).toStringAsFixed(1)),
              'discolored': double.parse((_totalDiscolored / _totalSeedsParsed * 100).toStringAsFixed(1)),
            };
          });
        } else if (total > 900) {
          debugPrint('[Grading] Ignoring suspiciously large count: $total (likely empty belt noise)');
        }
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _stopAutomatedGrading() async {
    _captureTimer?.cancel();
    if (_isMotorOn) await _toggleMotor();
    if (_isLightOn) await _toggleLight();

    // Turn off phone flash
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint("Could not turn off flash: $e");
    }

    setState(() {
      _isAutoGrading = false;
      _isAnalyzing = false;
      
      final finalWeight = _capturedWeight ?? _liveWeight;

      if (_totalSeedsParsed == 0) {
        _density = finalWeight;
        _weight = finalWeight;
        _finalGrade = 'Grade D (Low Density / Waste) - No Seeds Evaluated';
      } else {
        _weight = finalWeight;
        _density = finalWeight;
        double pureProb = (_totalPure / _totalSeedsParsed) * 100;
        
        String grade = 'Grade D (Low Density / Waste)';
        if (_density! >= 570 && pureProb >= 90) {
          grade = 'Grade A (Premium High Density)';
        } else if (_density! >= 550 && pureProb >= 80) {
          grade = 'Grade B (Standard High Quality)';
        } else if (_density! >= 500 && pureProb >= 70) {
          grade = 'Grade C (Lightweight / Industrial)';
        }
        _finalGrade = grade;
      }
    });
  }

  Future<void> _saveResult() async {
    if (_density == null || _visuals == null || _finalGrade == null) return;

    setState(() => _isSaving = true);

    try {
      final apiService = context.read<ApiService>();
      await apiService.saveQualityGrading({
        'weightGrams': _weight,
        'density': _density,
        'visualPercentages': _visuals,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('common_success')),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/farmer/quality-grading/history');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('common_error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getBadgeColor(String? grade) {
    if (grade == null) return Colors.grey;
    if (grade.contains('Grade A')) return Colors.green;
    if (grade.contains('Grade B')) return Colors.blue;
    if (grade.contains('Grade C')) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          context.tr('grading_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.pepperGold),
            onPressed: () => context.push('/farmer/quality-grading/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Machine Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.forestGreen, Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.memory, size: 60, color: AppTheme.pepperGold),
                  const SizedBox(height: 16),
                  Text(
                    _isAnalyzing
                        ? context.tr('common_loading')
                        : context.tr('grading_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected ? 'Scale Connected' : 'Scale Disconnected',
                        style: TextStyle(
                          color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_isConnected) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Live: ${_liveWeight.toStringAsFixed(1)} g',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_capturedWeight != null)
                      Text(
                        'Locked: ${_capturedWeight!.toStringAsFixed(1)} g',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: (_liveWeight > 0 && !_isAnalyzing) ? _captureCurrentWeight : null,
                      icon: const Icon(Icons.lock),
                      label: Text(_capturedWeight == null ? 'Lock Weight for Grading' : 'Update Locked Weight'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.forestGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hardware Controls Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Device Connection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.forestGreen)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          enabled: !_isConnected,
                          decoration: const InputDecoration(
                            labelText: 'IP Address',
                            hintText: '192.168.1.100',
                            prefixIcon: Icon(Icons.wifi, size: 20),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isTaring || _isAnalyzing ? null : (_isConnected ? _disconnectFromScale : _connectToScale),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected ? Colors.red : AppTheme.forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isTaring && !_isConnected
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isConnected ? 'Disconnect' : 'Connect'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  const Text('Scale & Environment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (!_isConnected || _isTaring || _isAnalyzing) ? null : _tareScale,
                          icon: _isTaring ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.exposure_zero),
                          label: Text(_isTaring ? 'Working...' : 'Tare'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            side: BorderSide(color: Colors.orange[800]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (!_isConnected || _isTaring || _isAnalyzing) ? null : _calibrateScale,
                          icon: const Icon(Icons.settings),
                          label: const Text('Calibrate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[800],
                            side: BorderSide(color: Colors.blue[800]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: (!_isConnected || _isTogglingLight || _isAnalyzing) ? null : _toggleLight,
                    icon: _isTogglingLight 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Icon(_isLightOn ? Icons.lightbulb : Icons.lightbulb_outline, color: _isLightOn ? Colors.amber[700] : null),
                    label: Text(_isLightOn ? 'Turn Light OFF' : 'Turn Light ON'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isLightOn ? Colors.amber[800] : Colors.grey[700],
                      side: BorderSide(color: (_isLightOn ? Colors.amber[800] : Colors.grey[400])!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  
                  const Divider(height: 32),
                  const Text('Conveyor Motor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.grey, size: 20),
                      Expanded(
                        child: Slider(
                          value: _motorSpeed,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${_motorSpeed.round()}%',
                          onChanged: !_isConnected ? null : (value) {
                            setState(() => _motorSpeed = value);
                          },
                          onChangeEnd: !_isConnected ? null : (value) => _updateMotorSpeed(),
                        ),
                      ),
                      Text('${_motorSpeed.round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (!_isConnected || _isTogglingMotor || _isAnalyzing) ? null : _toggleMotor,
                      icon: _isTogglingMotor 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : Icon(_isMotorOn ? Icons.stop : Icons.play_arrow),
                      label: Text(_isMotorOn ? 'Turn Motor OFF' : 'Turn Motor ON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMotorOn ? Colors.red : AppTheme.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metrics Display Area
            if (_density != null && _visuals != null) ...[
              // Grade Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _getBadgeColor(_finalGrade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBadgeColor(_finalGrade)),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('grading_final_grade'),
                      style: TextStyle(
                        color: _getBadgeColor(_finalGrade),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _finalGrade!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getBadgeColor(_finalGrade),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Detailed Metrics
              Row(
                children: [
                   Expanded(
                    child: _buildMetricCard(
                      context.tr('lot_weight'),
                      '${_weight!.toStringAsFixed(1)}g',
                      Icons.scale,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context.tr('grading_sample_density'),
                      '${_density!.toStringAsFixed(1)} g/L',
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visual Analysis Proportions
              Text(
                context.tr('grading_visual_analysis'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVisualStatCircle(
                        context.tr('grading_pure'), '${_visuals!['pure']}%', AppTheme.pepperGold),
                    _buildVisualStatCircle(
                        context.tr('grading_molded'), '${_visuals!['molded']}%', Colors.red[400]!),
                    _buildVisualStatCircle(context.tr('grading_discolored'),
                        '${_visuals!['discolored']}%', Colors.orange[400]!),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            if (_cameraController != null && _cameraController!.value.isInitialized)
              Container(
                height: 300,
                width: double.infinity,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1 / _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                    if (_isAutoGrading)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.white, size: 12),
                              const SizedBox(width: 8),
                              Text(
                                _countdown > 0 ? "STARTING IN $_countdown..." : "LIVE SCAN", 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                              ),
                            ],
                          )
                        )
                      ),
                  ]
                )
              ),

             if (_isAutoGrading || _visuals != null) ...[
               const SizedBox(height: 16),
               if (_visuals != null)
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       _buildLiveStatBadge('Pure', '${_visuals!['pure']}%', AppTheme.pepperGold),
                       const SizedBox(width: 8),
                       _buildLiveStatBadge('Molded', '${_visuals!['molded']}%', Colors.red[400]!),
                       const SizedBox(width: 8),
                       _buildLiveStatBadge('Discolored', '${_visuals!['discolored']}%', Colors.orange[400]!),
                     ],
                   ),
                 )
               else
                 const Text(
                   'Waiting for seeds...',
                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                   textAlign: TextAlign.center,
                 ),
               const SizedBox(height: 16),
             ],

            // Actions
            ElevatedButton(
              onPressed: _isConnected && !_isSaving ? (_isAutoGrading ? _stopAutomatedGrading : _startAutomatedGrading) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isAutoGrading ? Colors.red : AppTheme.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isAutoGrading ? 'Stop Automated Grading' : 'Start Automated Grading',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            if (_density != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isSaving ? null : _saveResult,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.forestGreen, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.forestGreen,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        context.tr('grading_save'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.forestGreen),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualStatCircle(String label, String value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: double.parse(value.replaceAll('%', '')) / 100,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                strokeWidth: 6,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 6),
          Text('$label: $value', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
