import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/models/generation_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../components/gem_indicator.dart';

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

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = "Uploading image...";
    });

    try {
      final repository = context.read<DrawAiRepository>();
      final fileName = _selectedImage!.path.split('/').last;
      final imageBytes = await _selectedImage!.readAsBytes();

      final result = await repository.executeToolAndWait(
        toolType: 'remove_background',
        imageBytes: imageBytes,
        filename: fileName,
        onStatusUpdate: (message, status) {
          setState(() => _statusMessage = message);
        },
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "";
        });

        // Show success and potentially navigate or show result
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
          "Background removed successfully! You can find the result in your gallery.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back or to gallery
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildUploadCard(theme),
                    if (_errorMessage != null) _buildErrorCard(theme),
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

// Helper for roundedRectangleType until I check if I need a specific one
RoundedRectangleBorder roundedRectangleType(double radius) =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
