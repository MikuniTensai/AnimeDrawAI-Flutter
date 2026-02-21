import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/community_model.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/utils/image_utils.dart';
import '../../components/zoomable_image.dart';

/// Full-screen detail view for a community post.
/// Equivalent to Android's PostDetailScreen.
class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  final bool initiallyLiked;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.initiallyLiked = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  bool _isLiking = false;
  bool _showPrompt = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _likeCount = widget.post.likes;
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    final repo = context.read<CommunityRepository>();
    try {
      await repo.toggleLike(widget.post.id);
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _reportPost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text(
          'Are you sure you want to report this post for inappropriate content?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = context.read<CommunityRepository>();
      try {
        await repo.reportPost(widget.post.id, 'inappropriate_content');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post reported. Thank you!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error reporting post: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepo = context.read<AuthRepository>();
    final isOwner = authRepo.currentUser?.uid == widget.post.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: _reportPost,
              tooltip: 'Report',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => setState(() => _showPrompt = !_showPrompt),
            tooltip: 'Show prompt',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen zoomable image
          Positioned.fill(
            child: ZoomableImage(
              child: Builder(
                builder: (context) {
                  final imageUrl = ImageUtils.getFullUrl(widget.post.imageUrl);
                  if (imageUrl.isEmpty) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 48),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            (widget.post.userPhotoUrl != null &&
                                ImageUtils.getFullUrl(
                                  widget.post.userPhotoUrl,
                                ).isNotEmpty)
                            ? NetworkImage(
                                ImageUtils.getFullUrl(
                                  widget.post.userPhotoUrl!,
                                ),
                              )
                            : null,
                        child: widget.post.userPhotoUrl == null
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.post.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Like button
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(_isLiked),
                                color: _isLiked ? Colors.red : Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_likeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Views
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.post.views}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Prompt panel (collapsible)
                  if (_showPrompt && widget.post.prompt.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prompt',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.post.prompt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.post.workflow.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.post.workflow
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
