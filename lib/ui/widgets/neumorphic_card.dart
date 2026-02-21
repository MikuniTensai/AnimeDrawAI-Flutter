import 'package:flutter/material.dart';

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.color,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = color ?? theme.cardColor;

    // Neumorphic shadow colors
    final shadowDark = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.grey.withValues(alpha: 0.2);
    final shadowLight = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            // Darker shadow bottom right
            BoxShadow(
              color: shadowDark,
              offset: const Offset(4, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            // Lighter shadow top left
            BoxShadow(
              color: shadowLight,
              offset: const Offset(-4, -4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      ),
    );
  }
}
