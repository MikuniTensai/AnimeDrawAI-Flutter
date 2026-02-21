import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/generation_model.dart';
import '../../components/gem_indicator.dart';

class UpscaleScreen extends StatefulWidget {
  const UpscaleScreen({super.key});

  @override
  State<UpscaleScreen> createState() => _UpscaleScreenState();
}

class _UpscaleScreenState extends State<UpscaleScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String _statusMessage = "";
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  // Upscale Options
  double _upscaleFactor = 1.5;
  int _tileSize = 512;
  int _overlap = 32;
  int _feather = 0;
  String _selectedResample = "lanczos";
  bool _isConfigExpanded = true;

  final List<String> _resampleOptions = [
    "lanczos",
    "nearest-exact",
    "bilinear",
    "area",
    "bicubic",
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File file = File(image.path);
        final int fileSize = await file.length();

        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            _errorMessage =
                "File too large. Maximum 2MB (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)";
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = file;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Error picking image: $e");
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = "Processing...";
    });

    try {
      final repository = context.read<DrawAiRepository>();
      final fileName = _selectedImage!.path.split('/').last;
      final imageBytes = await _selectedImage!.readAsBytes();

      final options = {
        "upscale_by": _upscaleFactor.toString(),
        "tile_size": _tileSize.toString(),
        "overlap": _overlap.toString(),
        "feather": _feather.toString(),
        "resample_method": _selectedResample,
      };

      final result = await repository.executeToolAndWait(
        toolType: 'upscale',
        imageBytes: imageBytes,
        filename: fileName,
        options: options,
        onStatusUpdate: (message, status) {
          setState(() => _statusMessage = message);
        },
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "";
        });
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showSuccessDialog(TaskStatusResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success"),
        content: const Text(
          "Image upscaled successfully! You can find the high-resolution result in your gallery.",
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildUploadCard(theme),
                    if (_errorMessage != null) _buildErrorCard(theme),
                    const SizedBox(height: 16),
                    _buildConfigCard(theme),
                    const SizedBox(height: 24),
                    if (_isProcessing) _buildProcessingCard(theme),
                    if (!_isProcessing && _selectedImage != null)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _processImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            "Start Upscaling",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Super Resolution",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Upscale & Enhance",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: context.read<DrawAiRepository>().getGemCountStream(
              context.read<AuthRepository>().currentUser?.uid ?? "",
            ),
            builder: (context, snapshot) {
              return GemIndicator(gemCount: snapshot.data ?? 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(ThemeData theme) {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickImage,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        elevation: 0,
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: _selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.contain),
                    if (!_isProcessing)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: 0.8,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.add_photo_alternate,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Upload Image",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Max 2MB",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildConfigCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isConfigExpanded = !_isConfigExpanded),
            leading: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            title: const Text(
              "Upscale Settings",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              _isConfigExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
          ),
          if (_isConfigExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildSliderRow(
                    "Upscale By",
                    _upscaleFactor,
                    1.0,
                    4.0,
                    (v) => setState(() => _upscaleFactor = v),
                    isFloat: true,
                  ),
                  _buildSliderRow(
                    "Tile Size",
                    _tileSize.toDouble(),
                    256,
                    1024,
                    (v) => setState(() => _tileSize = v.toInt()),
                  ),
                  _buildSliderRow(
                    "Overlap",
                    _overlap.toDouble(),
                    0,
                    128,
                    (v) => setState(() => _overlap = v.toInt()),
                  ),
                  _buildSliderRow(
                    "Feather",
                    _feather.toDouble(),
                    0,
                    64,
                    (v) => setState(() => _feather = v.toInt()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Resample Method",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedResample,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          items: _resampleOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedResample = val!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
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
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              isFloat ? value.toStringAsFixed(1) : value.toInt().toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(
              _statusMessage.isEmpty ? "Processing..." : _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
