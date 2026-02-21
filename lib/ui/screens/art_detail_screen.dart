import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../data/repositories/community_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/api_response.dart'; // For WorkflowInfo
import 'generate/generate_screen.dart'; // For navigation
import '../../data/providers/navigation_provider.dart';
import '../../data/models/community_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/generation_repository.dart';

class ArtDetailScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? prompt;
  final String? negativePrompt;
  final String? workflow;
  final String? id;
  final bool isFromGallery;
  final bool isLiked;
  final bool isLocked;
  final int likes;
  final int? seed;

  const ArtDetailScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.prompt,
    this.negativePrompt,
    this.workflow,
    this.id,
    this.isFromGallery = true,
    this.isLiked = false,
    this.isLocked = false,
    this.likes = 0,
    this.seed,
  });

  @override
  State<ArtDetailScreen> createState() => _ArtDetailScreenState();
}

class _ArtDetailScreenState extends State<ArtDetailScreen> {
  late PageController _pageController;
  bool _isLiked = false;
  bool _isLocked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _isLiked = widget.isLiked;
    _isLocked = widget.isLocked;
    _likes = widget.likes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isFromGallery) ...[
            IconButton(
              icon: Icon(
                _isLocked ? Icons.lock_open : Icons.lock_outline,
                color: Colors.white,
              ),
              onPressed: _toggleVaultLock,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _confirmDelete,
            ),
          ],
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
            ),
            onPressed: _toggleLike,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onPressed: _shareImage,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Image Gallery
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: widget.imageUrls[index].isNotEmpty
                    ? CachedNetworkImageProvider(widget.imageUrls[index])
                    : const AssetImage('assets/images/placeholder.png')
                          as ImageProvider,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: widget.imageUrls[index],
                ),
              );
            },
            itemCount: widget.imageUrls.length,
            loadingBuilder: (context, event) =>
                const Center(child: CircularProgressIndicator()),
            pageController: _pageController,
          ),

          // Bottom Info Overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.workflow != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.workflow!.toUpperCase().replaceAll("_", " "),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (widget.prompt != null) ...[
                      const Text(
                        "Prompt",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.prompt!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () => _copyToClipboard(
                              widget.prompt!,
                              "Prompt copied",
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.negativePrompt != null &&
                        widget.negativePrompt!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Negative Prompt",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.negativePrompt!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () => _copyToClipboard(
                              widget.negativePrompt!,
                              "Negative prompt copied",
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (!widget.isFromGallery) ...[
                          const Icon(
                            Icons.favorite,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$_likes",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 20),
                        ],
                        const Spacer(),
                        if (widget.isFromGallery) ...[
                          // Use Again Button
                          if (_isWorkflowImage())
                            ElevatedButton.icon(
                              onPressed: _useAgain,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text("Use Again"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onSecondaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _publishToCommunity,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text("Publish"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isWorkflowImage() {
    final w = widget.workflow?.toLowerCase() ?? "";
    if (w.isEmpty) return false;
    return !w.contains("background_remover") &&
        !w.contains("upscale") &&
        !w.contains("face_restore") &&
        !w.contains("make_background") &&
        !w.contains("sketch_to_image") &&
        !w.contains("photo_editor");
  }

  Future<void> _toggleVaultLock() async {
    final galleryRepo = Provider.of<GalleryRepository>(context, listen: false);

    if (widget.id == null) return;

    final newStatus = !_isLocked;
    setState(() => _isLocked = newStatus);

    try {
      await galleryRepo.toggleVaultLock(widget.id!, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? "Moved to Private Vault" : "Moved to Main Gallery",
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLocked = !newStatus);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _useAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("prefilled_prompt", widget.prompt ?? "");
    await prefs.setString("prefilled_avoid", widget.negativePrompt ?? "");
    await prefs.setString("prefilled_workflow", widget.workflow ?? "");
    await prefs.setString("prefilled_seed", widget.seed?.toString() ?? "");
    await prefs.setBool("has_prefilled_data", true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✨ Opening Generate Menu...")),
      );

      // Navigate to GenerateScreen via named route or provider
      // Assuming typical navigation setup: pop detail, then navigate to generate
      Navigator.pop(context);

      // Use NavigationProvider to switch tab if needed, and push route
      // We'll rely on the app's main router to handle '/generate' with arguments
      // or similar. Since we don't have direct access to main router here,
      // we'll try to push the route directly if possible, or pop until home.

      // Better approach: Just pop. The user might need to navigate manually
      // OR we can try to find the NavigationProvider.
      try {
        final nav = Provider.of<NavigationProvider>(context, listen: false);
        nav.setIndex(1); // Assuming 1 is Generate.
        // However, GenerateScreen needs arguments.
        // We'll rely on the user navigating or the app checking prefs on resume?
        // No, Android explicitly navigates.

        // For now, let's just pop and show the message.
        // Ideally we'd navigate to GenerateScreen(workflowId: widget.workflow)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GenerateScreen(
              workflowId:
                  widget.workflow ?? "anime_ageless_logs", // Default fallack
              workflow: WorkflowInfo(
                name: "Remix", // Placeholder
                description: "Remixed workflow",
                estimatedTime: "15s",
                fileExists: true,
              ),
            ),
          ),
        );
      } catch (e) {
        debugPrint("Navigation error: $e");
      }
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _toggleLike() async {
    final communityRepo = Provider.of<CommunityRepository>(
      context,
      listen: false,
    );
    final galleryRepo = Provider.of<GalleryRepository>(context, listen: false);

    if (widget.id == null) return;

    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likes++ : _likes--;
    });

    try {
      if (widget.isFromGallery) {
        await galleryRepo.toggleFavorite(widget.id!, !widget.isLiked);
      } else {
        await communityRepo.toggleLike(widget.id!);
      }
    } catch (e) {
      // Revert UI on failure
      setState(() {
        _isLiked = !_isLiked;
        _isLiked ? _likes++ : _likes--;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Art?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (context.mounted) {
                final galleryRepo = Provider.of<GalleryRepository>(
                  context,
                  listen: false,
                );
                await galleryRepo.deleteGeneration(widget.id!);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareImage() {
    _publishToCommunity();
  }

  Future<void> _showGuidelinesDialog() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Community Guidelines"),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "By publishing to our community, you agree to follow these rules:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text("• No NSFW or sexually suggestive content."),
              Text("• No extreme violence or gore."),
              Text("• No illegal or harmful content."),
              Text("• No hate speech or harassment."),
              SizedBox(height: 12),
              Text(
                "Warning: Violating these guidelines may result in a permanent ban of your account.",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("I Agree"),
          ),
        ],
      ),
    );

    if (result == true) {
      await prefs.setBool("has_accepted_guidelines", true);
      _performPublish();
    }
  }

  Future<void> _publishToCommunity() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool("has_accepted_guidelines") ?? false;

    // Safety check for ID
    if (widget.id == null) return;

    // Premium Check (Android Parity)
    if (!mounted) return;

    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final genRepo = Provider.of<GenerationRepository>(context, listen: false);
    final uid = authRepo.currentUser?.uid;

    if (uid != null) {
      try {
        final limitInfo = await genRepo.getGenerationLimit(uid);
        if (limitInfo.subscriptionType == "free") {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Only Basic and Pro users can publish to the community.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint("Error checking subscription status: $e");
      }
    }

    if (!mounted) return;

    if (!hasAccepted) {
      _showGuidelinesDialog();
    } else {
      _performPublish();
    }
  }

  Future<void> _performPublish() async {
    final communityRepo = Provider.of<CommunityRepository>(
      context,
      listen: false,
    );
    final galleryRepo = Provider.of<GalleryRepository>(context, listen: false);
    final authRepo = Provider.of<AuthRepository>(context, listen: false);

    if (widget.id == null) return;

    String selectedCategory = "Anime";
    final List<String> categories = [
      "Anime",
      "General",
      "Animal",
      "Flower",
      "Food",
      "Background",
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Publish to Community?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your art will be visible to everyone in the Community tab.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Community Guidelines:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "• No NSFW, violence, or illegal content.\n• Violation may result in a permanent account ban.",
                      style: TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Category:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCategory = val);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Publish"),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final post = CommunityPost(
          id: "",
          userId: authRepo.currentUser?.uid ?? "",
          imageUrl: widget.imageUrls[0],
          thumbnailUrl: widget.imageUrls[0],
          prompt: widget.prompt ?? "",
          negativePrompt: widget.negativePrompt ?? "",
          workflow: widget.workflow ?? "standard",
          username: authRepo.currentUser?.displayName ?? "User",
          category: selectedCategory,
          likes: 0,
          views: 0,
          downloads: 0,
          createdAt: DateTime.now(),
        );

        final postId = await communityRepo.publishPostFromGallery(post: post);
        await galleryRepo.markAsShared(widget.id!, postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Published successfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error publishing: $e")));
        }
      }
    }
  }
}
