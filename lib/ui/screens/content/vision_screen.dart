import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/models/vision_model.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../../data/utils/image_utils.dart';

class VisionScreen extends StatefulWidget {
  final Function(String, String, String)? onNavigateToWorkflow;
  final String? source;
  final String? workflowId;

  const VisionScreen({
    super.key,
    this.onNavigateToWorkflow,
    this.source,
    this.workflowId,
  });

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  List<VisionItem> _allItems = [];
  List<VisionItem> _shuffledItems = [];
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchVisions();
  }

  Future<void> _fetchVisions({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = Provider.of<DrawAiRepository>(context, listen: false);
      final items = await repo.getVisions(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _allItems = items;
          _shuffledItems = List.from(_allItems)..shuffle();
          _currentPage = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load visions: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _shuffleItems() {
    setState(() {
      _shuffledItems = List.from(_allItems)..shuffle();
      _currentPage = 0;
      _scrollToTop();
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _loadNextPage() {
    if ((_currentPage + 1) * _pageSize < _shuffledItems.length) {
      setState(() {
        _currentPage++;
        _scrollToTop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // In Flutter, we might show a drawer icon if it's the main route
    // or a back button if pushed.

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vision Prompts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Expand your imagination", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _shuffleItems,
            tooltip: "Shuffle",
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _fetchVisions(forceRefresh: true),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_allItems.isEmpty) {
      return const Center(child: Text("No visions found"));
    }

    final displayedItems = _shuffledItems
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65, // Adjust based on card content
            ),
            itemCount: displayedItems.length,
            itemBuilder: (context, index) {
              return _VisionCard(
                item: displayedItems[index],
                onUse: (item) {
                  if (widget.onNavigateToWorkflow != null &&
                      widget.workflowId != null) {
                    widget.onNavigateToWorkflow!(
                      widget.workflowId!,
                      item.vision,
                      item.avoid,
                    );
                  } else {
                    // Standalone mode (from drawer): Navigate back to Home
                    // and then somehow pass the prompt.
                    // For now, navigating back and showing a SnackBar is a good start,
                    // but we should ideally use the NavigationProvider.
                    Navigator.pop(context);
                    Provider.of<NavigationProvider>(
                      context,
                      listen: false,
                    ).setIndex(0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Prompt copied! Select a workflow to generate.",
                        ),
                        action: SnackBarAction(label: "OK", onPressed: () {}),
                      ),
                    );
                    Clipboard.setData(ClipboardData(text: item.vision));
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),
          // Pagination Controls
          if ((_currentPage + 1) * _pageSize < _shuffledItems.length)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _loadNextPage,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Next Page"),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),

          if ((_currentPage + 1) * _pageSize >= _shuffledItems.length &&
              _shuffledItems.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _shuffleItems,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Shuffle & Restart"),
                    SizedBox(width: 8),
                    Icon(Icons.refresh, size: 16),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80), // Space for bottom nav or FAB
        ],
      ),
    );
  }
}

class _VisionCard extends StatefulWidget {
  final VisionItem item;
  final Function(VisionItem)? onUse;

  const _VisionCard({required this.item, this.onUse});

  @override
  State<_VisionCard> createState() => _VisionCardState();
}

class _VisionCardState extends State<_VisionCard> {
  bool _showAvoid = false;
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.item.vision));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              width: double.infinity,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUtils.getFullUrl(item.imageUrl!),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.brush,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
            ),
          ),

          // Content
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vision Text
                  Text(
                    item.vision,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Copy Feedback
                  if (_copied)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "✓ Copied",
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                  // Actions
                  Row(
                    children: [
                      // Copy Button
                      InkWell(
                        onTap: _copyToClipboard,
                        child: Text(
                          "Copy",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Avoid Toggle
                      if (item.avoid.isNotEmpty)
                        InkWell(
                          onTap: () => setState(() => _showAvoid = !_showAvoid),
                          child: Row(
                            children: [
                              Text(
                                "Avoid",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              Icon(
                                _showAvoid
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 14,
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Avoid Text (collapsible)
                  if (_showAvoid && item.avoid.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.avoid,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Use Button
                  if (widget.onUse != null)
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => widget.onUse!(item),
                        child: const Text(
                          "Use",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
