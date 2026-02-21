import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/gallery_model.dart';
import '../../../data/repositories/gallery_repository.dart';

import '../art_detail_screen.dart';
import '../../components/gem_indicator.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/drawai_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'character_creation_dialog.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../components/generation_limit_badge.dart';
import '../../../data/repositories/generation_repository.dart';
import '../../../data/models/generation_limit_model.dart';
import '../../../data/utils/image_utils.dart';
import '../../components/banner_ad_widget.dart';
import '../../components/native_ad_card.dart';

class GalleryScreen extends StatefulWidget {
  final bool showFavorites;
  final bool isSelectionMode;

  const GalleryScreen({
    super.key,
    this.showFavorites = false,
    this.isSelectionMode = false,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late bool _showOnlyFavorites;
  late bool _isSelectionMode;
  bool _showLockedOnly = false;
  bool _isVaultUnlocked = false;

  @override
  void initState() {
    super.initState();
    _showOnlyFavorites = widget.showFavorites;
    _isSelectionMode = widget.isSelectionMode;
  }

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<GalleryRepository>(context);

    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(_showLockedOnly ? "Private Vault" : "My Gallery"),
        actions: [
          StreamBuilder<int>(
            stream: drawAiRepo.getGemCountStream(
              authRepo.currentUser?.uid ?? "",
            ),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GemIndicator(
                  gemCount: snapshot.data ?? 0,
                  onClick: () {},
                ),
              );
            },
          ),
          StreamBuilder<GenerationLimit>(
            stream: Provider.of<GenerationRepository>(
              context,
              listen: false,
            ).getGenerationLimitStream(authRepo.currentUser?.uid ?? ""),
            builder: (context, snapshot) {
              final limit = snapshot.data ?? GenerationLimit();
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: GenerationLimitBadge(
                  limit: limit,
                  onTap: () {
                    // Navigate to subscription or show details
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showLockedOnly ? Icons.lock_open : Icons.lock_outline,
              color: _showLockedOnly ? Colors.orange : null,
            ),
            onPressed: _handleVaultToggle,
          ),
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () =>
                setState(() => _showOnlyFavorites = !_showOnlyFavorites),
            color: _showOnlyFavorites ? Colors.red : null,
          ),
        ],
      ),
      body: StreamBuilder<GenerationLimit>(
        stream: Provider.of<DrawAiRepository>(context, listen: false)
            .getLimitStream(
              Provider.of<AuthRepository>(
                    context,
                    listen: false,
                  ).currentUser?.uid ??
                  "",
            ),
        builder: (context, limitSnapshot) {
          final limit = limitSnapshot.data ?? GenerationLimit();
          final isPremium =
              limit.isPremium == true ||
              limit.subscriptionType == 'basic' ||
              limit.subscriptionType == 'pro';

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<GeneratedImage>>(
                  stream: repository.getGenerationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final error = snapshot.error.toString();
                      final isIndexError =
                          error.contains("FAILED_PRECONDITION") ||
                          error.contains("index");

                      return Column(
                        children: [
                          if (isIndexError)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: Colors.orange.withValues(alpha: 0.1),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Cloud sync is initializing. Some remote images might be missing temporarily.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child:
                                snapshot.data == null || snapshot.data!.isEmpty
                                ? _buildErrorState(error)
                                : _buildGrid(snapshot.data!, isPremium),
                          ),
                        ],
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return _buildLoadingGrid();
                    }

                    var images = snapshot.data ?? [];

                    // 1. Filter by Lock status
                    if (_showLockedOnly) {
                      images = images.where((img) => img.isLocked).toList();
                    } else {
                      images = images.where((img) => !img.isLocked).toList();
                    }

                    // 2. Filter by Favorites
                    if (_showOnlyFavorites) {
                      images = images.where((img) => img.isFavorite).toList();
                    }

                    if (images.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildGrid(images, isPremium);
                  },
                ),
              ),
              if (!isPremium)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: BannerAdWidget(),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isSelectionMode = !_isSelectionMode;
          });
          if (_isSelectionMode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Select an image to summon a character"),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(_isSelectionMode ? Icons.close : Icons.person_add),
      ),
    );
  }

  Future<void> _handleVaultToggle() async {
    if (_showLockedOnly) {
      setState(() {
        _showLockedOnly = false;
        _isVaultUnlocked = false; // Relock when leaving
      });
      return;
    }

    if (_isVaultUnlocked) {
      setState(() => _showLockedOnly = true);
      return;
    }

    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const _GalleryPinDialog(),
    );

    if (success == true) {
      setState(() {
        _isVaultUnlocked = true;
        _showLockedOnly = true;
      });
    }
  }

  Widget _buildGrid(List<GeneratedImage> images, bool isPremium) {
    // If not premium, inject Native Ad every 8 items
    final int itemsCount = isPremium
        ? images.length
        : images.length + (images.length ~/ 8);

    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: itemsCount,
      itemBuilder: (context, index) {
        if (!isPremium && index > 0 && (index + 1) % 9 == 0) {
          return const NativeAdCard();
        }

        // Calculate the actual image index
        final imageIndex = isPremium ? index : index - (index ~/ 9);

        if (imageIndex >= images.length) {
          return const SizedBox.shrink(); // Prevent OOB
        }

        return _GalleryCard(
          image: images[imageIndex],
          isSelectionMode: _isSelectionMode,
          onSelect: () {
            setState(() => _isSelectionMode = false);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Connection Error",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          height: (index % 2 == 0) ? 200 : 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _showLockedOnly
                ? "Your vault is empty"
                : _showOnlyFavorites
                ? "No favorite art yet"
                : "No art generated yet",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (!_showOnlyFavorites && !_showLockedOnly)
            ElevatedButton(
              onPressed: () {
                final navProvider = Provider.of<NavigationProvider>(
                  context,
                  listen: false,
                );
                navProvider.setIndex(0); // Switch to Home tab
                // Check if we need to pop (if Gallery was pushed on top of MainScreen)
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Start Creating"),
            ),
        ],
      ),
    );
  }
}

