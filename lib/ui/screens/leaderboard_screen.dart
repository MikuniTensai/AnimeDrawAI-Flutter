import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/drawai_repository.dart';
import '../../data/models/leaderboard_model.dart';
import '../components/app_drawer.dart';
import '../../data/providers/navigation_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ["Architect", "Romancer", "MVP", "Fame", "Rising"];

  // Filters for Architect
  int _selectedTimeFrame = 0; // 0=All, 1=Weekly, 2=Monthly
  final List<String> _timeFrames = ["All Time", "Weekly", "Monthly"];

  // Filters for Fame
  bool _showDownloads = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        drawer: AppDrawer(
          currentRoute: 'leaderboard',
          onNavigate: (route) {
            Navigator.pop(context); // Close drawer
            if (route == 'leaderboard') return;

            // Handle navigation similar to MainScreen
            final navProvider = Provider.of<NavigationProvider>(
              context,
              listen: false,
            );
            final index = [
              "home",
              "community",
              "gallery",
              "chat",
              "profile",
            ].indexOf(route);

            if (index != -1) {
              navProvider.setIndex(index);
              Navigator.pop(context); // Go back to MainScreen
            } else {
              // For other routes, push them
              Navigator.pushNamed(
                context,
                '/$route',
              ); // Assuming routes are registered
            }
          },
        ),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text("Leaderboard"),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) => setState(() => _selectedTab = index),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return _buildArchitectTab();
      case 1:
        return _buildSimpleTab(
          'romancer',
          'Affection',
          "Master Romancer",
          "Users with highest affection from characters.",
          Icons.favorite,
        );
      case 2:
        return _buildSimpleTab(
          'mvp',
          'Shares',
          "Community MVP",
          "Most active sharers in the community.",
          Icons.share,
        );
      case 3:
        return _buildFameTab();
      case 4:
        return _buildSimpleTab(
          'rising',
          'Recent Likes',
          "Rising Stars",
          "Fast growing creators with recent likes.",
          Icons.trending_up,
        );
      default:
        return const Center(child: Text("Not implemented"));
    }
  }

  Widget _buildArchitectTab() {
    String type = switch (_selectedTimeFrame) {
      1 => 'weekly',
      2 => 'monthly',
      _ => 'all_time',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_timeFrames.length, (index) {
                final isSelected = _selectedTimeFrame == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(_timeFrames[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTimeFrame = index);
                    },
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: LeaderboardList(
            type: type,
            metricLabel: "Generations",
            headerTitle: "Master Architect",
            headerDesc: "Top creators with most generations.",
            headerIcon: Icons.create,
            key: ValueKey('architect_$_selectedTimeFrame'),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTab(
    String type,
    String metric,
    String title,
    String desc,
    IconData icon,
  ) {
    return LeaderboardList(
      type: type,
      metricLabel: metric,
      headerTitle: title,
      headerDesc: desc,
      headerIcon: icon,
      key: ValueKey(type),
    );
  }

  Widget _buildFameTab() {
    String type = _showDownloads ? "downloads_general" : "likes_general";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text("Most Liked"),
                selected: !_showDownloads,
                onSelected: (val) => setState(() => _showDownloads = false),
                avatar: const Icon(Icons.thumb_up, size: 16),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text("Most Downloaded"),
                selected: _showDownloads,
                onSelected: (val) => setState(() => _showDownloads = true),
                avatar: const Icon(Icons.download, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LeaderboardList(
            type: type,
            metricLabel: _showDownloads ? "Downloads" : "Likes",
            headerTitle: "Hall of Fame",
            headerDesc: "Most popular creations in the gallery.",
            headerIcon: Icons.star,
            key: ValueKey('fame_$_showDownloads'),
          ),
        ),
      ],
    );
  }
}

class LeaderboardList extends StatefulWidget {
  final String type;
  final String metricLabel;
  final String headerTitle;
  final String headerDesc;
  final IconData headerIcon;

  const LeaderboardList({
    super.key,
    required this.type,
    required this.metricLabel,
    required this.headerTitle,
    required this.headerDesc,
    required this.headerIcon,
  });

  @override
  State<LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<LeaderboardList> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _loadData()),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        final entries = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadData());
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: entries.isEmpty ? 2 : entries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildInfoCard(theme);
              }

              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "No rankings found. Be the first!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final entry = entries[index - 1];
              return _buildRankItem(entry, index - 1, theme);
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.headerIcon,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.headerTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.headerDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(LeaderboardEntry entry, int index, ThemeData theme) {
    final rank = index + 1;
    final isTop3 = index < 3;
    final rankColor = switch (index) {
      0 => const Color(0xFFFFD700), // Gold
      1 => const Color(0xFFC0C0C0), // Silver
      2 => const Color(0xFFCD7F32), // Bronze
      _ => theme.colorScheme.onSurfaceVariant.withAlpha(100),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "$rank",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              elevation: isTop3 ? 3 : 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage:
                          entry.userPhoto != null && entry.userPhoto!.isNotEmpty
                          ? CachedNetworkImageProvider(entry.userPhoto!)
                          : NetworkImage(
                                  "https://api.dicebear.com/7.x/avataaars/png?seed=${entry.userId}",
                                )
                                as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${entry.score.toInt()} ${widget.metricLabel}",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
