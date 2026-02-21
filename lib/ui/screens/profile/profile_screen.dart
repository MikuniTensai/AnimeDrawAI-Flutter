import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/generation_repository.dart';
import '../../../data/models/generation_limit_model.dart';
import '../../../data/repositories/usage_statistics_repository.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import '../../components/gem_indicator.dart';
import '../../components/generation_limit_badge.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/gallery_repository.dart';
import '../../../services/ad_manager.dart'; // Replaces RewardedAdHelper

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository>(context);
    final genRepo = Provider.of<GenerationRepository>(context);
    final user = authRepo.currentUser;

    if (user == null) {
      return const Center(child: Text("Please sign in"));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text("Profile"),
        actions: [
          StreamBuilder<int>(
            stream: Provider.of<DrawAiRepository>(
              context,
              listen: false,
            ).getGemCountStream(user.uid),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GemIndicator(
                  gemCount: snapshot.data ?? 0,
                  onClick: () {},
                ),
              );
            },
          ),
          StreamBuilder<GenerationLimit>(
            stream: genRepo.getGenerationLimitStream(user.uid),
            builder: (context, snapshot) {
              final limit = snapshot.data ?? GenerationLimit();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GenerationLimitBadge(
                  limit: limit,
                  onTap: () {
                    // Show details
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<GenerationLimit>(
        stream: genRepo.getGenerationLimitStream(user.uid),
        builder: (context, snapshot) {
          final limit = snapshot.data ?? GenerationLimit();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(user, authRepo, context),
                const SizedBox(height: 24),
                _buildSubscriptionCard(limit, context),
                const SizedBox(height: 24),
                _buildReferralCard(user.uid, context),
                const SizedBox(height: 24),
                _buildMenu(context, authRepo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(user, AuthRepository authRepo, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () =>
                    _showEditNameDialog(context, authRepo, user.displayName),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName ?? "User",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? (user.isAnonymous ? "Guest Account" : ""),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(GenerationLimit limit, BuildContext context) {
    final theme = Theme.of(context);
    final isPremium =
        limit.subscriptionType == "pro" || limit.subscriptionType == "basic";
    final remaining = limit.getRemainingGenerations();
    final maxLimit = limit.getMaxGenerations();

    final progress = maxLimit > 0 ? remaining / maxLimit : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Text(
            "SUBSCRIPTION",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isPremium
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.surfaceContainerHighest,
                        theme.colorScheme.surface,
                      ],
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          limit.subscriptionType.toUpperCase(),
                          style: TextStyle(
                            color: isPremium
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          isPremium ? "Premium Member" : "Free Plan",
                          style: TextStyle(
                            color: isPremium
                                ? Colors.white70
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isPremium ? "👑" : "⚡",
                      style: const TextStyle(fontSize: 32),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Daily Generations",
                          style: TextStyle(
                            color: isPremium
                                ? Colors.white.withValues(alpha: 0.9)
                                : theme.colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "$remaining / $maxLimit",
                          style: TextStyle(
                            color: isPremium
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isPremium
                            ? Colors.white24
                            : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPremium ? Colors.white : theme.colorScheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    if (!isPremium) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Resets daily at 00:00 UTC",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isPremium)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "EXPIRES",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            limit.subscriptionEndDate != null
                                ? DateFormat(
                                    'MM/yy',
                                  ).format(limit.subscriptionEndDate!)
                                : "N/A",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      FilledButton.tonal(
                        onPressed: () {
                          AdManager.showRewardedAd(
                            onUserEarnedReward: (amount) async {
                              try {
                                final genRepo =
                                    Provider.of<GenerationRepository>(
                                      context,
                                      listen: false,
                                    );
                                await genRepo.addBonusGeneration(limit.userId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("💎 +1 Generation Limit!"),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint("Error receiving reward: $e");
                              }
                            },
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "+1 Gen",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to subscription
                        },
                        child: Text(
                          "Upgrade >",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCard(String uid, BuildContext context) {
    final theme = Theme.of(context);
    final referralCode = uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Text(
            "INVITE & REWARDS",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("🎁", style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Invite Friends",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Get 500 Gems for every friend!",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: referralCode),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Your Referral Code",
                    border: const OutlineInputBorder(),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Code copied!")),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Share logic
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Share"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRedeemDialog(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Enter Code"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, AuthRepository authRepo) {
    final theme = Theme.of(context);
    final user = authRepo.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                Icons.history,
                "Usage Statistics",
                () => _showUsageStats(context),
              ),
              _buildMenuItem(Icons.help_outline, "Help & Support", () {
                _launchEmailSupport();
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Text(
            "ACCOUNT Management",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (user != null && user.isAnonymous)
                _buildMenuItem(
                  Icons.link,
                  "Link Account",
                  () => _showLinkAccountDialog(context, authRepo),
                ),
              _buildMenuItem(
                Icons.logout,
                "Sign Out",
                () => _showSignOutWarning(context, authRepo),
              ),
              _buildMenuItem(
                Icons.delete_forever,
                "Delete Account",
                () => _showDeleteDialog(context),
                textColor: theme.colorScheme.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUsageStats(BuildContext context) {
    final statsRepo = Provider.of<UsageStatisticsRepository?>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<UsageStats>(
          future: statsRepo?.getUsageStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? UsageStats();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Usage Statistics",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildStatItem(
                  context,
                  "Total Generations",
                  stats.totalGenerations.toString(),
                  Icons.auto_awesome,
                ),
                _buildStatItem(
                  context,
                  "Images Saved",
                  stats.totalSaves.toString(),
                  Icons.save_alt,
                ),
                _buildStatItem(
                  context,
                  "Favorites",
                  stats.totalFavorites.toString(),
                  Icons.favorite_border,
                ),
                const SizedBox(height: 12),
                if (stats.firstGenerationDate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Member since: ${stats.firstGenerationDate.split(' ')[0]}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Redeem Code"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your code here"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Invalid or expired code")),
              );
              Navigator.pop(context);
            },
            child: const Text("Redeem"),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showSignOutWarning(BuildContext context, AuthRepository authRepo) {
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account deletion will result in permanent loss of:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "• All generated images\n• Premium subscription\n• Unused Gems\n• XP and Level progress\n• Referral benefits",
            ),
            SizedBox(height: 16),
            Text(
              "Deleted data cannot be recovered.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Click below to submit a deletion request via our secure form.",
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
              // Open deletion form URL
              Navigator.pop(context);
            },
            child: const Text(
              "Submit Request",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmailSupport() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      String model = "Unknown";
      String os = "Unknown";

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
        os = "Android ${androidInfo.version.release}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.utsname.machine;
        os = "iOS ${iosInfo.systemVersion}";
      }

      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'nitedreamworks@gmail.com',
        queryParameters: {
          'subject': 'Draw AI - Support Request',
          'body':
              '\n\n---\nApp Version: ${packageInfo.version}\nDevice: $model\nOS: $os\nPlatform: Flutter',
        },
      );

      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
      // Fallback simple mailto
      final Uri simpleUri = Uri(
        scheme: 'mailto',
        path: 'nitedreamworks@gmail.com',
        queryParameters: {'subject': 'Support Request'},
      );
      if (await canLaunchUrl(simpleUri)) {
        await launchUrl(simpleUri);
      }
    }
  }

  void _showEditNameDialog(
    BuildContext context,
    AuthRepository authRepo,
    String? currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await authRepo.updateDisplayName(controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showLinkAccountDialog(BuildContext context, AuthRepository authRepo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Link Account"),
        content: const Text(
          "Link your guest account to Google to save your data permanently and access it from other devices.",
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await authRepo.linkWithGoogle();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text("Link with Google"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
