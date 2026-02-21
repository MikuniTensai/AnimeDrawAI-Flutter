import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../services/ad_manager.dart';
import '../../data/repositories/generation_repository.dart';
import '../../data/models/generation_limit_model.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authRepo.currentUser;
    final generationRepo = Provider.of<GenerationRepository>(
      context,
      listen: false,
    );

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, user, generationRepo, theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  label: "Home",
                  isSelected: currentRoute == "home",
                  onTap: () => onNavigate("home"),
                ),
                _buildCollapsibleSection(context, theme),
                _buildSubscriptionItem(context, theme),
                const SizedBox(height: 12),
                _buildColorPicker(context, settingsProvider),
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.emoji_events,
                  label: "Leaderboard",
                  isSelected: currentRoute == "leaderboard",
                  onTap: () => onNavigate("leaderboard"),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  label: "Settings",
                  isSelected: currentRoute == "settings",
                  onTap: () => onNavigate("settings"),
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  label: "Events & Updates",
                  isSelected: currentRoute == "news",
                  onTap: () => onNavigate("news"),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  label: "Help & Support",
                  isSelected: false,
                  onTap: () => _launchEmailSupport(),
                ),
                const SizedBox(height: 16),
                _buildPromoCard(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    GenerationRepository genRepo,
    ThemeData theme,
  ) {
    if (user == null) {
      return Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.only(left: 20, bottom: 16, top: 40),
        decoration: BoxDecoration(color: theme.colorScheme.primary),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Guest",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Sign in to save progress",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<GenerationLimit>(
      stream: genRepo.getGenerationLimitStream(user.uid),
      builder: (context, snapshot) {
        final limit = snapshot.data ?? GenerationLimit();
        final subType = limit.subscriptionType.toLowerCase().trim();
        final isPremium = subType == "pro" || subType == "basic";
        final isPro = subType == "pro";
        final isBasic = subType == "basic";

        return Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16,
            top: 40,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPro
                  ? [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                      theme.colorScheme.primary,
                    ]
                  : isBasic
                  ? [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary.withAlpha(204),
                    ]
                  : [
                      theme.colorScheme.primary.withAlpha(230),
                      theme.colorScheme.primary.withAlpha(180),
                    ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email ?? "",
                          style: TextStyle(
                            color: Colors.white.withAlpha(210),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(limit, theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gens: ${limit.getRemainingGenerations()} / ${limit.getMaxGenerations()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Chat: 0 / ${limit.maxChatLimit}",
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  if (!isPremium)
                    _buildAdButton(context, user.uid, genRepo, theme),
                ],
              ),
              if (isPremium && limit.subscriptionEndDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  "Expires: ${DateFormat('dd MMM yyyy').format(limit.subscriptionEndDate!)}",
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(GenerationLimit? limit, ThemeData theme) {
    if (limit == null) return const SizedBox.shrink();
    final subType = limit.subscriptionType.toLowerCase().trim();
    final isPro = subType == "pro";
    final isBasic = subType == "basic";

    if (subType == "free") return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(77),
        borderRadius: BorderRadius.circular(6),
        border: isPro
            ? Border.all(color: const Color(0xFFFFD700), width: 1)
            : isBasic
            ? Border.all(color: const Color(0xFFC0C0C0), width: 1)
            : null,
      ),
      child: Text(
        subType.toUpperCase(),
        style: TextStyle(
          color: isPro
              ? const Color(0xFFFFD700)
              : isBasic
              ? const Color(0xFFC0C0C0)
              : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAdButton(
    BuildContext context,
    String? userId,
    GenerationRepository genRepo,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () {
        if (userId == null) return;
        AdManager.showRewardedAd(
          onUserEarnedReward: (amount) async {
            try {
              await genRepo.addBonusGeneration(userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("💎 Bonus received! +1 Gen")),
                );
              }
            } catch (e) {
              debugPrint("Error adding bonus stripe: $e");
            }
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(102)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              "+1 Gen",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? null : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? null : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildCollapsibleSection(BuildContext context, ThemeData theme) {
    return ExpansionTile(
      leading: const Icon(Icons.grid_view, color: Colors.grey),
      title: const Text("More Features", style: TextStyle(fontSize: 14)),
      childrenPadding: const EdgeInsets.only(left: 16),
      shape: const Border(),
      children: [
        _buildDrawerItem(
          icon: Icons.inventory_2_outlined,
          label: "Inventory",
          isSelected: false,
          onTap: () => onNavigate("inventory"),
        ),
        _buildDrawerItem(
          icon: Icons.remove_red_eye_outlined,
          label: "Vision",
          isSelected: false,
          onTap: () => onNavigate("vision"),
        ),
        _buildDrawerItem(
          icon: Icons.photo_library_outlined,
          label: "Gallery",
          isSelected: false,
          onTap: () => onNavigate("gallery"),
        ),
        _buildDrawerItem(
          icon: Icons.favorite_border,
          label: "Favorites",
          isSelected: false,
          onTap: () => onNavigate("favorites"),
        ),
        _buildDrawerItem(
          icon: Icons.explore_outlined,
          label: "Explore",
          isSelected: false,
          onTap: () => onNavigate("community"),
        ),
        _buildDrawerItem(
          icon: Icons.chat_bubble_outline,
          label: "AI Chat",
          isSelected: false,
          onTap: () => onNavigate("general_chat"),
        ),
        _buildDrawerItem(
          icon: Icons.group_outlined,
          label: "Characters",
          isSelected: false,
          onTap: () => onNavigate("chat"),
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.white),
            title: const Text(
              "Subscription",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () => onNavigate("subscription"),
          ),
        ),
        // Language
        ListTile(
          leading: const Icon(Icons.language, color: Colors.grey),
          title: const Text("Language", style: TextStyle(fontSize: 14)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Coming Soon",
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Language settings coming soon!")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker(BuildContext context, SettingsProvider settings) {
    final colors = [
      const Color(0xFF6650a4), // Default Purple
      AppColors.themePink,
      AppColors.themeIndigo,
      AppColors.themeBlue,
      AppColors.themeCyan,
      AppColors.themeTeal,
      AppColors.themeSunset,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: colors.map((color) {
          final isSelected = settings.themeColor == color;
          return GestureDetector(
            onTap: () => settings.setThemeColor(color),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(128),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Winter Event!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Check out new seasonal prompts!",
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
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
}
