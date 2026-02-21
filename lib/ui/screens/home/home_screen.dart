import 'package:flutter/material.dart';
import 'shop_dialog.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/api_response.dart';
import '../../../data/models/daily_reward_model.dart';
import '../../widgets/workflow_card.dart';
import '../../../data/providers/settings_provider.dart';

import '../daily_reward_dialog.dart';
import '../../components/welcome_dialog.dart';
import '../content/background_remover_screen.dart';
import '../content/background_remover_advanced_screen.dart';
import '../content/face_restore_screen.dart';
import '../content/upscale_screen.dart';
import '../content/make_background_screen.dart';
import '../content/make_background_advanced_screen.dart';
import '../content/sketch_to_image_screen.dart';
import '../content/draw_to_image_screen.dart';
import '../generate/generate_screen.dart';
import '../../components/gem_indicator.dart';
import '../../components/generation_limit_badge.dart';
import '../../components/banner_ad_widget.dart'; // Added BannerAdWidget
import '../../components/native_ad_card.dart'; // Added NativeAdCard
import '../../../data/models/generation_limit_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _welcomeShownThisSession = false;
  final String _tag = "HomeScreen";
  late Future<Map<String, WorkflowInfo>> _workflowsFuture;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String? _selectedSort;
  int _gridColumns = 2;
  bool _showFilterSheet = false;
  bool _isWorkflowsExpanded = false;
  final ScrollController _scrollController = ScrollController();
  bool? _lastRestrictedEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context);

    if (_lastRestrictedEnabled != null &&
        _lastRestrictedEnabled != settings.isRestrictedContentEnabled) {
      _refreshWorkflows();
    }
    _lastRestrictedEnabled = settings.isRestrictedContentEnabled;
  }

  void _refreshWorkflows() {
    setState(() {
      _workflowsFuture = _loadWorkflows(forceRefresh: true);
    });
  }

  @override
  void initState() {
    super.initState();
    _workflowsFuture = _loadWorkflows();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWelcomeMessage();
      _checkDailyStatus();
      Provider.of<DrawAiRepository>(
        context,
        listen: false,
      ).getAllWorkflowStats();
    });
  }

  Future<void> _checkWelcomeMessage() async {
    if (_welcomeShownThisSession) return;

    final appSettingsRepo = context.read<AppSettingsRepository>();
    final welcomeData = await appSettingsRepo.getWelcomeMessage();

    if (welcomeData != null && welcomeData.isActive && mounted) {
      _welcomeShownThisSession = true;
      if (context.mounted) {
        WelcomeDialog.show(context, data: welcomeData);
      }
    }
  }

  Future<Map<String, WorkflowInfo>> _loadWorkflows({
    bool forceRefresh = false,
  }) {
    return Provider.of<DrawAiRepository>(
      context,
      listen: false,
    ).getWorkflows(forceRefresh: forceRefresh);
  }

  Future<void> _checkDailyStatus() async {
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);
    try {
      final status = await drawAiRepo.checkDailyStatus();
      if (status.success && status.isClaimable && mounted) {
        _showDailyRewardDialog(status);
      }
    } catch (e) {
      debugPrint("Error checking daily status: $e");
    }
  }

  void _showDailyRewardDialog(DailyStatusResponse status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyRewardDialog(status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawAiRepo = Provider.of<DrawAiRepository>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final authRepo = Provider.of<AuthRepository>(context, listen: false);

    return StreamBuilder<GenerationLimit>(
      stream: drawAiRepo.getLimitStream(authRepo.currentUser?.uid ?? ""),
      builder: (context, limitSnapshot) {
        final limit = limitSnapshot.data ?? GenerationLimit();
        final isPremium =
            limit.isPremium == true ||
            limit.subscriptionType == 'basic' ||
            limit.subscriptionType == 'pro';

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                title: const Text("Discover"),
                elevation: 0,
                backgroundColor: Colors.transparent,
                actions: [
                  StreamBuilder<int>(
                    stream: drawAiRepo.getGemCountStream(
                      authRepo.currentUser?.uid ?? "",
                    ),
                    builder: (context, snapshot) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GemIndicator(
                          gemCount: snapshot.data ?? 0,
                          onClick: () {
                            showDialog(
                              context: context,
                              builder: (context) => const ShopDialog(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GenerationLimitBadge(
                      limit: limit,
                      onTap: () {
                        // Navigate to subscription or show details
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: () async {
                      try {
                        final drawAiRepo = Provider.of<DrawAiRepository>(
                          context,
                          listen: false,
                        );
                        final authRepo = Provider.of<AuthRepository>(
                          context,
                          listen: false,
                        );

                        // Check if user is premium to allow premium workflows
                        final userId = authRepo.currentUser?.uid ?? "";
                        final limitStream = drawAiRepo.getLimitStream(userId);
                        final limit = await limitStream.first;
                        final isPremium =
                            limit.isPremium == true ||
                            limit.subscriptionType == 'basic' ||
                            limit.subscriptionType == 'pro';

                        final workflowsMap = await drawAiRepo.getWorkflows();
                        if (workflowsMap.isEmpty) return;

                        // Filter available workflows
                        final validWorkflows = workflowsMap.entries.where((
                          entry,
                        ) {
                          if (!isPremium && entry.value.isPremium) {
                            return false;
                          }
                          if (!settings.isRestrictedContentEnabled &&
                              entry.value.restricted) {
                            return false;
                          }
                          return true;
                        }).toList();

                        if (validWorkflows.isEmpty) return;

                        // Pick random
                        validWorkflows.shuffle();
                        final selected = validWorkflows.first;

                        if (!context.mounted) return;

                        drawAiRepo.incrementWorkflowView(selected.key);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateScreen(
                              workflowId: selected.key,
                              workflow: selected.value,
                            ),
                          ),
                        );
                      } catch (e) {
                        debugPrint("Error on random workflow: $e");
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      try {
                        final status = await drawAiRepo.checkDailyStatus();
                        if (status.success && mounted) {
                          _showDailyRewardDialog(status);
                        }
                      } catch (e) {
                        debugPrint("Error checking daily status: $e");
                      }
                    },
                  ),
                ],
              ),
              body: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Search and Filter Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search workflows...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () =>
                                setState(() => _showFilterSheet = true),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildMainBanner(theme),
                    ),
                  ),

                  // Workflows Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<Map<String, WorkflowInfo>>(
                            future: _workflowsFuture,
                            builder: (context, snapshot) {
                              final workflowsMap = snapshot.data ?? {};
                              final workflowsList = workflowsMap.entries
                                  .toList();

                              // Calculate filtered count for the header
                              final filteredCount = workflowsList.where((
                                entry,
                              ) {
                                final workflow = entry.value;
                                final workflowId = entry.key;

                                // 1. Filter by restricted content setting
                                if (!settings.isRestrictedContentEnabled &&
                                    workflow.restricted) {
                                  return false;
                                }

                                // 2. Filter by category
                                if (_selectedFilter != 'All') {
                                  String category = "General";
                                  final idLower = workflowId.toLowerCase();
                                  if (idLower.contains("anime")) {
                                    category = "Anime";
                                  } else if (idLower.contains("animal")) {
                                    category = "Animal";
                                  } else if (idLower.contains("flower")) {
                                    category = "Flower";
                                  } else if (idLower.contains("background")) {
                                    category = "Background";
                                  } else if (idLower.contains("food")) {
                                    category = "Food";
                                  }
                                  if (category != _selectedFilter) return false;
                                }

                                // 3. Filter by search query
                                if (_searchQuery.isNotEmpty) {
                                  final query = _searchQuery.toLowerCase();
                                  return workflow.name.toLowerCase().contains(
                                        query,
                                      ) ||
                                      workflow.description
                                          .toLowerCase()
                                          .contains(query);
                                }

                                return true;
                              }).length;

                              return Text(
                                "Workflows ($filteredCount)",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  _refreshWorkflows();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _gridColumns = _gridColumns == 2
                                        ? 3
                                        : _gridColumns == 3
                                        ? 5
                                        : 2;
                                  });
                                },
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text("See All"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Workflows Grid
                  FutureBuilder<Map<String, WorkflowInfo>>(
                    future: _workflowsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      return StreamBuilder<Map<String, Map<String, int>>>(
                        stream: drawAiRepo.getAllWorkflowStatsStream,
                        initialData: drawAiRepo.currentWorkflowStats,
                        builder: (context, statsSnapshot) {
                          final workflowsMap = snapshot.data ?? {};
                          final statsMap = statsSnapshot.data ?? {};

                          if (workflowsMap.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: Center(child: Text("No workflows found")),
                            );
                          }

                          final workflowsList = workflowsMap.entries.toList();

                          // Debug Log
                          debugPrint(
                            "$_tag: Raw API workflows: ${workflowsMap.length}",
                          );

                          // Filter and Sort
                          final filteredList = workflowsList.where((entry) {
                            final workflow = entry.value;
                            final workflowId = entry.key;

                            // 1. Filter by restricted content setting
                            // Android Parity: Restricted content is ONLY filtered by the toggle
                            if (!settings.isRestrictedContentEnabled &&
                                workflow.restricted) {
                              return false;
                            }

                            // 2. Filter by category
                            if (_selectedFilter != 'All') {
                              String category = "General";
                              final idLower = workflowId.toLowerCase();
                              if (idLower.contains("anime")) {
                                category = "Anime";
                              } else if (idLower.contains("animal")) {
                                category = "Animal";
                              } else if (idLower.contains("flower")) {
                                category = "Flower";
                              } else if (idLower.contains("background")) {
                                category = "Background";
                              } else if (idLower.contains("food")) {
                                category = "Food";
                              }

                              if (category != _selectedFilter) {
                                return false;
                              }
                            }

                            // 3. Filter by search query
                            bool matchesSearch = true;
                            if (_searchQuery.isNotEmpty) {
                              final query = _searchQuery.toLowerCase();
                              matchesSearch =
                                  workflow.name.toLowerCase().contains(query) ||
                                  workflow.description.toLowerCase().contains(
                                    query,
                                  );
                            }

                            return matchesSearch;
                          }).toList();

                          // Apply sorting or shuffle
                          if (_selectedSort != null) {
                            filteredList.sort((a, b) {
                              final statsA = statsMap[a.key] ?? {};
                              final statsB = statsMap[b.key] ?? {};

                              if (_selectedSort == 'Most Viewed') {
                                return (statsB['viewCount'] ?? 0).compareTo(
                                  statsA['viewCount'] ?? 0,
                                );
                              } else if (_selectedSort == 'Newest') {
                                return (statsA['generationCount'] ?? 0)
                                    .compareTo(statsB['generationCount'] ?? 0);
                              } else if (_selectedSort == 'Most Popular') {
                                return (statsB['generationCount'] ?? 0)
                                    .compareTo(statsA['generationCount'] ?? 0);
                              }
                              return 0;
                            });
                          } else {
                            // Shuffle by default if no sort is selected
                            filteredList.shuffle();
                          }

                          final isPremium =
                              limit.isPremium == true ||
                              limit.subscriptionType == 'basic' ||
                              limit.subscriptionType == 'pro';

                          final slivers = <Widget>[];

                          final int displayCount = _isWorkflowsExpanded
                              ? filteredList.length
                              : 6;

                          for (
                            int i = 0;
                            i < filteredList.length && i < displayCount;
                            i += 6
                          ) {
                            final chunk = filteredList.skip(i).take(6).toList();

                            slivers.add(
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _gridColumns,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: _gridColumns == 2
                                            ? 0.73
                                            : _gridColumns == 3
                                            ? 1.0
                                            : 1.0,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final entry = chunk[index];
                                    final workflowId = entry.key;
                                    final baseWorkflow = entry.value;

                                    // Merge stats
                                    if (index == 0) {
                                      debugPrint(
                                        "HomeScreen: statsMap keys count: ${statsMap.length}",
                                      );
                                      if (statsMap.isNotEmpty) {
                                        debugPrint(
                                          "HomeScreen: First 3 statsMap keys: ${statsMap.keys.take(3).toList()}",
                                        );
                                      }
                                    }

                                    final stats = statsMap[workflowId];
                                    if (stats == null) {
                                      // debugPrint("HomeScreen: No stats found for workflow: $workflowId");
                                    } else if (index < 5) {
                                      debugPrint(
                                        "HomeScreen: Stats found for $workflowId: $stats",
                                      );
                                    }

                                    final workflow = WorkflowInfo(
                                      name: baseWorkflow.name,
                                      description: baseWorkflow.description,
                                      estimatedTime: baseWorkflow.estimatedTime,
                                      fileExists: baseWorkflow.fileExists,
                                      isPremium: baseWorkflow.isPremium,
                                      restricted: baseWorkflow.restricted,
                                      useCount:
                                          stats?['generationCount'] ??
                                          baseWorkflow.useCount,
                                      viewCount:
                                          stats?['viewCount'] ??
                                          baseWorkflow.viewCount,
                                    );

                                    // Detect category
                                    String category = "General";
                                    final idLower = workflowId.toLowerCase();
                                    if (idLower.contains("anime") ||
                                        idLower.contains("illustration")) {
                                      category = "Anime";
                                    } else if (idLower.contains("animal") ||
                                        idLower.contains("pet")) {
                                      category = "Animal";
                                    } else if (idLower.contains("flower") ||
                                        idLower.contains("flora")) {
                                      category = "Flower";
                                    } else if (idLower.contains("background") ||
                                        idLower.contains("scenery")) {
                                      category = "Background";
                                    } else if (idLower.contains("food") ||
                                        idLower.contains("cuisine")) {
                                      category = "Food";
                                    }

                                    return WorkflowCard(
                                      workflowId: workflowId,
                                      workflow: workflow,
                                      category: category,
                                      gridColumns: _gridColumns,
                                      userIsPremium: isPremium,
                                      onTap: () {
                                        if (workflow.isPremium && !isPremium) {
                                          Navigator.pushNamed(
                                            context,
                                            '/subscription',
                                          );
                                          return;
                                        }
                                        drawAiRepo.incrementWorkflowView(
                                          workflowId,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GenerateScreen(
                                                  workflowId: workflowId,
                                                  workflow: workflow,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  }, childCount: chunk.length),
                                ),
                              ),
                            );

                            // Insert Native Ad every 6 items (except at the very end of list)
                            if (!isPremium && i + 6 < filteredList.length) {
                              slivers.add(
                                const SliverPadding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: NativeAdCard(),
                                  ),
                                ),
                              );
                            }
                          }

                          if (!_isWorkflowsExpanded &&
                              filteredList.length > 6) {
                            slivers.add(
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isWorkflowsExpanded = true;
                                        });
                                      },
                                      icon: const Icon(Icons.expand_more),
                                      label: const Text(
                                        "See All Workflows",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverMainAxisGroup(slivers: slivers);
                        },
                      );
                    },
                  ),

                  // Bouncing Arrow
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: _BouncingArrow(),
                    ),
                  ),

                  // Content Title Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Content Tools",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Content Tools Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/background_remover_v1',
                          label: 'Remove BG',
                          badge: 'NEW',
                          badgeColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BackgroundRemoverScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/background_remover_v2',
                          label: 'Adv Remove BG',
                          icon: Icons.tune,
                          iconColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BackgroundRemoverAdvancedScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/face_restore_v1',
                          label: 'Face Restore',
                          icon: Icons.face,
                          iconColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FaceRestoreScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/upscale_image_super_resolution',
                          label: 'Super Upscale',
                          icon: Icons.auto_awesome,
                          iconColor: theme.colorScheme.tertiary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpscaleScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/make_background_v1',
                          label: 'Make Background',
                          badge: 'NEW',
                          badgeColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MakeBackgroundScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/make_background_v2',
                          label: 'Adv Make BG',
                          icon: Icons.tune,
                          iconColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MakeBackgroundAdvancedScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/sketch_to_image_drawup',
                          label: 'Sketch to Image',
                          badge: 'NEW',
                          badgeColor: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SketchToImageScreen(),
                              ),
                            );
                          },
                        ),
                        _ContentToolItem(
                          imageUrl:
                              'https://drawai-api.drawai.site/workflow-image/draw_to_image_drawai',
                          label: 'Draw to Image',
                          icon: Icons.brush,
                          iconColor: theme.colorScheme.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DrawToImageScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Banner Ad for free users
                  if (!isPremium)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: BannerAdWidget(),
                      ),
                    ),

                  // Spacer for bottom nav
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            if (_showFilterSheet) _buildFilterBottomSheet(theme),
          ],
        );
      },
    );
  }

  Widget _buildFilterBottomSheet(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _showFilterSheet = false),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _showFilterSheet = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Category', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                              'All',
                              'Anime',
                              'General',
                              'Animal',
                              'Flower',
                              'Food',
                              'Background',
                            ]
                            .map(
                              (filter) => FilterChip(
                                label: Text(filter),
                                selected: _selectedFilter == filter,
                                onSelected: (selected) {
                                  setState(() => _selectedFilter = filter);
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Sort By', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Most Viewed', 'Newest', 'Most Popular']
                        .map(
                          (sort) => FilterChip(
                            label: Text(sort),
                            selected: _selectedSort == sort,
                            onSelected: (selected) {
                              setState(
                                () => _selectedSort = selected ? sort : null,
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => setState(() => _showFilterSheet = false),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBanner(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Navigate to draw/imagine screen
      },
      child: SizedBox(
        width: double.infinity,
        height: 140,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            30,
          ), // Increased radius for rounded/circle look
          child: Image.asset(
            'assets/images/create_imagination_banner.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _BouncingArrow extends StatefulWidget {
  const _BouncingArrow();

  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey,
            size: 32,
          ),
        );
      },
    );
  }
}

class _ContentToolItem extends StatelessWidget {
  final String imageUrl;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ContentToolItem({
    required this.imageUrl,
    required this.label,
    this.badge,
    this.badgeColor,
    this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.error),
              ),
            ),

            // Gradient Overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Badge or Icon at top-right
            if (badge != null || icon != null)
              Positioned(
                top: 4,
                right: 4,
                child: badge != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 16,
                        color: iconColor ?? theme.colorScheme.primary,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
