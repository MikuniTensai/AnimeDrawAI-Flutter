import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/community_model.dart';
import '../../../data/repositories/community_repository.dart';
import 'post_detail_screen.dart';
import '../../components/gem_indicator.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/drawai_repository.dart';
import '../../../data/utils/image_utils.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SortType> _tabs = [
    SortType.popular,
    SortType.recent,
    SortType.trending,
    SortType.myPosts,
  ];

  String _selectedCategory = "All";
  final List<String> _categories = [
    "All",
    "Anime",
    "Realistic",
    "Cyberpunk",
    "Fantasy",
    "Portrait",
    "Landscape",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final drawAiRepo = Provider.of<DrawAiRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text("Community"),
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
                  onClick: () {},
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((type) => Tab(text: _getTabLabel(type))).toList(),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map(
                    (type) => _CommunityFeed(
                      sortType: type,
                      category: _selectedCategory,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Artwork Upload coming soon!")),
          );
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  String _getTabLabel(SortType type) {
    switch (type) {
      case SortType.popular:
        return "Popular";
      case SortType.recent:
        return "Recent";
      case SortType.trending:
        return "Trending";
      case SortType.myPosts:
        return "My Posts";
    }
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(category),
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: Colors.transparent,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CommunityFeed extends StatelessWidget {
  final SortType sortType;
  final String category;
  const _CommunityFeed({required this.sortType, required this.category});

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<CommunityRepository>(context);

    return StreamBuilder<List<CommunityPost>>(
      stream: repository.getPostsStream(sortBy: sortType, category: category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return _buildEmptyState();
        }

        return MasonryGridView.count(
          padding: const EdgeInsets.all(12),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _PostCard(post: posts[index]);
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          height: (index % 2 == 0) ? 200 : 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No posts found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = Provider.of<CommunityRepository>(context, listen: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPostDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final imageUrl = ImageUtils.getFullUrl(post.thumbnailUrl);
                if (imageUrl.isEmpty) {
                  return Container(
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundImage:
                            (post.userPhotoUrl != null &&
                                ImageUtils.getFullUrl(
                                  post.userPhotoUrl,
                                ).isNotEmpty)
                            ? NetworkImage(
                                ImageUtils.getFullUrl(post.userPhotoUrl!),
                              )
                            : null,
                        child: post.userPhotoUrl == null
                            ? const Icon(Icons.person, size: 10)
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.username,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _IconLabel(
                        icon: Icons.favorite_border,
                        label: post.likes.toString(),
                        onTap: () => repository.toggleLike(post.id),
                      ),
                      _IconLabel(
                        icon: Icons.remove_red_eye_outlined,
                        label: post.views.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostDetails(BuildContext context) async {
    final repository = Provider.of<CommunityRepository>(context, listen: false);
    final isLiked = await repository.hasLiked(post.id);

    if (!context.mounted) return;

    // Increment view count
    await repository.incrementView(post.id);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostDetailScreen(post: post, initiallyLiked: isLiked),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _IconLabel({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
