import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/api_response.dart';
import '../../../data/models/generation_limit_model.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/generation_repository.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../../data/utils/prompt_templates.dart';
import '../../../data/utils/content_moderator.dart';
import '../../utils/content_moderator_helper.dart';
import '../../../services/ad_helper.dart'; // Added for AdMob
import '../../../services/ad_manager.dart'; // Replaces RewardedAdHelper
import '../content/vision_screen.dart'; // Added
import '../../components/generation_limit_badge.dart';
import '../../components/generation_loading_overlay.dart';

class GenerateScreen extends StatefulWidget {
  final String workflowId;
  final WorkflowInfo workflow;

  const GenerateScreen({
    super.key,
    required this.workflowId,
    required this.workflow,
  });

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  // Constants
  static const String _prefsKeyHasPrefilled = "has_prefilled_data";
  static const String _prefsKeyPrompt = "prefilled_prompt";
  static const String _prefsKeyAvoid = "prefilled_avoid";
  static const String _prefsKeyWorkflow = "prefilled_workflow";
  static const String _prefsKeySeed = "prefilled_seed";

  final TextEditingController _positivePromptController =
      TextEditingController();
  final TextEditingController _negativePromptController =
      TextEditingController();
  final TextEditingController _seedController = TextEditingController(
    text: "1062314217360759",
  );

  bool _isGenerating = false;
  String _statusMessage = "";
  double? _progress;

  // Queue Info
  bool _isQueued = false;
  int? _queuePosition;
  int? _queueTotal;
  String? _queueInfo;

  @override
  void initState() {
    super.initState();
    _loadPrefilledData();
    AdManager.loadRewardedAd(); // Preload ad
  }

