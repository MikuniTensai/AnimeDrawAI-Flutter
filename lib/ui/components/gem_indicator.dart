import 'package:flutter/material.dart';

class GemIndicator extends StatelessWidget {
  final int gemCount;
  final VoidCallback? onClick;

  const GemIndicator({super.key, required this.gemCount, this.onClick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gemColor = Color(0xFFE91E63);

    return GestureDetector(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(204), // 0.8 opacity
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: gemColor, size: 18),
            const SizedBox(width: 6),
            Text(
              gemCount.toString(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
