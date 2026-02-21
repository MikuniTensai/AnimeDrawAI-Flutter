import 'package:flutter/material.dart';

/// Content warning dialog for potentially sensitive content.
/// Equivalent to Android's ContentWarningDialog.
class ContentWarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ContentWarningDialog({
    super.key,
    this.title = 'Content Warning',
    this.message =
        'This content may not be suitable for all audiences. Do you wish to continue?',
    required this.onAccept,
    required this.onDecline,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ContentWarningDialog(
        title: title ?? 'Content Warning',
        message:
            message ??
            'This content may not be suitable for all audiences. Do you wish to continue?',
        onAccept: () => Navigator.of(ctx).pop(true),
        onDecline: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleLarge),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: onDecline, child: const Text('No, go back')),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Yes, continue'),
        ),
      ],
    );
  }
}
