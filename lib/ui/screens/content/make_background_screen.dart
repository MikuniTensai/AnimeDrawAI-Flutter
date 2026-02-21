import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../services/ad_helper.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/generation_repository.dart';
import '../../../data/utils/content_moderator.dart';
import '../../utils/content_moderator_helper.dart';
import '../../components/gem_indicator.dart';
import '../../components/generation_loading_overlay.dart';

class MakeBackgroundScreen extends StatefulWidget {
  const MakeBackgroundScreen({super.key});

  @override
  State<MakeBackgroundScreen> createState() => _MakeBackgroundScreenState();
}

class _MakeBackgroundScreenState extends State<MakeBackgroundScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _selectedSize = "1280x720";
  int _seed = math.Random().nextInt(1000000000);
  bool _isGenerating = false;
  String _statusMessage = "";
  String? _errorMessage;

  // Progress Tracking
  double? _progress;
  bool _isQueued = false;
  int? _queuePosition;
  int? _queueTotal;
  String? _queueInfo;

  final List<Map<String, String>> _sizeOptions = [
    {"id": "1024x1024", "label": "Square (1:1)"},
    {"id": "1280x720", "label": "Landscape (16:9)"},
  ];

  Future<void> _generateBackground() async {
    if (_promptController.text.isEmpty) {
      setState(() => _errorMessage = "Please enter a vision request");
      return;
    }

    // Preload Ad
    AdHelper.preloadInterstitialAd();

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _statusMessage = "Generating...";
      _progress = null;
      _isQueued = false;
      _queuePosition = null;
      _queueTotal = null;
      _queueInfo = null;
    });

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final userId = authRepo.currentUser?.uid;

      if (userId != null) {
        final genRepo = Provider.of<GenerationRepository>(
          context,
          listen: false,
        );
        final limit = await genRepo.getGenerationLimit(userId);

        if (!limit.moreEnabled) {
          final blockedWords = ContentModerator.checkPrompt(
            _promptController.text,
          );
          if (blockedWords.isNotEmpty) {
            if (mounted) {
              setState(() => _isGenerating = false);
              ContentModeratorHelper.showModerationWarning(
                context,
                blockedWords,
              );
            }
            return;
          }
        }
      }

      if (!mounted) return;

      final repository = context.read<DrawAiRepository>();
      final options = {
        "prompt": _promptController.text,
        "width": _selectedSize.split('x')[0],
        "height": _selectedSize.split('x')[1],
        "seed": _seed.toString(),
      };

      await repository.executeToolAndWait(
        toolType: 'make_background',
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
            _isGenerating = false;
          });

          _handlePostProcessNavigation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildPreviewCard(theme),
                        const SizedBox(height: 16),
                        Text(
                          "Generate beautiful anime-style backgrounds without characters. Perfect for wallpapers, game assets, or creative projects.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildConfigCard(theme),
                        const SizedBox(height: 24),
                        if (!_isGenerating)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _generateBackground,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                "Generate Background",
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
            GenerationLoadingOverlay(
              isGenerating: _isGenerating,
              statusMessage: _statusMessage,
              progress: _progress,
              isQueued: _isQueued,
              queuePosition: _queuePosition,
              queueTotal: _queueTotal,
              queueInfo: _queueInfo,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Make Background",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "AI Tools • Scene Generator",
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

  Widget _buildPreviewCard(ThemeData theme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Image.network(
        "https://drawai-api.drawai.site/workflow-image/make_background_v1",
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.image_not_supported)),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Configuration",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Vision Request",
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: "What scene to generate?",
                hintText: "e.g. A cyberpunk city street at night, neon lights",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Text(
              "Canvas Size",
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSize,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: _sizeOptions.map((opt) {
                return DropdownMenuItem(
                  value: opt["id"],
                  child: Text(opt["label"]!),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSize = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Seed", style: TextStyle(fontSize: 12)),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    controller: TextEditingController(text: _seed.toString()),
                    onChanged: (v) => _seed = int.tryParse(v) ?? _seed,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () =>
                      setState(() => _seed = math.Random().nextInt(1000000000)),
                ),
              ],
            ),
            if (_errorMessage != null) _buildErrorText(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
      ),
    );
  }
}
