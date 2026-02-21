import 'package:flutter/material.dart';

class ContentModeratorHelper {
  static void showModerationWarning(
    BuildContext context,
    List<String> blockedWords,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.security, size: 48, color: Colors.red),
        title: const Text("Sensitive Content Detected"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your prompt contains words that may violate our safety guidelines:",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: blockedWords
                  .map(
                    (word) => Chip(
                      label: Text(word, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              "Please remove these words to proceed.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I Understand"),
          ),
        ],
      ),
    );
  }
}
