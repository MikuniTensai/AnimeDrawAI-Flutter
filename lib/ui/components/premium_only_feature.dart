import 'package:flutter/material.dart';

/// A widget that wraps premium-only features with a lock overlay.
/// Shows a lock icon and optional message when the user is not premium.
/// Equivalent to Android's PremiumOnlyFeature composable.
class PremiumOnlyFeature extends StatelessWidget {
  final bool isPremium;
  final Widget child;
  final VoidCallback? onUpgrade;
  final String? lockMessage;

  const PremiumOnlyFeature({
    super.key,
    required this.isPremium,
    required this.child,
    this.onUpgrade,
    this.lockMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) return child;

    return Stack(
      children: [
        // Blurred/dimmed content
        Opacity(opacity: 0.4, child: child),
        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: onUpgrade,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (lockMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      lockMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (onUpgrade != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
