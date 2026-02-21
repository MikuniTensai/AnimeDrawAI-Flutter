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

class BackgroundRemoverScreen extends StatefulWidget {
  const BackgroundRemoverScreen({super.key});

  @override
  State<BackgroundRemoverScreen> createState() =>
      _BackgroundRemoverScreenState();
}

class _BackgroundRemoverScreenState extends State<BackgroundRemoverScreen> {
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File file = File(image.path);
        final int fileSize = await file.length();

        // 2MB Limit as per Android implementation
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

      await repository.executeToolAndWait(
        toolType: 'remove_background',
        imageBytes: imageBytes,
        filename: fileName,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildUploadCard(theme),
                        if (_errorMessage != null) _buildErrorCard(theme),
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
                                "Remove Background",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Remove Background",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "AI Tools • Image Editing",
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
        shape: roundedRectangleType(24),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        elevation: 0,
        child: Container(
          width: double.infinity,
          height: 400,
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
                    const SizedBox(height: 8),
                    Text(
                      "Supports JPG, PNG • Max 2MB",
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

// Helper for roundedRectangleType until I check if I need a specific one
RoundedRectangleBorder roundedRectangleType(double radius) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
