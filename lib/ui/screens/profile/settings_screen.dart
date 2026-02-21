import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/gallery_repository.dart';
import '../../../data/providers/settings_provider.dart';
import '../../../data/models/generation_limit_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);
    final galleryRepo = Provider.of<GalleryRepository>(context, listen: false);

    final user = authRepo.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionHeader("Account & Subscription"),
          _buildSubscriptionTile(context, user?.uid),
          if (user?.isAnonymous ?? true)
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text("Link Account"),
              subtitle: const Text("Sync your progress across devices"),
              onTap: () => _showLinkAccountOptions(context, authRepo),
            ),
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.orange),
            title: const Text("Redeem Promo Code"),
            subtitle: const Text("Enter code to claim rewards"),
            onTap: () => _showRedeemCodeDialog(context, drawAiRepo),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text("Sign Out"),
            onTap: () => _confirmSignOut(context, authRepo),
          ),

          const Divider(),
          _buildSectionHeader("App Preferences"),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Colors.purple),
            title: const Text("Dark Mode"),
            subtitle: const Text("Use dark theme throughout the app"),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.save, color: Colors.green),
            title: const Text("Auto-Save"),
            subtitle: const Text("Automatically save images to cloud"),
            value: settings.isAutoSave,
            onChanged: (val) => settings.toggleAutoSave(val),
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.blue),
            title: const Text("Export Gallery"),
            subtitle: const Text("Save all local images to device gallery"),
            onTap: () => _exportGallery(context, galleryRepo),
          ),

          const Divider(),
          _buildSectionHeader("Safety & Control"),
          _buildRestrictedContentTile(context, settings),
          _buildMoreContentTile(context, drawAiRepo, user?.uid),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.amber),
            title: const Text("Gallery Lock"),
            subtitle: Text(
              settings.isGalleryLocked
                  ? "PIN Protected"
                  : "Set PIN to protect gallery",
            ),
            onTap: () => _showPinSettings(context, settings),
          ),

          const Divider(),
          _buildSectionHeader("Notifications"),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_active,
              color: Colors.teal,
            ),
            title: const Text("Daily Check-in Reminder"),
            subtitle: const Text("Get reminded to claim your daily rewards"),
            value: settings.isNotificationsEnabled,
            onChanged: (val) => settings.toggleNotifications(val),
          ),
          if (settings.isNotificationsEnabled)
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.teal),
              title: const Text("Reminder Time"),
              trailing: Text(
                settings.reminderTime,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              onTap: () => _selectReminderTime(context, settings),
            ),

          const Divider(),
          _buildSectionHeader("Support & Community"),
          ListTile(
            leading: const Icon(Icons.telegram, color: Color(0xFF0088cc)),
            title: const Text("Telegram Group"),
            onTap: () => _launchUrl("https://t.me/animedrawai"),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
            title: const Text("WhatsApp Support"),
            onTap: () => _launchUrl("https://wa.me/yourwhatsapp"),
          ),
          ListTile(
            leading: const Icon(Icons.article, color: Colors.blueGrey),
            title: const Text("Release Notes"),
            onTap: () => Navigator.pushNamed(context, '/news'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("App Version"),
            trailing: Text("1.0.0+1"),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Delete Account",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showDeleteDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(BuildContext context, String? userId) {
    if (userId == null) return const SizedBox();

    return StreamBuilder<GenerationLimit>(
      stream: Provider.of<DrawAiRepository>(
        context,
        listen: false,
      ).getLimitStream(userId),
      builder: (context, snapshot) {
        final limit = snapshot.data;
        final type = limit?.subscriptionType.trim().toUpperCase() ?? "FREE";
        final color = type == "PRO"
            ? Colors.amber
            : (type == "BASIC" ? Colors.blue : Colors.grey);

        return ListTile(
          leading: Icon(Icons.stars, color: color),
          title: const Text("Subscription Plan"),
          subtitle: Text("Current status: $type"),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: () => Navigator.pushNamed(context, '/subscription'),
        );
      },
    );
  }

  Widget _buildMoreContentTile(
    BuildContext context,
    DrawAiRepository drawAiRepo,
    String? userId,
  ) {
    if (userId == null) return const SizedBox();

    return StreamBuilder<GenerationLimit>(
      stream: drawAiRepo.getLimitStream(userId),
      builder: (context, snapshot) {
        final limit = snapshot.data;
        final status = limit?.moreRequestStatus ?? "";
        final isEnabled = limit?.moreEnabled ?? false;

        return SwitchListTile(
          secondary: const Icon(
            Icons.add_circle_outline,
            color: Colors.deepOrange,
          ),
          title: const Text("More"),
          subtitle: Text(_getMoreStatusText(status, isEnabled)),
          value: isEnabled,
          onChanged: (val) async {
            if (val) {
              // User trying to enable
              if (limit == null || limit.subscriptionType == 'free') {
                _showUpgradeDialog(context);
                return;
              }

              if (limit.moreRequestStatus == 'pending') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Activation request pending review"),
                  ),
                );
              } else if (limit.moreRequestStatus == 'approved') {
                // Should be enabled, but if for some reason it's not
                await drawAiRepo.toggleMoreEnabled(true);
              } else {
                // Status is '' or 'rejected', show request dialog
                _showMoreRequestDialog(context, drawAiRepo);
              }
            } else {
              // User trying to disable
              await drawAiRepo.toggleMoreEnabled(false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Feature disabled")),
                );
              }
            }
          },
        );
      },
    );
  }

  String _getMoreStatusText(String status, bool isEnabled) {
    if (isEnabled) return "More content enabled";
    switch (status) {
      case "pending":
        return "Activation request pending review";
      case "approved":
        return "Content improved (please restart)";
      case "rejected":
        return "Request rejected. Click to retry.";
      default:
        return "Tap to request more diverse content";
    }
  }

  Widget _buildRestrictedContentTile(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.warning_amber, color: Colors.redAccent),
      title: const Text("Restricted Content"),
      subtitle: const Text("Allow diverse content generations"),
      value: settings.isRestrictedContentEnabled,
      onChanged: (val) {
        if (val) {
          _showContentWarning(context, settings);
        } else {
          settings.setRestrictedContent(false);
        }
      },
    );
  }

  // --- Actions & Dialogs ---

  void _showRedeemCodeDialog(BuildContext context, DrawAiRepository repo) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Redeem Promo Code"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter code here",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(context);
              try {
                final reward = await repo.redeemCode(code);
                if (context.mounted) {
                  _showSuccessDialog(
                    context,
                    "Success!",
                    "You have received $reward Gems.",
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorDialog(context, e.toString());
                }
              }
            },
            child: const Text("Redeem"),
          ),
        ],
      ),
    );
  }

  void _showMoreRequestDialog(BuildContext context, DrawAiRepository repo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request More Content"),
        content: const Text(
          "This will request access to a wider variety of generation models. Your request will be reviewed by administrators.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await repo.requestMoreAccess();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Request sent! Waiting for admin approval."),
                  ),
                );
              }
            },
            child: const Text("Request"),
          ),
        ],
      ),
    );
  }

  void _showContentWarning(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Content Warning"),
          ],
        ),
        content: const Text(
          "By enabling this, you understand that you may see adult content. You must be 18+ years old.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAgeVerification(context, settings);
            },
            child: const Text("I Understand"),
          ),
        ],
      ),
    );
  }

  void _showAgeVerification(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Age Verification"),
        content: const Text("Are you 18 years or older?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No, I'm under 18"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMathChallenge(context, settings);
            },
            child: const Text("Yes, I am 18+"),
          ),
        ],
      ),
    );
  }

  void _showMathChallenge(BuildContext context, SettingsProvider settings) {
    final a = 12, b = 7;
    final answer = a + b;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Security Check"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please solve this to verify you are an adult:"),
            const SizedBox(height: 16),
            Text(
              "$a + $b = ?",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "Answer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (int.tryParse(controller.text) == answer) {
                settings.setRestrictedContent(true);
                settings.setAgeVerified(true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Content filtering disabled")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect answer")),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _showPinSettings(BuildContext context, SettingsProvider settings) {
    // Basic PIN setup dialog (SIMPLIFIED for migration)
    final controller = TextEditingController();
    final isRemoving = settings.isGalleryLocked;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRemoving ? "Remove Gallery PIN" : "Set Gallery PIN"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: InputDecoration(
            hintText: isRemoving ? "Current PIN" : "Enter 4-digit PIN",
          ),
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final pin = controller.text;
              if (pin.length == 4) {
                if (isRemoving) {
                  if (pin == settings.galleryPin) {
                    settings.setGalleryPin(null);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Wrong PIN")));
                  }
                } else {
                  settings.setGalleryPin(pin);
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isRemoving ? "Remove" : "Set"),
          ),
        ],
      ),
    );
  }

  void _selectReminderTime(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final curTimeParts = settings.reminderTime.split(":");
    final currentHour = int.tryParse(curTimeParts[0]) ?? 20;
    final currentMin = int.tryParse(curTimeParts[1]) ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMin),
    );

    if (picked != null) {
      settings.setReminderTime(picked.hour, picked.minute);
    }
  }

  void _exportGallery(
    BuildContext context,
    GalleryRepository galleryRepo,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exporting images to device gallery...")),
    );

    await galleryRepo.exportGallery();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gallery exported successfully!")),
      );
    }
  }

  void _showLinkAccountOptions(BuildContext context, AuthRepository auth) {
    // Show Google/Email linking options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Linking options: Google/Email")),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthRepository authRepo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text("⚠️ ", style: TextStyle(fontSize: 20)),
            Text("Warning"),
          ],
        ),
        content: const Text(
          "Signing out will delete all generated images in your localized gallery from this device. To save them, please go to Settings > Export to Gallery first.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final galleryRepo = Provider.of<GalleryRepository>(
                context,
                listen: false,
              );
              await galleryRepo.clearGallery();
              await authRepo.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Warning: This will permanently delete your credits and generations. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.stars, size: 48, color: Colors.amber),
        title: const Text("Upgrade Required"),
        content: const Text(
          "The 'More' content feature is available for Basic and Pro subscribers only. Upgrade now to unlock more diverse models!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription');
            },
            child: const Text("Show Plans"),
          ),
        ],
      ),
    );
  }
}
