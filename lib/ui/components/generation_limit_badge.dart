import 'package:flutter/material.dart';
import '../../data/models/generation_limit_model.dart';

class GenerationLimitBadge extends StatelessWidget {
  final GenerationLimit limit;
  final VoidCallback? onTap;

  const GenerationLimitBadge({super.key, required this.limit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = limit.getRemainingGenerations();
    final isPremium = limit.subscriptionType != 'free';
    final isLow = remaining <= 0;

    final statusColor = isLow
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isPremium ? "👑" : "⚡", style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              "$remaining",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
