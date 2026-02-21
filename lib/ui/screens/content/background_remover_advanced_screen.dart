import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/generation_repository.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../../services/ad_helper.dart';
import '../../components/gem_indicator.dart';
import '../../components/generation_loading_overlay.dart';

class BackgroundRemoverAdvancedScreen extends StatefulWidget {
  const BackgroundRemoverAdvancedScreen({super.key});

  @override
  State<BackgroundRemoverAdvancedScreen> createState() =>
      _BackgroundRemoverAdvancedScreenState();
}

class _BackgroundRemoverAdvancedScreenState
    extends State<BackgroundRemoverAdvancedScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String _statusMessage = "";
  String? _errorMessage;
  double? _progress;
  bool _isQueued = false;
  int? _queuePosition;
  int? _queueTotal;
  String? _queueInfo;
  final ImagePicker _picker = ImagePicker();

  // Advanced Options
  String _selectedModel = "u2net";
  bool _postProcessing = false;
  bool _onlyMask = false;
  bool _alphaMatting = false;
  double _amForeground = 240.0;
  double _amBackground = 10.0;
  double _amErode = 10.0;
  String _bgColor = "none";
  bool _isConfigExpanded = true;

  final List<Map<String, String>> _modelOptions = [
    {"id": "u2net", "name": "Standard (Best)"},
    {"id": "u2netp", "name": "Fast (Lower Qual)"},
    {"id": "u2netp_human_seg", "name": "Human Focus"},
    {"id": "silueta", "name": "Silhouette / Object"},
    {"id": "isnet-general-use", "name": "General (ISNet)"},
    {"id": "isnet-anime", "name": "Anime Style"},
  ];

  final List<Map<String, dynamic>> _bgColors = [
    {"id": "none", "name": "Transparent", "color": Colors.transparent},
    {"id": "white", "name": "White", "color": Colors.white},
    {"id": "black", "name": "Black", "color": Colors.black},
    {"id": "magenta", "name": "Magenta", "color": const Color(0xFFFF00FF)},
    {"id": "chroma green", "name": "Chroma Green", "color": Color(0xFF00FF00)},
    {"id": "chroma blue", "name": "Chroma Blue", "color": Color(0xFF0000FF)},
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

    // Preload Ad
    AdHelper.preloadInterstitialAd();

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = "Uploading image...";
      _progress = null;
      _isQueued = false;
    });

    try {
      final repository = context.read<DrawAiRepository>();
      final fileName = _selectedImage!.path.split('/').last;
      final imageBytes = await _selectedImage!.readAsBytes();

      final options = {
        "model": _selectedModel,
        "post_process": _postProcessing.toString(),
        "only_mask": _onlyMask.toString(),
        "alpha_matting": _alphaMatting.toString(),
        "alpha_matting_foreground_threshold": _amForeground.toInt().toString(),
        "alpha_matting_background_threshold": _amBackground.toInt().toString(),
        "alpha_matting_erode_size": _amErode.toInt().toString(),
        "bgcolor": _bgColor,
      };

      await repository.executeToolAndWait(
        toolType: 'remove_background',
        imageBytes: imageBytes,
        filename: fileName,
        options: options,
        onStatusUpdate: (message, status) {
          if (mounted) {
            setState(() {
              _statusMessage = message;
              if (status != null) {
                _progress = (status.progress ?? 0) / 100.0;
                _isQueued = status.status == "queued";
                _queuePosition = status.queuePosition;
                _queueTotal = status.queueTotal;
                _queueInfo = status.queueInfo;
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _statusMessage = "Success!";
          _progress = 1.0;
        });

        // Delay to show success state briefly
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          _handlePostProcessNavigation();
        }
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

  void _handlePostProcessNavigation() async {
    void navigateToGallery() {
      if (mounted) {
        Provider.of<NavigationProvider>(context, listen: false).setIndex(2);
        Navigator.pop(context);
      }
    }

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final genRepo = Provider.of<GenerationRepository>(context, listen: false);
      final userId = authRepo.currentUser?.uid;

      if (userId != null) {
        final limit = await genRepo.getGenerationLimit(userId);
        final isPremium =
            limit.isPremium == true ||
            limit.subscriptionType == 'basic' ||
            limit.subscriptionType == 'pro';

        if (!isPremium) {
          AdHelper.showAdAfterSave(onCompleted: navigateToGallery);
        } else {
          navigateToGallery();
        }
      } else {
        navigateToGallery();
      }
    } catch (e) {
      navigateToGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
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
                        _buildAdvancedOptions(theme),
                        const SizedBox(height: 24),
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
                                "Remove Background (Advanced)",
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
          if (_isProcessing)
            GenerationLoadingOverlay(
              isGenerating: _isProcessing,
              statusMessage: _statusMessage,
              progress: _progress,
              isQueued: _isQueued,
              queuePosition: _queuePosition,
              queueTotal: _queueTotal,
              queueInfo: _queueInfo,
            ),
        ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Advanced Remover",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Professional Tools",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
          height: 350,
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
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tap to Upload Photo",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions(ThemeData theme) {
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
            leading: Icon(Icons.settings, color: theme.colorScheme.primary),
            title: const Text(
              "Advanced Settings",
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Model",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedModel,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: _modelOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt["id"],
                        child: Text(opt["name"]!),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedModel = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    "Post Processing",
                    _postProcessing,
                    (v) => setState(() => _postProcessing = v),
                  ),
                  _buildSwitchRow(
                    "Only Mask",
                    _onlyMask,
                    (v) => setState(() => _onlyMask = v),
                  ),
                  _buildSwitchRow(
                    "Alpha Matting",
                    _alphaMatting,
                    (v) => setState(() => _alphaMatting = v),
                  ),
                  if (_alphaMatting) ...[
                    _buildSliderRow(
                      "AM Foreground",
                      _amForeground,
                      0,
                      255,
                      (v) => setState(() => _amForeground = v),
                    ),
                    _buildSliderRow(
                      "AM Background",
                      _amBackground,
                      0,
                      255,
                      (v) => setState(() => _amBackground = v),
                    ),
                    _buildSliderRow(
                      "AM Erode Size",
                      _amErode,
                      0,
                      255,
                      (v) => setState(() => _amErode = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    "Background Color",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _bgColors.length,
                      itemBuilder: (context, index) {
                        final item = _bgColors[index];
                        final isSelected = _bgColor == item["id"];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _bgColor = item["id"] as String),
                          child: Container(
                            width: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: item["color"] as Color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: isSelected ? 3 : 1,
                              ),
                              image: item["id"] == "none"
                                  ? const DecorationImage(
                                      image: AssetImage(
                                        'assets/images/transparent_pattern.png',
                                      ),
                                      repeat: ImageRepeat.repeat,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color:
                                        (item["color"] as Color)
                                                .computeLuminance() >
                                            0.5
                                        ? Colors.black
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              value.toInt().toString(),
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
}
