import 'package:flutter/material.dart';
import '../../../../data/models/shop_model.dart';
import '../../../../data/repositories/drawai_repository.dart';
import 'package:provider/provider.dart';

class InventoryDialog extends StatelessWidget {
  final Function(InventoryItemModel) onSelectItem;

  const InventoryDialog({super.key, required this.onSelectItem});

  @override
  Widget build(BuildContext context) {
    final drawAiRepo = Provider.of<DrawAiRepository>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Give a Gift",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          FutureBuilder<List<InventoryItemModel>>(
            future: drawAiRepo.getInventory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Your inventory is empty",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 300,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _getEmoji(item.id),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        "${item.affectionValue} affection points",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      trailing: Text("x${item.amount}"),
                      onTap: item.amount > 0 ? () => onSelectItem(item) : null,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
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
