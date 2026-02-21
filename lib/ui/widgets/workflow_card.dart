import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/api_response.dart';
import 'neumorphic_card.dart';

class WorkflowCard extends StatelessWidget {
  final String workflowId;
  final WorkflowInfo workflow;
  final String? category;
  final VoidCallback? onTap;
  final int gridColumns;
  final bool userIsPremium;

  const WorkflowCard({
    super.key,
    required this.workflowId,
    required this.workflow,
    this.category,
    this.onTap,
    this.gridColumns = 2,
    this.userIsPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String imageUrl =
        "https://drawai-api.drawai.site/workflow-image/$workflowId";

    // 5 Columns: Minimal Layout (Avatar/Icon style)
    if (gridColumns >= 5) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  alignment: Alignment.topCenter,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3 Columns: Compact Layout (Image + Floating Badges)
    if (gridColumns == 3) {
      return GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                alignment: Alignment.topCenter,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: theme.colorScheme.surfaceContainerHighest),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              // Gradient Overlay at bottom for contrast if needed
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Love Icon
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Pro Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: workflow.isPremium
                        ? Colors.amber
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (workflow.isPremium && !userIsPremium)
                        const Padding(
                          padding: EdgeInsets.only(right: 2.0),
                          child: Icon(Icons.lock, size: 8, color: Colors.white),
                        ),
                      Text(
                        "PRO",
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2 Columns: Full Detailed Layout
    return NeumorphicCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Icon Section
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  alignment: Alignment.topCenter,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                // Top-Right Favorite Icon
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 20,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),

                // Bottom Gradient Overlay & Content
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category Tag
                        if (category != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme
                                  .colorScheme
                                  .primary, // using primary as in screenshot (pink/red)
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Title
                        Text(
                          workflow.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Stats Row (Views, Cost, Time)
                        Row(
                          children: [
                            // Views
                            const Icon(
                              Icons.visibility,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                _formatCount(workflow.viewCount),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Cost (Lightning)
                            const Icon(
                              Icons.bolt,
                              size: 10,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                _formatCount(workflow.useCount),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Time
                            const Icon(
                              Icons.timer_outlined,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${workflow.estimatedTime}s",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return "${(count / 1000000).toStringAsFixed(1)}M";
    }
    if (count >= 1000) {
      return "${(count / 1000).toStringAsFixed(1)}k";
    }
    return count.toString();
  }
}
