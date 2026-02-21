import 'package:flutter/material.dart';

class GenerationLoadingOverlay extends StatelessWidget {
  final bool isGenerating;
  final bool isQueued;
  final double? progress;
  final String statusMessage;
  final int? queuePosition;
  final int? queueTotal;
  final String? queueInfo;

  const GenerationLoadingOverlay({
    super.key,
    required this.isGenerating,
    required this.statusMessage,
    this.isQueued = false,
    this.progress,
    this.queuePosition,
    this.queueTotal,
    this.queueInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGenerating) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Matches logic from GenerateScreen.dart
    String title = "Processing";
    String detail = "Please wait, image is being generated.";
    String statusInfo = "Processing your request now...";

    if (isQueued) {
      title = "Queued";
      detail = "Your request is in queue, please wait.";
      if (queuePosition == 1 && queueTotal == 1) {
        statusInfo = "Processing your request now...";
      } else if ((queuePosition ?? 0) > 1) {
        statusInfo = queueInfo ?? "Position $queuePosition of $queueTotal";
      } else {
        statusInfo = "Initializing...";
      }
    } else if (progress == null) {
      title = "Preparing...";
      detail = "Connecting to server...";
      statusInfo = "Initializing...";
    }

    // Override detail if we are downloading
    if (statusMessage == "Downloading images...") {
      detail = "Saving your masterpiece...";
      statusInfo = "Processing your request now...";
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 12),
              Text(
                statusInfo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
