import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/drawai_repository.dart';
import '../../data/models/shop_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<InventoryItemModel>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = Provider.of<DrawAiRepository>(
      context,
      listen: false,
    ).getInventory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _inventoryFuture = Provider.of<DrawAiRepository>(
                  context,
                  listen: false,
                ).getInventory();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<InventoryItemModel>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _inventoryFuture = Provider.of<DrawAiRepository>(
                          context,
                          listen: false,
                        ).getInventory();
                      });
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(item, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Your items will appear here",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Claim daily rewards or visit the shop to get items!"),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InventoryItemModel item, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleItemClick(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E), // Match Shop item bg
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getEmoji(item.id),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Amount: ${item.amount}",
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "❤️ +${item.affectionValue}",
                style: const TextStyle(color: Colors.pink, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemClick(InventoryItemModel item) {
    switch (item.id) {
      case "pro_pass_3d":
      case "outfit_ticket":
        _showConfirmationDialog(item);
        break;
      case "streak_ice":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This protects your streak automatically if you miss a day.",
            ),
          ),
        );
        break;
      case "candy":
      case "coffee":
      case "rose":
      case "chocolate":
      case "ring":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gift this to your character in Chat!")),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item info: ${item.description}")),
        );
    }
  }

  void _showConfirmationDialog(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Use ${item.name}?"),
        content: const Text(
          "Do you want to activate this item now? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _useItem(item.id);
            },
            child: const Text("Use"),
          ),
        ],
      ),
    );
  }

  Future<void> _useItem(String itemId) async {
    final repo = Provider.of<DrawAiRepository>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await repo.useItem(itemId);
      if (!mounted) return;

      Navigator.pop(context); // Dismiss loading

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? "Item used successfully")),
        );
        // Refresh inventory
        setState(() {
          _inventoryFuture = repo.getInventory(forceRefresh: true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? "Failed to use item"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
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
