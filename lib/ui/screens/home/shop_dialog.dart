import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/utils/image_utils.dart';
import '../../../data/repositories/drawai_repository.dart';

class ShopDialog extends StatefulWidget {
  const ShopDialog({super.key});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  bool _isLoading = true;
  String? _error;
  List<ShopItem> _shopItems = [];
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
  }

  Future<void> _loadShopItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = Provider.of<DrawAiRepository>(context, listen: false);
      final apiItems = await repo.getShopItems();

      // Inject Special Booster Item (matching Android)
      final boosterItem = ShopItem(
        id: "daily_booster",
        name: "Daily Limit Booster",
        description: "+5 Daily Generations (Expires at midnight)",
        costGems: 50,
        type: "item",
        amount: 5,
        itemId: "daily_gen_boost",
      );

      setState(() {
        _shopItems = [boosterItem, ...apiItems];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gemColor = Color(0xFFE91E63);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.purpleAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.diamond, color: gemColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Gem Store",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Error loading shop",
                      style: TextStyle(color: Colors.red),
                    ),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: _loadShopItems,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: _shopItems.length,
                  itemBuilder: (context, index) {
                    return _ShopItemCard(
                      item: _shopItems[index],
                      isPurchasing: _isPurchasing,
                      onBuy: () => _handlePurchase(_shopItems[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(ShopItem item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isPurchasing = true);
    final repo = Provider.of<DrawAiRepository>(context, listen: false);

    try {
      if (item.id == "daily_booster") {
        await repo.purchaseDailyBooster(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Booster Activated! +5 Generations"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final result = await repo.purchaseShopItem(item.id);
        if (result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? "Purchase successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception(result.error ?? "Purchase failed");
        }
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.replaceFirst('Exception: ', '');
        }
        _showErrorDialog(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Oops!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.purpleAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool isPurchasing;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.isPurchasing,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Icon Box
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    ImageUtils.getFullUrl(item.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : Text(
                    _getEmoji(item.id),
                    style: const TextStyle(fontSize: 32),
                  ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              item.description,
              style: const TextStyle(color: Colors.grey, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: isPurchasing ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.costGems != null) ...[
                    Text(
                      "${item.costGems}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.diamond, size: 12, color: Colors.white),
                  ] else if (item.costUsd != null)
                    Text(
                      "\$${item.costUsd}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Text(
                      "BUY",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String id) {
    switch (id) {
      case "daily_booster":
        return "🚀";
      case "candy":
        return "🍬";
      case "coffee":
        return "☕";
      case "rose":
        return "🌹";
      case "chocolate":
        return "🍫";
      case "streak_ice":
        return "❄️";
      case "pro_pass_3d":
        return "🎫";
      case "outfit_ticket":
        return "👗";
      default:
        return "🎁";
    }
  }
}
