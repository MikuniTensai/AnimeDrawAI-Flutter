import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/drawai_repository.dart';
import '../../data/models/generation_limit_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/models/character_model.dart';
import '../../services/billing_manager.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _gradientPosition = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_animController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billingManager = Provider.of<BillingManager>(
        context,
        listen: false,
      );
      billingManager.onPurchaseResult = (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      };
      billingManager.onGachaResult = (amount) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("🎉 Jackpot!"),
            content: Text("You received +$amount Chat Slots!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Awesome!"),
              ),
            ],
          ),
        );
      };
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handlePurchase(String productType) {
    if (!mounted) return;
    final billingManager = Provider.of<BillingManager>(context, listen: false);

    switch (productType) {
      case "BASIC":
        billingManager.buyProduct(BillingManager.kBasicProductId);
        break;
      case "PRO":
        billingManager.buyProduct(BillingManager.kProProductId);
        break;
      case "CHAT_GACHA":
        billingManager.buyProduct(BillingManager.kChatRandomProductId);
        break;
      case "CHAT_SINGLE":
        billingManager.buyProduct(BillingManager.kChat1ProductId);
        break;
      case "ONE_DAY_PASS":
        billingManager.buyProduct(BillingManager.kOneDayProductId);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid product selection")),
        );
    }
  }

  void _showBenefitsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  "Premium Benefits",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      _BenefitRow(
                        title: "⚡ Increased Gen Limits",
                        subtitle:
                            "Generate 200 or 600 images daily instead of 5",
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        title: "🚫 Ad-Free Experience",
                        subtitle: "No more interruptions while creating",
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        title: "💬 Extra Chat Limits",
                        subtitle: "Chat more with AI characters",
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        title: "✨ Community Access",
                        subtitle: "Share and browse the Explore feed",
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        title: "❤️ Likes & Engagement",
                        subtitle: "Interact with other creators",
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        title: "📥 Bulk Export",
                        subtitle: "Export all your creations at once",
                      ),
                      SizedBox(height: 16),
                      _BenefitRow(
                        title: "🔐 Gallery Lock",
                        subtitle: "Protect your gallery with PIN",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Got it!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String planName,
    String price,
    String limitDesc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            "Upgrade to $planName",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total: $price",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("• $limitDesc"),
              const Text("• Ad-free experience"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.primary,
                foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _handlePurchase(planName);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  String _calculateEffectivePlan(GenerationLimit? limit) {
    if (limit == null) return "FREE";
    if (limit.subscriptionEndDate != null &&
        limit.subscriptionEndDate!.isBefore(DateTime.now())) {
      return "FREE";
    }
    return limit.subscriptionType.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawAiRepo = Provider.of<DrawAiRepository>(context);
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final billingManager = Provider.of<BillingManager>(
      context,
    ); // Listen to price changes
    final userId = authRepo.currentUser?.uid ?? "";
    final userEmail = authRepo.currentUser?.email ?? "Guest";

    CharacterRepository? charRepo;
    try {
      charRepo = Provider.of<CharacterRepository>(context, listen: false);
    } catch (_) {}

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: theme.colorScheme.surface,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Subscription",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<GenerationLimit>(
                stream: drawAiRepo.getLimitStream(userId),
                builder: (context, limitSnapshot) {
                  final limit = limitSnapshot.data;
                  final effectivePlan = _calculateEffectivePlan(limit);

                  return StreamBuilder<List<CharacterModel>>(
                    stream: charRepo?.getCharactersStream() ?? Stream.value([]),
                    builder: (context, charSnapshot) {
                      final characterCount = charSnapshot.data?.length ?? 0;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Active Plan Info Card
                            AnimatedBuilder(
                              animation: _gradientPosition,
                              builder: (context, child) {
                                return _buildActivePlanCard(
                                  theme: theme,
                                  effectivePlan: effectivePlan,
                                  limit: limit,
                                  userEmail: userEmail,
                                  characterCount: characterCount,
                                  gradientPosition: _gradientPosition.value,
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Choose Plan Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Choose Your Plan",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _showBenefitsPopup(context),
                                  child: const Text(
                                    "See Benefits",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 1 Day Pass Card
                            _buildOneDayPassCard(theme, billingManager),
                            const SizedBox(height: 16),

                            // Compact Plans Row
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildCompactPlanCard(
                                      theme: theme,
                                      context: context,
                                      planName: 'BASIC',
                                      price: billingManager.basicPrice,
                                      limitText: '200 Gens',
                                      chatText: '💬 +3 Chat Limit',
                                      isCurrentPlan: effectivePlan == "BASIC",
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactPlanCard(
                                      theme: theme,
                                      context: context,
                                      planName: 'PRO',
                                      price: billingManager.proPrice,
                                      limitText: '600 Gens',
                                      chatText: '💬 +10 Chat Limit',
                                      isCurrentPlan: effectivePlan == "PRO",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              "Chat Add-ons",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Add-ons Row
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildAddonCard(
                                      theme: theme,
                                      title: "Gacha",
                                      desc: "Random limits",
                                      price: billingManager.chatRandomPrice,
                                      isGacha: true,
                                      onTap: () =>
                                          _handlePurchase("CHAT_GACHA"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildAddonCard(
                                      theme: theme,
                                      title: "Single Limit",
                                      desc: "+1 Chat Limit",
                                      price: billingManager.chat1Price,
                                      isGacha: false,
                                      onTap: () =>
                                          _handlePurchase("CHAT_SINGLE"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Payment Issue Notice
                            Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Payment Issues?",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            "If your plan doesn't update after payment, please contact us via Email in Settings.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlanCard({
    required ThemeData theme,
    required String effectivePlan,
    required GenerationLimit? limit,
    required String userEmail,
    required int characterCount,
    required double gradientPosition,
  }) {
    List<Color> gradientColors;
    if (effectivePlan == "PRO") {
      gradientColors = [
        theme.colorScheme.primary,
        theme.colorScheme.secondary,
        theme.colorScheme.primary,
      ];
    } else if (effectivePlan == "BASIC") {
      gradientColors = [theme.colorScheme.primary, theme.colorScheme.secondary];
    } else {
      gradientColors = [
        theme.colorScheme.primary.withValues(alpha: 0.8),
        theme.colorScheme.primary.withValues(alpha: 0.6),
      ];
    }

    final Alignment startAlign = effectivePlan == "PRO"
        ? Alignment(gradientPosition, 0)
        : Alignment.topCenter;

    final Alignment endAlign = effectivePlan == "PRO"
        ? Alignment(gradientPosition + 1.0, 1.0)
        : Alignment.bottomCenter;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: startAlign,
          end: endAlign,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Account Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userEmail == "Guest" ? "Guest User" : userEmail,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),

                if (limit != null) ...[
                  Text(
                    "Generations: ${limit.getRemainingGenerations()} / ${limit.getMaxGenerations()}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (effectivePlan != "FREE" &&
                      limit.subscriptionEndDate != null)
                    Text(
                      "Expires: ${DateFormat('dd MMM yyyy').format(limit.subscriptionEndDate!)}",
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  Text(
                    "Chat Slots: $characterCount/${limit.maxChatLimit}",
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ] else ...[
                  const Text(
                    "Loading limits...",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              effectivePlan,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: effectivePlan == "PRO"
                    ? const Color(0xFFFFD700)
                    : effectivePlan == "BASIC"
                    ? const Color(0xFFE0E0E0)
                    : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOneDayPassCard(ThemeData theme, BillingManager billingManager) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handlePurchase("ONE_DAY_PASS"),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Try in 1 DAY",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    billingManager.oneDayPrice,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Full Premium Access for 24h",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _handlePurchase("ONE_DAY_PASS"),
                  child: const Text("Buy", style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPlanCard({
    required ThemeData theme,
    required BuildContext context,
    required String planName,
    required String price,
    required String limitText,
    required String chatText,
    required bool isCurrentPlan,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPlan ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCurrentPlan
            ? null
            : () => _showConfirmDialog(context, planName, price, limitText),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                planName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                limitText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                chatText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 16),
              if (!isCurrentPlan)
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () =>
                        _showConfirmDialog(context, planName, price, limitText),
                    child: const Text("Buy", style: TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddonCard({
    required ThemeData theme,
    required String title,
    required String desc,
    required String price,
    required bool isGacha,
    required VoidCallback onTap,
  }) {
    final bgColor = isGacha
        ? const Color(0xFFFF9800).withValues(alpha: 0.1)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final borderColor = isGacha ? const Color(0xFFFF9800) : Colors.transparent;
    final titleColor = isGacha
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface;
    final priceColor = isGacha
        ? const Color(0xFFFF9800)
        : theme.colorScheme.onSurface;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      color: bgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: priceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String title;
  final String subtitle;
  const _BenefitRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
