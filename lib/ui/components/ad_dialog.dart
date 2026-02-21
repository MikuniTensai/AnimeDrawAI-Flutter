import 'dart:async';
import 'package:flutter/material.dart';

/// Ad countdown dialog that shows an ad with a countdown timer.
/// Equivalent to Android's AdDialog composable.
class AdDialog extends StatefulWidget {
  final int countdownSeconds;
  final VoidCallback onComplete;
  final VoidCallback? onSubscribe;
  final Widget? adContent;

  const AdDialog({
    super.key,
    this.countdownSeconds = 5,
    required this.onComplete,
    this.onSubscribe,
    this.adContent,
  });

  static Future<void> show(
    BuildContext context, {
    int countdownSeconds = 5,
    required VoidCallback onComplete,
    VoidCallback? onSubscribe,
    Widget? adContent,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdDialog(
        countdownSeconds: countdownSeconds,
        onComplete: () {
          Navigator.of(ctx).pop();
          onComplete();
        },
        onSubscribe: onSubscribe != null
            ? () {
                Navigator.of(ctx).pop();
                onSubscribe();
              }
            : null,
        adContent: adContent,
      ),
    );
  }

  @override
  State<AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<AdDialog> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canClose = _remaining == 0;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advertisement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: canClose
                        ? theme.colorScheme.primary
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    canClose ? 'Close' : '$_remaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ad content placeholder or actual ad
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  widget.adContent ??
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Advertisement',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            if (widget.onSubscribe != null)
              TextButton(
                onPressed: widget.onSubscribe,
                child: const Text(
                  'Remove ads with Premium',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canClose ? widget.onComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  canClose ? 'Continue' : 'Please wait... $_remaining',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