  @override
  void dispose() {
    _positivePromptController.dispose();
    _negativePromptController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefilledData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsKeyHasPrefilled) == true) {
        final prefilledWorkflow = prefs.getString(_prefsKeyWorkflow) ?? "";

        // Only apply if workflow matches or if params are empty
        if ((prefilledWorkflow == widget.workflowId ||
                prefilledWorkflow.isEmpty) &&
            _positivePromptController.text.isEmpty) {
          final prompt = prefs.getString(_prefsKeyPrompt) ?? "";
          final avoid = prefs.getString(_prefsKeyAvoid) ?? "";
          final seed = prefs.getString(_prefsKeySeed) ?? "";

          setState(() {
            _positivePromptController.text = prompt;
            _negativePromptController.text = avoid;
            if (seed.isNotEmpty) {
              _seedController.text = seed;
            }
          });

          debugPrint("✨ Pre-filled from Gallery: prompt='$prompt'");
        }

        // Clear flag
        await prefs.setBool(_prefsKeyHasPrefilled, false);
      }
    } catch (e) {
      debugPrint("Error reading prefilled data: $e");
    }
  }

  Future<void> _startGeneration() async {
    if (_positivePromptController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a prompt")));
      return;
    }

    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final user = authRepo.currentUser;
    final userId = user?.uid;
    final isAnonymous = user?.isAnonymous ?? true;

    if (userId == null || isAnonymous) {
      _showGuestBindDialog();
      return;
    }

    // Pre-check limit (as requested by user to ensure sync/firebase check)
    try {
      final genRepo = Provider.of<GenerationRepository>(context, listen: false);
      final limit = await genRepo.getGenerationLimit(userId);

      // Prompt Moderation Check
      if (!limit.moreEnabled) {
        final blockedWords = ContentModerator.checkPrompt(
          _positivePromptController.text,
        );
        if (blockedWords.isNotEmpty) {
          if (mounted) {
            ContentModeratorHelper.showModerationWarning(context, blockedWords);
          }
          return;
        }
      }

      if (!limit.canGenerate()) {
        final remaining = limit.getRemainingGenerations();
        _showLimitExceededDialog("Generation limit reached.", remaining);
        return;
      }
    } catch (e) {
      debugPrint("Error pre-checking limit: $e");
      // Continue anyway, server will handle it if it fails
    }

    // Unconditionally begin fetching the interstitial ad now so it's
    // ready by the time generation finishes. If the user turns out to be
    // premium later in the flow, it simply won't be shown.
    AdHelper.preloadInterstitialAd();

    setState(() {
      _isGenerating = true;
      _statusMessage = "Starting...";
      _progress = null;
      _isQueued = false;
      _queuePosition = null;
      _queueTotal = null;
    });

    try {
      // Logic from Kotlin: if empty seed, use random.
      // Here we parse existing text.
      int? seed;
      if (_seedController.text.isNotEmpty) {
        seed = int.tryParse(_seedController.text);
      }

      final result = await drawAiRepo.generateAndWait(
        positivePrompt: _positivePromptController.text,
        negativePrompt: _negativePromptController.text,
        workflow: widget.workflowId,
        userId: userId,
        seed: seed,
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

      debugPrint("Generated files: ${result.resultFiles}");

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = "Success!";
          _progress = 1.0;
        });

        // Delay to show success state briefly
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Generation Complete!")));

          void navigateToGallery() {
            if (mounted) {
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setIndex(2); // Go to Gallery Tab
              Navigator.pop(context);
            }
          }

          try {
            final authRepo = Provider.of<AuthRepository>(
              context,
              listen: false,
            );
            final genRepo = Provider.of<GenerationRepository>(
              context,
              listen: false,
            );
            final userId = authRepo.currentUser?.uid;

            if (userId != null) {
              final limit = await genRepo.getGenerationLimit(userId);
              final isPremium =
                  limit.isPremium == true ||
                  limit.subscriptionType == 'basic' ||
                  limit.subscriptionType == 'pro';

              if (!isPremium) {
                debugPrint("🎬 Showing Interstitial Ad before Gallery");
                AdHelper.showAdAfterSave(onCompleted: navigateToGallery);
              } else {
                navigateToGallery();
              }
            } else {
              navigateToGallery();
            }
          } catch (e) {
            debugPrint("⚠️ Ad check failed, skipping to gallery");
            navigateToGallery();
          }
        }
      }
    } on GenerationLimitExceededException catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showLimitExceededDialog(e.message, e.remaining);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = "Error: $e";
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showLimitExceededDialog(String message, int remaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text("⚡", style: TextStyle(fontSize: 40)),
        title: const Text(
          "Limit Reached",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text("Watch a short ad to get 1 more generation for free!"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showRewardedAd();
            },
            icon: const Icon(Icons.play_circle_fill),
            label: const Text("Watch Ad (+1)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              foregroundColor: Theme.of(context).colorScheme.onTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAd() {
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);
    final userId = authRepo.currentUser?.uid;

    if (userId == null) return;

    AdManager.showRewardedAd(
      onUserEarnedReward: (amount) async {
        try {
          // Success: Reward user with 1 generation (this might be handled server-side too,
          // but we usually sync it or acknowledge it).
          // In Android, it calls repository.addBonus(userId)
          await drawAiRepo.addBonus(userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("💎 Reward received! +1 Generation added."),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error adding bonus: $e");
        }
      },
    );
  }

  void _showGuestBindDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Text("🔒", style: TextStyle(fontSize: 48)),
        title: const Text(
          "Sign In Required",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Guest users cannot generate images.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              "Please sign in with your Google account to start creating amazing AI artwork!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "With Google Account:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "✨ Generate AI images",
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    "💾 Save your creations",
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    "📊 Track your usage",
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    "🎁 Access premium features",
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Trigger Google Sign-In or Linking
              final authRepo = Provider.of<AuthRepository>(
                context,
                listen: false,
              );
              try {
                if (authRepo.currentUser?.isAnonymous ?? true) {
                  await authRepo.linkWithGoogle();
                } else {
                  await authRepo.signInWithGoogle();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            icon: const Text("🔗", style: TextStyle(fontSize: 20)),
            label: const Text("Link Google Account"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Text("🔒", style: TextStyle(fontSize: 24)),
        ),
        title: Text(
          "Premium Workflow",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This workflow is available for subscribers only."),
            SizedBox(height: 8),
            Text(
              "Upgrade to unlock:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text("✨ Premium workflows"),
            Text("📈 More generations"),
            Text("🚫 No advertisements"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setIndex(0); // Go home for now or stay? Kotlin goes Home.
              Navigator.pop(context); // Close screen
            },
            child: const Text("Back"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription
              // You might need a way to navigate to Subscription screen specifically
            },
            child: const Text("Upgrade Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use GenerationLimit stream if possible, otherwise SubscriptionRepo
    // For now we stick to SubscriptionRepo for plan info as per old code,
    // but we should ideally use DrawAiRepository.getLimitStream if available
    final drawAiRepo = Provider.of<DrawAiRepository>(context);
    final authRepo = Provider.of<AuthRepository>(context);
    final userId = authRepo.currentUser?.uid;

    final Stream<GenerationLimit> limitStream = (userId != null)
        ? drawAiRepo.getLimitStream(userId)
        : Stream.value(GenerationLimit()); // Empty default

    return StreamBuilder<GenerationLimit>(
      stream: limitStream,
      builder: (context, snapshot) {
        final limit = snapshot.data ?? GenerationLimit();
        final isPremium =
            limit.isPremium ||
            limit.subscriptionType == 'basic' ||
            limit.subscriptionType == 'pro';

        // Premium Lock Check
        final bool isLocked = widget.workflow.isPremium && !isPremium;

        // Show upgrade dialog if locked and not already showing?
        // Best to handle this in init or via a dedicated lock screen view.
        // For here, we'll just show the locked UI state.

        return Scaffold(
          body: Stack(
            children: [
              // 1. Background Image with Overlay
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl:
                      "https://drawai-api.drawai.site/workflow-image/${widget.workflowId}",
                  fit: BoxFit.cover,
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                  colorBlendMode:
                      BlendMode.srcOver, // Blend background color over image
                  placeholder: (_, __) =>
                      Container(color: theme.colorScheme.surface),
                  errorWidget: (_, __, ___) =>
                      Container(color: theme.colorScheme.surface),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.surface.withValues(alpha: 0.6),
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                        theme.colorScheme.surface,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Main Content
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(context, theme, limit, isLocked),
                            const SizedBox(height: 24),

                            // Positive Prompt
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Describe your vision",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VisionScreen(
                                          workflowId: widget.workflowId,
                                          source: "workflow",
                                          onNavigateToWorkflow:
                                              (id, vision, avoid) {
                                                Navigator.pop(context, {
                                                  'vision': vision,
                                                  'avoid': avoid,
                                                });
                                              },
                                        ),
                                      ),
                                    );

                                    if (result != null &&
                                        result is Map<String, String>) {
                                      setState(() {
                                        _positivePromptController.text =
                                            result['vision'] ?? "";
                                        _negativePromptController.text =
                                            result['avoid'] ?? "";
                                      });
                                    }
                                  },
                                  child: Text(
                                    "Suggest more",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildPromptInput(
                              controller: _positivePromptController,
                              hint:
                                  "E.g. A beautiful landscape with mountains...",
                              minLines: 4,
                              theme: theme,
                            ),
                            const SizedBox(height: 8),
                            _buildSuggestions(
                              context,
                              widget.workflowId,
                              theme,
                              true,
                            ),

                            const SizedBox(height: 24),

                            // Negative Prompt
                            Text(
                              "Things to avoid (Optional)",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPromptInput(
                              controller: _negativePromptController,
                              hint: "E.g. Low quality, blurry...",
                              minLines: 3,
                              theme: theme,
                              isError: true,
                            ),
                            const SizedBox(height: 8),
                            _buildSuggestions(
                              context,
                              widget.workflowId,
                              theme,
                              false,
                            ),

                            const SizedBox(height: 24),

                            // Seed
                            Text(
                              "Seed (Optional)",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSeedInput(theme),

                            const SizedBox(height: 100), // Space for FAB/Button
                          ],
                        ),
                      ),
                    ),

                    // Bottom Button Area
                    _buildBottomButton(context, theme, isLocked, isPremium),
                  ],
                ),
              ),

              // 3. Loading Overlay
              GenerationLoadingOverlay(
                isGenerating: _isGenerating,
                statusMessage: _statusMessage,
                isQueued: _isQueued,
                progress: _progress,
                queuePosition: _queuePosition,
                queueTotal: _queueTotal,
                queueInfo: _queueInfo,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    GenerationLimit limit,
    bool isLocked,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.workflow.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "PRO",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      "${widget.workflow.category ?? 'General'} • ${widget.workflow.estimatedTime}",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Ad & Limit Area
        Row(
          children: [
            // Check if can watch ads
            if (limit.subscriptionType == 'free' &&
                limit.getRemainingGenerations() <= 0)
              InkWell(
                onTap: _showRewardedAd,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text("🎬", style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        "+1",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.onTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GenerationLimitBadge(
              limit: limit,
              onTap: () {
                // Future: Show detailed limit info or navigate to shop
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptInput({
    required TextEditingController controller,
    required String hint,
    required int minLines,
    required ThemeData theme,
    bool isError = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: minLines + 2, // Allow some growth
      minLines: minLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isError
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(
    BuildContext context,
    String workflowId,
    ThemeData theme,
    bool isPositive,
  ) {
    if (!isPositive) {
      // Negative suggestions (Hardcoded equivalent to PromptTemplates.commonNegatives)
      // Since PromptTemplates.commonNegatives was in old file, assumes it's available.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: PromptTemplates.commonNegatives
              .take(5)
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      s,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.errorContainer
                        .withValues(alpha: 0.1),
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onPressed: () {
                      final current = _negativePromptController.text;
                      _negativePromptController.text = current.isEmpty
                          ? s
                          : "$current, $s";
                    },
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    // Positive
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PromptTemplates.getSuggestionsForWorkflow(workflowId)
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    s,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.05,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onPressed: () {
                    final current = _positivePromptController.text;
                    _positivePromptController.text = current.isEmpty
                        ? s
                        : "$current, $s";
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSeedInput(ThemeData theme) {
    return TextField(
      controller: _seedController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Random if empty",
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ThemeData theme,
    bool isLocked,
    bool isPremium,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: isLocked
          ? Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          "PRO users only",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showUpgradeDialog();
                        },
                        child: const Text("Upgrade"),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _startGeneration,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isGenerating
                    ? const Text(
                        "Generating...",
                      ) // Simple text as overlay handles detail
                    : const Text(
                        "Generate Image",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
    );
  }
}
