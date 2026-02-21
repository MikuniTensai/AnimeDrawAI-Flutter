import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/models/generation_model.dart';

class DrawToImageScreen extends StatefulWidget {
  const DrawToImageScreen({super.key});

  @override
  State<DrawToImageScreen> createState() => _DrawToImageScreenState();
}

enum DrawStep { drawing, config }

class _DrawToImageScreenState extends State<DrawToImageScreen> {
  DrawStep _currentStep = DrawStep.drawing;
  Uint8List? _capturedImage;

  // Drawing States
  final List<DrawingPath> _paths = [];
  final List<DrawingPath> _redoPaths = []; // Redo stack
  Color _selectedColor = Colors.black;
  double _brushSize = 8.0;
  bool _isEraser = false; // Eraser mode

  // Config States
  final TextEditingController _promptController = TextEditingController();
  double _cfgScale = 7.0;
  double _denoise = 0.6;
  int _steps = 25;
  int _seed = math.Random().nextInt(1000000000); // Initialize seed immediately
  bool _isGenerating = false;
  String _statusMessage = "";

  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _captureCanvas() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture with higher pixel ratio for better quality
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        setState(() {
          _capturedImage = byteData.buffer.asUint8List();
          _currentStep = DrawStep.config;
        });
      }
    } catch (e) {
      debugPrint("Error capturing canvas: $e");
    }
  }

  Future<void> _generateImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = "Generating...";
    });

    try {
      final repository = context.read<DrawAiRepository>();
      final options = {
        "positive_prompt": _promptController.text,
        "cfg": _cfgScale.toString(),
        "denoise": _denoise.toString(),
        "steps": _steps.toString(),
        "seed": _seed.toString(),
      };

      final result = await repository.executeToolAndWait(
        toolType: 'draw_to_image',
        imageBytes: _capturedImage!,
        filename: "drawing_${DateTime.now().millisecondsSinceEpoch}.png",
        options: options,
        onStatusUpdate: (message, status) {
          setState(() => _statusMessage = message);
        },
      );

      if (mounted) {
        setState(() => _isGenerating = false);
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showSuccessDialog(TaskStatusResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text(
          "Your drawing has been reimagined! Check your gallery.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Undo/Redo Logic
  void _undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _redoPaths.add(_paths.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoPaths.isNotEmpty) {
      setState(() {
        _paths.add(_redoPaths.removeLast());
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _paths.clear();
      _redoPaths.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _currentStep == DrawStep.drawing
        ? _buildDrawingStep()
        : _buildConfigStep();
  }

  Widget _buildDrawingStep() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Sketch Pad"),
        actions: [
          IconButton(
            onPressed: _paths.isNotEmpty ? _undo : null,
            icon: const Icon(Icons.undo),
            tooltip: "Undo",
          ),
          IconButton(
            onPressed: _redoPaths.isNotEmpty ? _redo : null,
            icon: const Icon(Icons.redo),
            tooltip: "Redo",
          ),
          IconButton(
            onPressed: _clearCanvas,
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear",
          ),
          IconButton(
            onPressed: _paths.isEmpty ? null : _captureCanvas,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: "Done",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _redoPaths.clear(); // Clear redo stack on new stroke
                  _paths.add(
                    DrawingPath(
                      points: [details.localPosition],
                      color: _isEraser ? Colors.white : _selectedColor,
                      width: _brushSize,
                      isEraser: _isEraser,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _paths.last.points.add(details.localPosition);
                });
              },
              child: RepaintBoundary(
                key: _canvasKey,
                child: CustomPaint(
                  painter: CanvasPainter(paths: _paths),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          _buildDrawingTools(theme),
        ],
      ),
    );
  }

  Widget _buildDrawingTools(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Capsuled Eraser Toggle
              GestureDetector(
                onTap: () => setState(() => _isEraser = !_isEraser),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isEraser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cleaning_services, // Eraser icon
                        size: 18,
                        color: _isEraser
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      if (_isEraser) ...[
                        const SizedBox(width: 4),
                        Text(
                          "Eraser",
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Brush Size Slider
              const Icon(Icons.brush, size: 16),
              Expanded(
                child: Slider(
                  value: _brushSize,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setState(() => _brushSize = v),
                ),
              ),
              Text(
                _brushSize.toInt().toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Color Palette (Disable if Eraser is active)
          Opacity(
            opacity: _isEraser ? 0.3 : 1.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                          Colors.black,
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.purple,
                          Colors.orange,
                          Colors.brown,
                          Colors.grey,
                        ]
                        .map(
                          (color) => GestureDetector(
                            onTap: _isEraser
                                ? null
                                : () => setState(() => _selectedColor = color),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: !_isEraser && _selectedColor == color
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigStep() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Configure Generation"),
        leading: IconButton(
          onPressed: () => setState(() => _currentStep = DrawStep.drawing),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_capturedImage != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _capturedImage!,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: "What should this become?",
                hintText: "e.g. A vibrant anime landscape...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSliderColumn(
              "Imagination (Denoise)",
              _denoise,
              0.1,
              1.0,
              (v) => setState(() => _denoise = v),
              isFloat: true,
            ),
            _buildSliderColumn(
              "Control (CFG)",
              _cfgScale,
              1,
              20,
              (v) => setState(() => _cfgScale = v),
              isFloat: true,
            ),
            _buildSliderColumn(
              "Quality (Steps)",
              _steps.toDouble(),
              10,
              50,
              (v) => setState(() => _steps = v.toInt()),
            ),
            const SizedBox(height: 16),
            // Seed Control
            Row(
              children: [
                const Text(
                  "Seed",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    controller: TextEditingController(text: _seed.toString())
                      ..selection = TextSelection.collapsed(
                        offset: _seed.toString().length,
                      ),
                    onChanged: (v) =>
                        setState(() => _seed = int.tryParse(v) ?? _seed),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: "Randomize Seed",
                  onPressed: () =>
                      setState(() => _seed = math.Random().nextInt(1000000000)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isGenerating)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _generateImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    "Generate Masterpiece",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderColumn(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool isFloat = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              isFloat ? value.toStringAsFixed(1) : value.toInt().toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class DrawingPath {
  List<Offset> points;
  Color color;
  double width;
  bool isEraser;

  DrawingPath({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });
}

class CanvasPainter extends CustomPainter {
  final List<DrawingPath> paths;
  CanvasPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background with white to ensure eraser works by painting white/clearing
    // or simply because our "paper" is white.
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    for (var path in paths) {
      final paint = Paint()
        ..color = path.isEraser ? Colors.white : path.color
        ..strokeWidth = path.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // Ensure eraser blends correctly if we were using transparency,
      // but since we have a white background, painting white works as an eraser.
      // If we wanted transparent background support, we'd use BlendMode.clear.

      if (path.points.length > 1) {
        // Draw path as a series of lines (more performant than Path object for simple drawing)
        // Optimization: For smoother curves, one could use Path.quadraticBezierTo
        final uiPath = Path();
        uiPath.moveTo(path.points[0].dx, path.points[0].dy);
        for (int i = 1; i < path.points.length; i++) {
          uiPath.lineTo(path.points[i].dx, path.points[i].dy);
        }
        canvas.drawPath(uiPath, paint);
      } else if (path.points.isNotEmpty) {
        // Single point (dot)
        canvas.drawCircle(
          path.points[0],
          path.width / 2,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
