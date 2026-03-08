import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ROISelectorScreen extends StatefulWidget {
  final File imageFile;

  const ROISelectorScreen({super.key, required this.imageFile});

  @override
  State<ROISelectorScreen> createState() => _ROISelectorScreenState();
}

class _ROISelectorScreenState extends State<ROISelectorScreen> {
  final List<Offset> _drawnPath = [];
  bool _isDrawing = false;
  bool _isPathClosed = false;
  ui.Image? _image;
  Size? _imageSize;
  double _scale = 1.0;
  Offset _imageOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    });
  }

  void _onPanStart(DragStartDetails details, Size widgetSize) {
    final imagePos = _convertToImageCoordinates(
      details.localPosition,
      widgetSize,
    );
    if (imagePos != null) {
      setState(() {
        if (!_isPathClosed) {
          _drawnPath.clear();
          _drawnPath.add(imagePos);
          _isDrawing = true;
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size widgetSize) {
    if (_isDrawing && !_isPathClosed) {
      final imagePos = _convertToImageCoordinates(
        details.localPosition,
        widgetSize,
      );
      if (imagePos != null) {
        setState(() {
          _drawnPath.add(imagePos);
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing && _drawnPath.length >= 3) {
      setState(() {
        _isDrawing = false;
        _isPathClosed = true;
        // Close the path by connecting back to start
        if (_drawnPath.isNotEmpty) {
          _drawnPath.add(_drawnPath.first);
        }
      });
    }
  }

  Offset? _convertToImageCoordinates(Offset widgetPosition, Size widgetSize) {
    if (_imageSize == null) return null;

    // Calculate scale to fit image in widget
    final widgetAspect = widgetSize.width / widgetSize.height;
    final imageAspect = _imageSize!.width / _imageSize!.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > widgetAspect) {
      // Image is wider - fit to width
      scale = widgetSize.width / _imageSize!.width;
      final scaledHeight = _imageSize!.height * scale;
      offsetY = (widgetSize.height - scaledHeight) / 2;
    } else {
      // Image is taller - fit to height
      scale = widgetSize.height / _imageSize!.height;
      final scaledWidth = _imageSize!.width * scale;
      offsetX = (widgetSize.width - scaledWidth) / 2;
    }

    _scale = scale;
    _imageOffset = Offset(offsetX, offsetY);

    // Check if touch is within image bounds
    if (widgetPosition.dx < offsetX ||
        widgetPosition.dx > offsetX + (_imageSize!.width * scale) ||
        widgetPosition.dy < offsetY ||
        widgetPosition.dy > offsetY + (_imageSize!.height * scale)) {
      return null;
    }

    // Convert widget coordinates to image coordinates
    final x = ((widgetPosition.dx - offsetX) / scale).clamp(
      0.0,
      _imageSize!.width,
    );
    final y = ((widgetPosition.dy - offsetY) / scale).clamp(
      0.0,
      _imageSize!.height,
    );

    return Offset(x, y);
  }

  Future<File?> _cropImage() async {
    if (_drawnPath.length < 3 || _imageSize == null) {
      return null;
    }

    try {
      // Read original image
      final bytes = await widget.imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      // Create a mask image (white background, black foreground for polygon)
      final mask = img.Image(
        width: originalImage.width,
        height: originalImage.height,
      );

      // Fill with white (background)
      img.fill(mask, color: img.ColorRgb8(255, 255, 255));

      // Convert path points to Point objects for polygon
      final polygonPoints =
          _drawnPath.map((p) {
            return img.Point(p.dx.toInt(), p.dy.toInt());
          }).toList();

      // Draw filled polygon on mask (black = selected area)
      img.fillPolygon(
        mask,
        vertices: polygonPoints,
        color: img.ColorRgb8(0, 0, 0),
      );

      // Apply mask to original image (keep only selected region)
      final masked = img.Image(
        width: originalImage.width,
        height: originalImage.height,
      );

      // Fill with white background
      img.fill(masked, color: img.ColorRgb8(255, 255, 255));

      // Copy pixels from original where mask is black
      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          final maskPixel = mask.getPixel(x, y);
          // If mask pixel is black (selected area)
          if (maskPixel.r == 0 && maskPixel.g == 0 && maskPixel.b == 0) {
            final originalPixel = originalImage.getPixel(x, y);
            masked.setPixel(x, y, originalPixel);
          }
        }
      }

      // Find bounding box of the polygon to crop tightly
      double minX = _drawnPath.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      double maxX = _drawnPath.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      double minY = _drawnPath.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      double maxY = _drawnPath.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

      // Add small padding
      final padding = 10;
      final left = (minX - padding).toInt().clamp(0, originalImage.width);
      final top = (minY - padding).toInt().clamp(0, originalImage.height);
      final right = (maxX + padding).toInt().clamp(0, originalImage.width);
      final bottom = (maxY + padding).toInt().clamp(0, originalImage.height);

      final width = (right - left).clamp(1, originalImage.width - left);
      final height = (bottom - top).clamp(1, originalImage.height - top);

      // Crop the masked image to bounding box
      final cropped = img.copyCrop(
        masked,
        x: left,
        y: top,
        width: width,
        height: height,
      );

      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final tempPath =
          '${tempDir.path}/masked_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));

      return croppedFile;
    } catch (e) {
      print('Error creating masked crop: $e');
      return null;
    }
  }

  void _confirmSelection() async {
    if (_drawnPath.length < 3 || !_isPathClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw around the target plant to select it'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading with three bounce animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ThreeBounceLoader(),
    );

    // Give UI thread time to render the dialog before starting heavy operation
    await Future.delayed(const Duration(milliseconds: 100));

    final maskedFile = await _cropImage();

    if (!mounted) return;

    if (maskedFile != null) {
      // Close loading dialog and navigate back in one smooth transition
      Navigator.pop(context); // Close loading
      Navigator.pop(context, maskedFile); // Navigate back with result
    } else {
      // Close loading dialog and show error
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process selection. Please try again.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _skipSelection() {
    Navigator.pop(context, widget.imageFile);
  }

  void _resetSelection() {
    setState(() {
      _drawnPath.clear();
      _isDrawing = false;
      _isPathClosed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Target Plant'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_drawnPath.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetSelection,
              tooltip: 'Clear & Redraw',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _drawnPath.isEmpty
                        ? 'Draw around the plant with your finger'
                        : _isPathClosed
                        ? 'Selection complete! Confirm or redraw'
                        : 'Keep drawing to outline the plant',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _image == null
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E7D32),
                        ),
                      ),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        final widgetSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return GestureDetector(
                          onPanStart:
                              (details) => _onPanStart(details, widgetSize),
                          onPanUpdate:
                              (details) => _onPanUpdate(details, widgetSize),
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            size: widgetSize,
                            painter: ROIPainter(
                              image: _image!,
                              imageSize: _imageSize!,
                              drawnPath: _drawnPath,
                              isPathClosed: _isPathClosed,
                              scale: _scale,
                              imageOffset: _imageOffset,
                            ),
                          ),
                        );
                      },
                    ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text(
                      'Confirm Selection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _skipSelection,
                    icon: const Icon(Icons.skip_next, size: 24),
                    label: const Text(
                      'Skip - Analyze Full Image',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(
                        color: Color(0xFF2E7D32),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ROIPainter extends CustomPainter {
  final ui.Image image;
  final Size imageSize;
  final List<Offset> drawnPath;
  final bool isPathClosed;
  final double scale;
  final Offset imageOffset;

  ROIPainter({
    required this.image,
    required this.imageSize,
    required this.drawnPath,
    required this.isPathClosed,
    required this.scale,
    required this.imageOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate image display bounds
    final widgetAspect = size.width / size.height;
    final imageAspect = imageSize.width / imageSize.height;

    double displayScale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > widgetAspect) {
      displayScale = size.width / imageSize.width;
      final scaledHeight = imageSize.height * displayScale;
      offsetY = (size.height - scaledHeight) / 2;
    } else {
      displayScale = size.height / imageSize.height;
      final scaledWidth = imageSize.width * displayScale;
      offsetX = (size.width - scaledWidth) / 2;
    }

    // Draw the image
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      imageSize.width * displayScale,
      imageSize.height * displayScale,
    );
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    // Draw the freehand path and overlay
    if (drawnPath.isNotEmpty) {
      // Convert image coordinates to widget coordinates for display
      final displayPath =
          drawnPath.map((p) {
            return Offset(
              (p.dx * displayScale) + offsetX,
              (p.dy * displayScale) + offsetY,
            );
          }).toList();

      // Create path for masking
      final path = Path();
      if (displayPath.isNotEmpty) {
        path.moveTo(displayPath.first.dx, displayPath.first.dy);
        for (int i = 1; i < displayPath.length; i++) {
          path.lineTo(displayPath[i].dx, displayPath[i].dy);
        }
        if (isPathClosed) {
          path.close();
        }
      }

      // Draw semi-transparent overlay outside the selection
      if (isPathClosed) {
        canvas.save();

        // Create a path covering the entire canvas
        final fullPath =
            Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

        // Subtract the selection path to create inverse clip
        final overlayPath = Path.combine(
          PathOperation.difference,
          fullPath,
          path,
        );

        canvas.drawPath(
          overlayPath,
          Paint()..color = Colors.white.withOpacity(0.7),
        );
        canvas.restore();
      }

      // Draw the path outline
      final pathPaint =
          Paint()
            ..color = const Color(0xFF2E7D32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, pathPaint);

      // Draw path points as dots for visual feedback
      final dotPaint =
          Paint()
            ..color = const Color(0xFF4CAF50)
            ..style = PaintingStyle.fill;

      for (final point in displayPath) {
        canvas.drawCircle(point, 6, dotPaint);
      }

      // Draw start point with special marker
      if (displayPath.isNotEmpty) {
        final startPaint =
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;
        canvas.drawCircle(displayPath.first, 8, startPaint);
        canvas.drawCircle(
          displayPath.first,
          6,
          Paint()..color = const Color(0xFF2E7D32),
        );
      }

      // Draw label
      if (isPathClosed && displayPath.isNotEmpty) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '✓ Plant Selected',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Find top-most point to position label
        final topPoint = displayPath.reduce((a, b) => a.dy < b.dy ? a : b);
        textPainter.paint(canvas, Offset(topPoint.dx - 50, topPoint.dy - 30));
      }
    } else {
      // Draw hint when no path yet
      final hintPainter = TextPainter(
        text: const TextSpan(
          text: '👆 Draw around the plant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Color(0xFF2E7D32),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      hintPainter.layout();
      hintPainter.paint(
        canvas,
        Offset((size.width - hintPainter.width) / 2, size.height * 0.1),
      );
    }
  }

  @override
  bool shouldRepaint(ROIPainter oldDelegate) {
    return drawnPath.length != oldDelegate.drawnPath.length ||
        isPathClosed != oldDelegate.isPathClosed;
  }
}

// Circular Progress Loader with Blur Widget
class ThreeBounceLoader extends StatelessWidget {
  const ThreeBounceLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2E7D32),
                    ),
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
