import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/drawai_repository.dart';
import '../../data/models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Leaderboard"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Weekly"),
              Tab(text: "Monthly"),
              Tab(text: "All Time"),
              Tab(text: "Romancers"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LeaderboardTab(type: 'weekly'),
            LeaderboardTab(type: 'monthly'),
            LeaderboardTab(type: 'all_time'),
            LeaderboardTab(type: 'romancer'),
          ],
        ),
      ),
    );
  }
}

class LeaderboardTab extends StatefulWidget {
  final String type;
  const LeaderboardTab({super.key, required this.type});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = Provider.of<DrawAiRepository>(
      context,
      listen: false,
    ).getLeaderboard(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<LeaderboardEntry>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text("No rankings found. Be the first!"));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _leaderboardFuture = Provider.of<DrawAiRepository>(
                context,
                listen: false,
              ).getLeaderboard(widget.type);
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildRankItem(entry, index, theme);
            },
          ),
        );
      },
    );
  }

  Widget _buildRankItem(LeaderboardEntry entry, int index, ThemeData theme) {
    final isTop3 = index < 3;
    final rankColor = switch (index) {
      0 => const Color(0xFFFFD700), // Gold
      1 => const Color(0xFFC0C0C0), // Silver
      2 => const Color(0xFFCD7F32), // Bronze
      _ => Colors.grey[400],
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isTop3 ? 4 : 0,
      color: isTop3
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: SizedBox(
          width: 80,
          child: Row(
            children: [
              Text(
                "${index + 1}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: rankColor,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: entry.userPhoto != null
                    ? CachedNetworkImageProvider(entry.userPhoto!)
                    : null,
                child: entry.userPhoto == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ],
          ),
        ),
        title: Text(
          entry.userName,
          style: TextStyle(
            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
            color: isTop3 ? theme.colorScheme.primary : null,
          ),
        ),
        trailing: Text(
          "${entry.score.toInt()} pts",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