class _GalleryPinDialog extends StatefulWidget {
  const _GalleryPinDialog();

  @override
  State<_GalleryPinDialog> createState() => _GalleryPinDialogState();
}

class _GalleryPinDialogState extends State<_GalleryPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter Gallery PIN"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your 4-digit PIN to access private images."),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: "****",
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: _verifyPin, child: const Text("Unlock")),
      ],
    );
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString("gallery_vault_pin");

    if (savedPin == null) {
      // First time setting PIN
      if (_pinController.text.length < 4) {
        setState(() => _error = "PIN must be 4 digits");
        return;
      }
      await prefs.setString("gallery_vault_pin", _pinController.text);
      if (mounted) Navigator.pop(context, true);
    } else {
      if (_pinController.text == savedPin) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _error = "Incorrect PIN");
      }
    }
  }
}

class _GalleryCard extends StatelessWidget {
  final GeneratedImage image;
  final bool isSelectionMode;
  final VoidCallback? onSelect;

  const _GalleryCard({
    required this.image,
    this.isSelectionMode = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = Provider.of<GalleryRepository>(context, listen: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelectionMode
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      elevation: isSelectionMode ? 8 : 2,
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            _summonCharacter(context);
            onSelect?.call();
          } else {
            _showDetails(context);
          }
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final imageUrl = ImageUtils.getFullUrl(image.imageUrl);
                    if (imageUrl.isEmpty) {
                      return Container(
                        height: 150,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    }
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        image.workflow.replaceAll("_", " "),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      if (image.isShared)
                        const Icon(
                          Icons.cloud_done,
                          size: 14,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    image.isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: image.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () =>
                      repository.toggleFavorite(image.id, image.isFavorite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtDetailScreen(
          imageUrls: [ImageUtils.getFullUrl(image.imageUrl)],
          prompt: image.prompt,
          negativePrompt: image.negativePrompt,
          workflow: image.workflow,
          id: image.id,
          isFromGallery: true,
          isLiked: image.isFavorite,
          isLocked: image.isLocked,
          seed: image.seed,
        ),
      ),
    );
  }

  void _summonCharacter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CharacterCreationDialog(image: image),
    );
  }
}
