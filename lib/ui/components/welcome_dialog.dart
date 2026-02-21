import 'package:flutter/material.dart';
import '../../data/models/app_settings_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WelcomeDialog extends StatelessWidget {
  final WelcomeMessageData data;
  final VoidCallback onDismiss;

  const WelcomeDialog({super.key, required this.data, required this.onDismiss});

  static Future<void> show(
    BuildContext context, {
    required WelcomeMessageData data,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) =>
          WelcomeDialog(data: data, onDismiss: () => Navigator.of(ctx).pop()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = data.imageUrl != null && data.imageUrl!.isNotEmpty;
    final hasIcon = data.iconUrl != null && data.iconUrl!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: data.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (hasIcon)
                    CachedNetworkImage(
                      imageUrl: data.iconUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    )
                  else if (!hasImage)
                    Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        data.buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
