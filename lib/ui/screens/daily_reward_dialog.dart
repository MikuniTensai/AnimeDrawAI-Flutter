import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/daily_reward_model.dart';
import '../../../data/repositories/drawai_repository.dart';

class DailyRewardDialog extends StatefulWidget {
  final DailyStatusResponse status;

  const DailyRewardDialog({super.key, required this.status});

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  bool _isClaiming = false;

  // Reward Cycle Definitions (matching Android)
  static const List<Map<String, dynamic>> _cycleA = [
    {'day': 1, 'label': 'Candy', 'icon': '🍬'},
    {'day': 2, 'label': '100 Gems', 'icon': '💎'},
    {'day': 3, 'label': 'Coffee', 'icon': '☕'},
    {'day': 4, 'label': '200 Gems', 'icon': '💎'},
    {'day': 5, 'label': 'Rose', 'icon': '🌹'},
    {'day': 6, 'label': '500 Gems', 'icon': '💎'},
    {'day': 7, 'label': 'Pro Pass', 'icon': '🎫'},
  ];

  static const List<Map<String, dynamic>> _cycleB = [
    {'day': 1, 'label': 'Coffee', 'icon': '☕'},
    {'day': 2, 'label': '100 Gems', 'icon': '💎'},
    {'day': 3, 'label': 'Chocolate', 'icon': '🍫'},
    {'day': 4, 'label': '200 Gems', 'icon': '💎'},
    {'day': 5, 'label': 'Ice Streak', 'icon': '❄️'},
    {'day': 6, 'label': '500 Gems', 'icon': '💎'},
    {'day': 7, 'label': 'Outfit Tix', 'icon': '🎫'},
  ];

  List<Map<String, dynamic>> get _currentRewards =>
      widget.status.rewardCycle == 'B' ? _cycleB : _cycleA;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E), // Match Android Deep Dark Blue
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Rewards",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Text("🔥", style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            "Streak: ${widget.status.currentStreak} Days",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

            const SizedBox(height: 24),

            // Rewards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return _buildRewardItem(_currentRewards[index]);
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRewardItem(_currentRewards[4]),
                        _buildRewardItem(_currentRewards[5]),
                        _buildRewardItem(_currentRewards[6], wide: true),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Claim Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isClaiming || !widget.status.isClaimable)
                    ? null
                    : _handleClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isClaiming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.status.isClaimable
                            ? "Claim Today's Reward"
                            : "Already Claimed Today",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            if (widget.status.streakSaved) ...[
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("❄️", style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text(
                    "Streak Saved by Freeze!",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(Map<String, dynamic> item, {bool wide = false}) {
    final day = item['day'] as int;
    final targetDay = widget.status.nextDayIndex + 1;
    final isPast = day < targetDay;
    final isToday = day == targetDay;
    final isFuture = day > targetDay;

    return Container(
      width: wide ? null : 64,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Day $day",
                  style: TextStyle(
                    color: isPast ? Colors.grey : Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                if (!isPast && item['icon'] == '💎')
                  Icon(
                    Icons.diamond,
                    color: const Color(0xFFE91E63),
                    size: wide ? 24 : 18,
                  )
                else
                  Text(
                    isPast ? "✅" : item['icon'] as String,
                    style: TextStyle(fontSize: wide ? 24 : 20),
                  ),
                const SizedBox(height: 2),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isPast ? Colors.grey : Colors.white,
                    fontSize: 8,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isFuture)
            Positioned(
              right: 2,
              top: 2,
              child: Icon(
                Icons.lock,
                size: 10,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    ).flexible(flex: wide ? 2 : 1);
  }

  Future<void> _handleClaim() async {
    setState(() => _isClaiming = true);
    final repo = Provider.of<DrawAiRepository>(context, listen: false);

    try {
      final response = await repo.claimDailyReward();
      if (mounted) {
        if (response.success) {
          Navigator.pop(context); // Close the reward list dialog
          _showSuccessDialog(response.reward);
        } else if (response.error?.contains("Already claimed") == true) {
          Navigator.pop(context);
          _showErrorDialog("You have already claimed today's reward.");
        } else {
          _showErrorDialog(response.error ?? "Claim failed");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  void _showSuccessDialog(DailyRewardConfig? reward) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🎉", style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                "Claim Successful!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (reward != null) ...[
                Text(
                  "You received:",
                  style: TextStyle(color: Colors.white.withAlpha(179)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha(51), // 0.2 * 255 ~= 51
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getRewardIcon(reward),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${reward.amount} ${reward.name.replaceAll(RegExp(r'[0-9]'), '').trim()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Awesome!"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRewardIcon(DailyRewardConfig reward) {
    if (reward.id == 'gems') return '💎';
    if (reward.id == 'candy') return '🍬';
    if (reward.id == 'coffee') return '☕';
    if (reward.id == 'rose') return '🌹';
    if (reward.id == 'chocolate') return '🍫';
    if (reward.id == 'ice_streak') return '❄️';
    if (reward.id == 'ticket') return '🎫';
    return '🎁';
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
            Text("Claim Error", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget flexible({int flex = 1}) => Flexible(flex: flex, child: this);
}
